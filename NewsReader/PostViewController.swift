//
//  PostViewController.swift
//  NewsReader
//
//  Created by Conan on 18/12/15.
//  Copyright © 2015年 Conan. All rights reserved.
//

//
//  ListViewController.swift
//  NewsReader
//
//  Created by Conan on 18/12/15.
//  Copyright © 2015年 Conan. All rights reserved.
//

import UIKit

class PostViewController: UIViewController {
    
    @IBOutlet weak var barNav: UINavigationBar!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var post: UITextView!
    
    private var data : WxcPostItem? = nil
    var postid : Int = 0
    var fontsize = 16
    private let  queue_getPost = dispatch_queue_create("PostInfo",DISPATCH_QUEUE_SERIAL)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnShare.layer.cornerRadius = 10.0
        //btnBack.buttonType = .DetailDisclosure
        // Do any additional setup after loading the view, typically from a nib.
        log("in controller, id =\(postid)",self)
        
        if (self.data == nil) {//first time
            dispatch_async(queue_getPost){
                manager.updateData(.wenxuecity, mode: .post, id: self.postid)
                self.data = manager.wxcPost
                guard self.data != nil else{
                    log("No post data",self)
                    return
                }
                let temp = self.creatPostText()
                dispatch_async(dispatch_get_main_queue()){
                    self.barNav.topItem?.title = self.data!.subid
                    self.post.attributedText = temp
                }
            }
        }
        self.post.editable = false
        
        //btnShare.addTarget(self, action: "sharePost", forControlEvents: .TouchUpInside)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func creatPostText() -> NSMutableAttributedString {
        let htmlopt = [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType]
        let img_width = Int(UIScreen.mainScreen().bounds.width-30)
        var config : String
        var st : String
        
        log("postwidth = \(post.frame.width), UIsize=\(UIScreen.mainScreen().bounds.size), scale=\(UIScreen.mainScreen().scale)",self)
        config = "img{max-width:\(img_width)px !important;}"   //img style
        config.appendContentsOf("body {font-size:\(fontsize)px;}")   //body style
        config.appendContentsOf("h1{font-size: \(fontsize+4)px}")      //title style
        config.appendContentsOf("h2{font-size: \(fontsize-2)px; color:grey}")      //info style
        config.appendContentsOf("com{font-size: \(fontsize-1)px; color:#070F50; font-famliy:Cursive}")      //coment style
        config = "<head><style>" + config + "</style></head>"
        
        //Title
        st = "<h1>\(data!.title)</h1>"
        //Author & date
        st.appendContentsOf("<h2>发布：\(data!.time)     来源：\(data!.author)<br/></h2>")
        // NOT include : data!.count
        //Content
        st.appendContentsOf(data!.content)
        st.appendContentsOf("<hr/>-------------------------------<br/>")
        //Comment
        st.appendContentsOf("<com>")
        data!.comment.forEach({
            st.appendContentsOf("\($0.usr) 发表于 \($0.time)<br/>\($0.content)<br/><br/>")
        })
        st.appendContentsOf("</com>")
        st = config + st
        do {
            return (try NSMutableAttributedString(data: st.dataUsingEncoding(NSUnicodeStringEncoding)!, options:htmlopt, documentAttributes: nil))
        }catch {
            print(error)
        }
        return NSMutableAttributedString(string: "ERROR")
    }
    
    @IBAction func sharePost(sender: AnyObject) {
            log("share url:\(data?.url)")
        
            let shareItems: [AnyObject] = [NSURL(string: data!.url)!]
            let share = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
            //share.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll]
            self.presentViewController(share, animated: true, completion: { _ in })
        }
    
}

