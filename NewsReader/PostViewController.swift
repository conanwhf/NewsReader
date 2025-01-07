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
import iAd

private var DEFAULT_FONT_SIZE = 16

class PostViewController: UIViewController {
    
    @IBOutlet weak var barNav: UINavigationBar!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var post: UITextView!
    @IBOutlet weak var infoReturn: UILabel!
    
    var postid : Int = 0
    private let queue_getPost = DispatchQueue(label: "PostInfo")
    //private let  queue_getPost = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    private var data : WxcPostItem? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        log("in controller, id =\(postid)",self)
        
        if (self.data == nil) {//first time
            queue_getPost.async {
                manager.updateData(.wenxuecity, mode: .post, id: self.postid)
                self.data = manager.wxcPost
                guard self.data != nil else{
                    log("No post data",self)
                    return
                }
                DispatchQueue.main.async {
                    self.barNav.topItem?.title = self.data!.subid
                    self.post.attributedText = self.creatPostText()
                }
            }
        }

        post.isEditable = false
        post.bounces = true
        btnShare.layer.cornerRadius = 10
        btnBack.layer.cornerRadius = 10
        infoReturn.isHidden = true
        view.bringSubviewToFront(infoReturn)
    }
    
    
    override func viewDidLayoutSubviews(){
        super.viewDidLayoutSubviews()
        //log("----postwidth = \(post.frame.width), UIsize=\(UIScreen.mainScreen().bounds.size), scale=\(UIScreen.mainScreen().scale)",self)
        if (data != nil) {
            self.post.attributedText = self.creatPostText()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func creatPostText() -> NSMutableAttributedString {
        let htmlopt: [NSAttributedString.DocumentReadingOptionKey: Any] = [.documentType: NSAttributedString.DocumentType.html]
        //let img_width = Int(UIScreen.mainScreen().bounds.width-30)
        let img_width = Int(post.frame.width-30)
        var config : String
        var st : String
       
        log("postwidth = \(post.frame.width), UIsize=\(UIScreen.main.bounds.size), scale=\(UIScreen.main.scale)",self)
        config = "img{max-width:\(img_width)px !important;}"   //img style
        config.append("body {font-size:\(DEFAULT_FONT_SIZE)px; background-color:#F9F2FF;}")   //body style
        config.append("h1{font-size: \(DEFAULT_FONT_SIZE+4)px}")      //title style
        config.append("h2{font-size: \(DEFAULT_FONT_SIZE-2)px; color:grey}")      //info style
        config.append("com{font-size: \(DEFAULT_FONT_SIZE-1)px; color:#070F50; font-famliy:Cursive}")      //coment style
        config = "<head><style>" + config + "</style></head>"

        //Title
        st = "<h1>\(data!.title)</h1>"
        //Author & date
        st.append("<h2>发布：\(data!.time)     来源：\(data!.author)<br/></h2>")
        // NOT include : data!.count
        //Content
        st.append(data!.content)
        st.append("<hr/>-------------------------------<br/>")
        //Comment
        st.append("<com>")
        data!.comment.forEach({
            st.append("<b>\($0.usr) 发表于 \($0.time)</b><br/><i>\($0.content)</i><br/><br/>")
        })
        st.append("</com>")
        st = config + st

        do {
            return (try NSMutableAttributedString(data: st.data(using: .unicode)!, options:htmlopt, documentAttributes: nil))
        }catch {
            print(error)
        }
        return NSMutableAttributedString(string: "ERROR")
    }
    
    @IBAction func sharePost(sender: AnyObject) {
        log("share url:\(String(describing: data?.url))")
        
            let shareItems: [AnyObject] = [NSURL(string: data!.url)!]
            let share = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
            //share.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll]
        self.present(share, animated: true, completion: {  })
        }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (scrollView.contentOffset.y > (scrollView.contentSize.height - scrollView.frame.size.height) + (scrollView.frame.size.height / 4) ) && (infoReturn.isHidden) // (scrollView.frame.size.height / 4)是触发操作的阀值
        {
            log("松手返回")//触发返回
            infoReturn.isHidden = false
            log("text=\(String(describing: infoReturn.text)), frame=\(infoReturn.frame)")
            //self.performSegueWithIdentifier("BackToList", sender: self)//跳转到下一个页面，使用转场“BackToList”
        }
        if (scrollView.contentOffset.y < (scrollView.contentSize.height - scrollView.frame.size.height) + (scrollView.frame.size.height / 5) ) && (!infoReturn.isHidden){
            log("取消返回")
            infoReturn.isHidden = true
        }
    }// any offset changes
    
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>){
//        log("scrollView.contentOffset=\(scrollView.contentOffset), scrollView.contentSize.height =\(scrollView.contentSize.height ), scrollView.frame.size.height=\(scrollView.frame.size.height), targetContentOffset=\(targetContentOffset), withVelocity=\(velocity)")
        if (scrollView.contentOffset.y > (scrollView.contentSize.height - scrollView.frame.size.height) + (scrollView.frame.size.height / 5) ) && (!infoReturn.isHidden)
        {
            log(scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height), "Post返回" as NSString)
            self.performSegue(withIdentifier: "BackToList", sender: self)//跳转到下一个页面，使用转场“BackToList”
        }
    }

     /*callbacks for ScrollView
    //func scrollViewDidScroll(scrollView: UIScrollView) {logn(1)}// any offset changes
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {logn(3)}
    //func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {logn(4)}
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {logn(5)}
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView)  {logn(6)}// called on finger up as we are moving
    func scrollViewDidEndDecelerating(scrollView: UIScrollView)  {logn(7)}// called when scroll view grinds to a halt
    func scrollViewDidScrollToTop(scrollView: UIScrollView)  {logn(13)}// called when scrolling animation finished. may be called immediately if already at top
    */
}
