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
    private var willReturn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        post.editable = false
        btnShare.layer.cornerRadius = 10
        btnBack.layer.cornerRadius = 10
        post.bounces = true

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

    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>){
//        log("scrollView.contentOffset=\(scrollView.contentOffset), scrollView.contentSize.height =\(scrollView.contentSize.height ), scrollView.frame.size.height=\(scrollView.frame.size.height), targetContentOffset=\(targetContentOffset), withVelocity=\(velocity)")
        if (scrollView.contentOffset.y > (scrollView.contentSize.height - scrollView.frame.size.height) + (scrollView.frame.size.height / 4) ) && (manager.wxcList.count > 0) // (scrollView.frame.size.height / 4)是触发操作的阀值
        {
            log(scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height), "5555555555555")//触发上拉刷新
            willReturn = true
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView)  {
        //logn(7)
        //log("scrollView.contentOffset=\(scrollView.contentOffset), scrollView.contentSize.height =\(scrollView.contentSize.height ), scrollView.frame.size.height=\(scrollView.frame.size.height)")
        if willReturn && (scrollView.contentOffset.y == scrollView.contentSize.height - scrollView.frame.size.height) {
            logn(0)
            self.performSegueWithIdentifier("BackToList", sender: self)//跳转到下一个页面，使用转场“BackToList”
        }
    }// called when scroll view grinds to a halt

    /* callbacks for ScrollView
    func scrollViewDidScroll(scrollView: UIScrollView) {logn(1)}// any offset changes
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {logn(3)}
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {logn(4)}
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {logn(5)}
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView)  {logn(6)}// called on finger up as we are moving
    func scrollViewDidScrollToTop(scrollView: UIScrollView)  {logn(13)}// called when scrolling animation finished. may be called immediately if already at top
    */
}

