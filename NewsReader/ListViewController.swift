//
//  ListViewController.swift
//  NewsReader
//
//  Created by Conan on 18/12/15.
//  Copyright © 2015年 Conan. All rights reserved.
//

import UIKit

private var last = (offset: CGPoint(x: 0,y: 0), ch: 0, news: NewsType.wenxuecity )
private let  queue_getListInfo = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);//dispatch_queue_create("GetListInfo",DISPATCH_QUEUE_SERIAL)
private let  queue_getListImg = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
private var read : Set<Int> = []

class ListViewController: UIViewController {
    @IBOutlet weak var channel: UISegmentedControl!
    @IBOutlet var ListTableView: UITableView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    private var selectPost = 0
    private let sliding = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        channel.removeAllSegments()
        for (i, j) in wxcChannelArr.enumerate() {
            channel.insertSegmentWithTitle(j, atIndex: i, animated: false)
        }
        if manager.wxcList.isEmpty {
            self.updateLatesList()
        }
        else {
            //显示之前位置
            log("channel=\(last.1), offset=\(last.0) ")
            ListTableView.setContentOffset(last.0, animated: false)
            channel.selectedSegmentIndex = last.1
            self.updateImg(-1)
        }
        //添加下拉刷新
        sliding.addTarget(self, action: "updateLatesList", forControlEvents: UIControlEvents.ValueChanged)
        sliding.attributedTitle = NSAttributedString(string: "下拉刷新...")
        self.ListTableView.addSubview(sliding)
        //添加上拉更多
        loading.hidesWhenStopped = true
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
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //log("cellForRowAtIndexPath, index=\(indexPath.row), post=\(manager.wxcList[indexPath.row].postId), title=\(manager.wxcList[indexPath.row].title)", self)
        let cell = tableView.dequeueReusableCellWithIdentifier("WxcList", forIndexPath: indexPath) as UITableViewCell
        // Configure the cell...
        cell.textLabel!.text = manager.wxcList[indexPath.row].title
        if read.contains( manager.wxcList[indexPath.row].postId ) {
            log("read!@    post=\(manager.wxcList[indexPath.row]), set=\(read)")
            cell.textLabel!.textColor = UIColor.grayColor()
        }
        else {
            cell.textLabel!.textColor = UIColor.blackColor()
        }
        cell.imageView!.image = UIImage(data: manager.wxcList[indexPath.row].logodata!)
        cell.detailTextLabel!.text = manager.wxcList[indexPath.row].time + "     \(manager.wxcList[indexPath.row].count)"
        cell.detailTextLabel!.textColor = UIColor.grayColor()
        return cell
    }
    
    //Selete and deselect
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        log("seleted, get title =\(manager.wxcList[indexPath.row].title)", self)
        //self.performSegueWithIdentifier("ShowPost", sender: self)//跳转到下一个页面，识别“ShowPost”
    }

    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath?    {
        log("will selet, get title =\(manager.wxcList[indexPath.row].title)", self)
        selectPost = indexPath.row
        return indexPath
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        log("id = \(segue.identifier), \(sender.debugDescription)",self)
        // Get the new view controller using segue.destinationViewController, and pass the selected object to the new view controller.
        let next = segue.destinationViewController as! PostViewController
        next.postid = manager.wxcList[selectPost].postId
        last.0 = self.ListTableView.contentOffset
        last.1 = self.channel.selectedSegmentIndex
        read = read.union([next.postid])
    }
    
    private func reload(){
        dispatch_async(dispatch_get_main_queue()){
            self.ListTableView.reloadData()}
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
                self.loading.stopAnimating()
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
    
  }// End All for ListViewController
