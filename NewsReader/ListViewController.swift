//
//  ListViewController.swift
//  NewsReader
//
//  Created by Conan on 18/12/15.
//  Copyright © 2015年 Conan. All rights reserved.
//

import UIKit

class ListViewController: UIViewController {
    @IBOutlet var ListTableView: UITableView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    private var seletedId = 0
    private let  queue_getListInfo = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);//dispatch_queue_create("GetListInfo",DISPATCH_QUEUE_SERIAL)
    private let  queue_getListImg = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    private let sliding = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //TODO:
        //manager.wxcCh = WxcChannels.ent
        //manager.wxcGetItemNum = 10
        if manager.wxcList.isEmpty {
            self.updateLatesList()
        }
        //添加下拉刷新
        sliding.addTarget(self, action: "updateLatesList", forControlEvents: UIControlEvents.ValueChanged)
        sliding.attributedTitle = NSAttributedString(string: "松手刷新...")
        self.ListTableView.addSubview(sliding)
        //添加上拉更多
        //self.ListTableView.addSubview(loading)
        //self.view.addSubview(loading)
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
        //log("cellForRowAtIndexPath, index=\(indexPath.row)", self)
        
        let cell = tableView.dequeueReusableCellWithIdentifier("WxcList", forIndexPath: indexPath) as UITableViewCell
        // Configure the cell...
        cell.textLabel!.text = manager.wxcList[indexPath.row].title
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
        seletedId = manager.wxcList[indexPath.row].postId
        return indexPath
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        log("id = \(segue.identifier), \(sender.debugDescription)",self)
        // Get the new view controller using segue.destinationViewController, and pass the selected object to the new view controller.
        let next = segue.destinationViewController as! PostViewController
        next.postid = seletedId
    }
    
    private func reload(){
        dispatch_async(dispatch_get_main_queue()){
            self.ListTableView.reloadData()}
    }
    
    func updateLatesList(){
        dispatch_async(queue_getListInfo){
            log("add a new job to update list info",self)
            manager.updateData(NewsType.wenxuecity, mode: DataRequestMode.latestItems)
            self.reload()
            self.sliding.endRefreshing()
            dispatch_async(self.queue_getListImg){
                log("add a new job to update images",self)
                manager.wxcList.forEach({
                    $0.updateLogo()
                    self.reload()
                })
            }
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
                manager.updateData(NewsType.wenxuecity, mode: DataRequestMode.moreItems)
                self.reload()
                self.loading.stopAnimating()
                dispatch_async(self.queue_getListImg){
                    log("add a new job to update images, count=\(manager.wxcList.count)",self)
                    manager.wxcList.forEach({
                        $0.updateLogo()
                        self.reload()
                    })
                } //aysnc  img end
            }
        }
        /*
        log("scrollView.contentOffset.y =\(scrollView.contentOffset.y), scrollView.contentSize.height=\(scrollView.contentSize.height),  scrollView.frame.size.height=\(scrollView.frame.size.height)")
        if (scrollView.contentOffset.y < -70  && manager.wxcList.count > 0) //触发下拉刷新
        {
            loading.startAnimating()
            dispatch_async(queue_getListInfo){
                log("add a new job to update list info",self)
                manager.updateData(NewsType.wenxuecity, mode: DataRequestMode.latestItems)
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
    
  }// End All for ListViewController