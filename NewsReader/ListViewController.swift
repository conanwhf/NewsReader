//
//  ListViewController.swift
//  NewsReader
//
//  Created by Conan on 18/12/15.
//  Copyright © 2015年 Conan. All rights reserved.
//

import UIKit
import iAd

private var last = (offset: CGPoint(x: 0,y: 0), ch: 0, news: NewsType.wenxuecity )
private let  queue_getListInfo = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);//dispatch_queue_create("GetListInfo",DISPATCH_QUEUE_SERIAL)
private let  queue_getListImg = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
private var read : Set<Int> = []

class ListViewController: UIViewController {
    @IBOutlet weak var channel: UISegmentedControl!
    @IBOutlet var ListTableView: UITableView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var listAd: ADBannerView!

    private var selectPost = 0
    private let sliding = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //添加广告
        self.canDisplayBannerAds = true
        //初始化频道
        channel.removeAllSegments()
        for (i, j) in wxcChannelArr.enumerate() {
            channel.insertSegmentWithTitle(j, atIndex: i, animated: false)
        }
        channel.selectedSegmentIndex = last.ch
        if manager.wxcList.isEmpty {
            self.updateLatesList()
        }
        else {
            //显示之前位置
            log("channel=\(last.ch), offset=\(last.offset) ")
            ListTableView.setContentOffset(last.offset, animated: false)
            self.updateImg(-1)
        }
        //添加下拉刷新
        sliding.addTarget(self, action: "updateLatesList", forControlEvents: UIControlEvents.ValueChanged)
        sliding.attributedTitle = NSAttributedString(string: "下拉刷新...")
        self.ListTableView.addSubview(sliding)
        //添加上拉更多
        loading.hidesWhenStopped = true
        loading.startAnimating()
        ListTableView.registerClass(ListTableViewCell.self, forCellReuseIdentifier: CELL_ID)
        //注册横竖屏变化
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "statusBarOrientationChange:", name: UIApplicationDidChangeStatusBarOrientationNotification, object: nil)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   
    //Number of Cell & Section
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manager.wxcList.count
    }
    
    //Show Cells
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> ListTableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(CELL_ID, forIndexPath: indexPath) as? ListTableViewCell
        //log("cellForRowAtIndexPath, index=\(indexPath.row), post=\(manager.wxcList[indexPath.row].postId), title=\(manager.wxcList[indexPath.row].title)", cell)
        if cell==nil {
            cell = ListTableViewCell(style: .Default, reuseIdentifier: CELL_ID)
        }

        cell!.showListItemInfo(indexPath.row)
        if read.contains( manager.wxcList[indexPath.row].postId ) {
            log("read!@    post=\(manager.wxcList[indexPath.row]), set=\(read)")
            cell!.title.textColor = UIColor.grayColor()
        }
        else {
            cell!.title.textColor = UIColor.blackColor()
        }
        return cell!
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath?    {
        log("will selet, get title =\(manager.wxcList[indexPath.row].title)", self)
        selectPost = indexPath.row
        self.performSegueWithIdentifier("ShowPost", sender: self)
        return indexPath
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        log("id = \(segue.identifier), \(sender.debugDescription)",self)
        // Get the new view controller using segue.destinationViewController, and pass the selected object to the new view controller.
        let next = segue.destinationViewController as! PostViewController
        next.postid = manager.wxcList[selectPost].postId
        last.offset = self.ListTableView.contentOffset
        last.ch = self.channel.selectedSegmentIndex
        read = read.union([next.postid])
    }
    
    private func reload(){
        dispatch_async(dispatch_get_main_queue()){
            self.ListTableView.reloadData()
            self.loading.stopAnimating()
        }
    }
    
    private func updateImg(index: Int){
        if index == -1 {
            dispatch_async(queue_getListImg){
                log("add a new job to update images",self)
                manager.wxcList.forEach({
                    $0.updateLogo()
                    self.reload()
                })
            }
        }
        else {
            dispatch_async(queue_getListInfo){
                log("update img for index \(index)",self)
                manager.wxcList[index].updateLogo()
                self.reload()
            }
        }
    }
    
    
    func updateLatesList(){
        dispatch_async(queue_getListInfo){
            log("add a new job to update list info",self)
            manager.updateData(last.news, mode: DataRequestMode.latestItems)
            self.reload()
            self.sliding.endRefreshing()
            self.updateImg(-1)
        }//async end
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //log(scrollView.contentOffset, decelerate)
        if (scrollView.contentOffset.y > (scrollView.contentSize.height - scrollView.frame.size.height) + 70) && (manager.wxcList.count > 0) //70是触发操作的阀值
        {
            log(scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height), "44444444444")//触发上拉刷新
            loading.startAnimating()
            dispatch_async(queue_getListInfo){
                log("add a new job to get more",self)
                manager.updateData(last.news, mode: DataRequestMode.moreItems)
                self.reload()
                self.updateImg(-1)
            }
        }
        /*
        log("scrollView.contentOffset.y =\(scrollView.contentOffset.y), scrollView.contentSize.height=\(scrollView.contentSize.height),  scrollView.frame.size.height=\(scrollView.frame.size.height)")
        if (scrollView.contentOffset.y < -70  && manager.wxcList.count > 0) //触发下拉刷新
        {
            loading.startAnimating()
            dispatch_async(queue_getListInfo){
                log("add a new job to update list info",self)
                manager.updateData(last.news, mode: DataRequestMode.latestItems)
                self.reload()
                self.loading.stopAnimating()
                dispatch_async(self.queue_getListImg){
                    log("add a new job to update images",self)
                    manager.wxcList.forEach({
                        $0.updateLogo()
                        self.reload()
                    })
                }
            }//async end
        }
*/
    }//End scrollViewDidEndDragging
    
    
    @IBAction func channelChanged(sender: AnyObject)  {
        let segment = sender as! UISegmentedControl

        switch (segment.selectedSegmentIndex){
            case 0: manager.wxcCh = WxcChannels.news
            case 1: manager.wxcCh = WxcChannels.ent
            case 2: manager.wxcCh = WxcChannels.social
            case 3: manager.wxcCh = WxcChannels.blog
            default: break
        }
        self.ListTableView.reloadData()
        log("segment.selectedSegmentIndex=\(segment.selectedSegmentIndex)")
        self.updateLatesList()
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView) {
        //print("!!!!!!!!!!!!!!!!!!!!!!!!")
    }
    
    func bannerView(banner: ADBannerView, didFailToReceiveAdWithError error: NSError) {
        //print("3232112213123213213213213123312123")
    }
    
    func statusBarOrientationChange(notification: NSNotification) {
        let orientation: UIInterfaceOrientation = UIApplication.sharedApplication().statusBarOrientation
        //print("isPortrait:\(orientation.isPortrait)")
        ListTableView.reloadData()
        if orientation == .LandscapeRight {
            //
        }
        if orientation == .LandscapeLeft {
            //
        }
        if orientation == .Portrait {
            //
        }
        if orientation == .PortraitUpsideDown {
            //
        }
    }
  }// End All for ListViewController
