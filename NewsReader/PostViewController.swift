//
//  PostViewController.swift
//  NewsReader
//
//  Created by Conan on 18/12/15.
//  Copyright © 2015年 Conan. All rights reserved.
//

import UIKit
// import iAd // iAd is deprecated, remove if not used

private var DEFAULT_FONT_SIZE = 16

class PostViewController: UIViewController {
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var postTextView: UITextView!
    @IBOutlet weak var returnLabel: UILabel!
    
    var postid: Int = 0
    private let queue_getPost = DispatchQueue.global(qos: .userInitiated)
    //private let queue_getPost = DispatchQueue.global(qos: .background) // Alternative approach
    private var data: WxcPostItem? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        log("in controller, id =\(postid)", self)
        
        if self.data == nil { // first time
            queue_getPost.async {
                manager.updateData(.wenxuecity, mode: .post, id: self.postid)
                self.data = manager.wxcPost
                guard let postData = self.data else {
                    log("No post data", self)
                    return
                }
                DispatchQueue.main.async {
                    self.navigationBar.topItem?.title = postData.subid
                    self.postTextView.attributedText = self.createPostText()
                }
            }
        }

        postTextView.isEditable = false
        postTextView.bounces = true
        shareButton.layer.cornerRadius = 10
        backButton.layer.cornerRadius = 10
        returnLabel.isHidden = true
        view.bringSubviewToFront(returnLabel)
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //log("----postwidth = \(postTextView.frame.width), UIsize=\(UIScreen.main.bounds.size), scale=\(UIScreen.main.scale)", self)
        if data != nil {
            self.postTextView.attributedText = self.createPostText()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func createPostText() -> NSAttributedString {
        let htmlopt = [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.html]
        //let img_width = Int(UIScreen.main.bounds.width-30)
        let img_width = Int(postTextView.frame.width - 30)
        var config: String
        var st: String
        
        //log("postwidth = \(postTextView.frame.width), UIsize=\(UIScreen.main.bounds.size), scale=\(UIScreen.main.scale)", self)
        config = "img{max-width:\(img_width)px !important;}"   // img style
        config += "body {font-size:\(DEFAULT_FONT_SIZE)px; background-color:#F9F2FF;}"   // body style
        config += "h1{font-size: \(DEFAULT_FONT_SIZE+4)px}"      // title style
        config += "h2{font-size: \(DEFAULT_FONT_SIZE-2)px; color:grey}"      // info style
        config += "com{font-size: \(DEFAULT_FONT_SIZE-1)px; color:#070F50; font-family:Cursive}"      // comment style
        config = "<head><style>" + config + "</style></head>"

        // Title
        st = "<h1>\(data!.title)</h1>"
        // Author & date
        st += "<h2>发布：\(data!.time)     来源：\(data!.author)<br/></h2>"
        // NOT include : data!.count
        // Content
        st += data!.content
        st += "<hr/>-------------------------------<br/>"
        // Comment
        st += "<com>"
        data!.comment.forEach {
            st += "<b>\($0.usr) 发表于 \($0.time)</b><br/><i>\($0.content)</i><br/><br/>"
        }
        st += "</com>"
        st = config + st

        do {
            return try NSAttributedString(data: st.data(using: .utf8)!, options: htmlopt, documentAttributes: nil)
        } catch {
            print(error)
            return NSAttributedString(string: "ERROR")
        }
    }
    
    @IBAction func sharePost(_ sender: UIButton) {
        log("share url:\(data?.url ?? "nil")")
              
        guard let url = URL(string: data!.url) else {
            return
        }
        
        let shareItems: [Any] = [url]
        let share = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        //share.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll]
        self.present(share, animated: true, completion: nil)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y > (scrollView.contentSize.height - scrollView.frame.size.height) + (scrollView.frame.size.height / 4)) && returnLabel.isHidden { // (scrollView.frame.size.height / 4) is the trigger threshold
            log("松手返回") // trigger return
            returnLabel.isHidden = false
            log("text=\(returnLabel.text ?? "nil"), frame=\(returnLabel.frame)")
            //self.performSegue(withIdentifier: "BackToList", sender: self) // jump to next page, using transition "BackToList"
        }
        if (scrollView.contentOffset.y < (scrollView.contentSize.height - scrollView.frame.size.height) + (scrollView.frame.size.height / 5)) && !returnLabel.isHidden {
            log("取消返回")
            returnLabel.isHidden = true
        }
    } // any offset changes
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        //        log("scrollView.contentOffset=\(scrollView.contentOffset), scrollView.contentSize.height =\(scrollView.contentSize.height ), scrollView.frame.size.height=\(scrollView.frame.size.height), targetContentOffset=\(targetContentOffset), withVelocity=\(velocity)")
        if (scrollView.contentOffset.y > (scrollView.contentSize.height - scrollView.frame.size.height) + (scrollView.frame.size.height / 5)) && !returnLabel.isHidden {
            log(scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height), "Post返回")
            self.performSegue(withIdentifier: "BackToList", sender: self) // jump to next page, using transition "BackToList"
        }
    }

     /* callbacks for ScrollView
    //func scrollViewDidScroll(scrollView: UIScrollView) {logn(1)}// any offset changes
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {logn(3)}
    //func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {logn(4)}
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {logn(5)}
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView)  {logn(6)}// called on finger up as we are moving
    func scrollViewDidEndDecelerating(scrollView: UIScrollView)  {logn(7)}// called when scroll view grinds to a halt
    func scrollViewDidScrollToTop(scrollView: UIScrollView)  {logn(13)}// called when scrolling animation finished. may be called immediately if already at top
    */
}
