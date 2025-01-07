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
private let  queue_getListInfo = DispatchQueue.global(qos: .userInitiated)
private let  queue_getListImg = DispatchQueue.global(qos: .utility)
private var read : Set<Int> = []

class ListViewController: UIViewController {
    @IBOutlet weak var channel: UISegmentedControl!
    @IBOutlet var ListTableView: UITableView!
    @IBOutlet weak var loading: UIActivityIndicatorView!

    fileprivate var selectPost = 0
    fileprivate let sliding = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
      
        //初始化频道
        channel.removeAllSegments()
        for (i, j) in wxcChannelArr.enumerated() {
            channel.insertSegment(withTitle: j, at: i, animated: false)
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
        sliding.addTarget(self, action: #selector(ListViewController.updateLatesList), for: UIControl.Event.valueChanged)
        sliding.attributedTitle = NSAttributedString(string: "下拉刷新...")
        self.ListTableView.addSubview(sliding)
        //添加上拉更多
        loading.hidesWhenStopped = true
        loading.startAnimating()
        ListTableView.register(ListTableViewCell.self, forCellReuseIdentifier: CELL_ID)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        ListTableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   
    //Number of Cell & Section
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manager.wxcList.count
    }
    
    //Show Cells
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> ListTableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath) as? ListTableViewCell
        //log("cellForRowAtIndexPath, index=\(indexPath.row), post=\(manager.wxcList[indexPath.row].postId), title=\(manager.wxcList[indexPath.row].title)", cell)
        if cell==nil {
            cell = ListTableViewCell(style: .default, reuseIdentifier: CELL_ID)
        }

        cell!.showListItemInfo((indexPath as NSIndexPath).row)
        if read.contains( manager.wxcList[(indexPath as NSIndexPath).row].postId ) {
            log("read!@    post=\(manager.wxcList[(indexPath as NSIndexPath).row]), set=\(read)")
            cell!.title.textColor = UIColor.gray
        }
        else {
            cell!.title.textColor = UIColor.black
        }
        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) -> IndexPath?    {
        log("will selet, get title =\(manager.wxcList[(indexPath as NSIndexPath).row].title)", self)
        selectPost = (indexPath as NSIndexPath).row
        self.performSegue(withIdentifier: "ShowPost", sender: self)
        return indexPath
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        log("id = \(segue.identifier ?? "nil"), \(String(describing: sender))",self)
        // Get the new view controller using segue.destinationViewController, and pass the selected object to the new view controller.
        let next = segue.destination as! PostViewController
        next.postid = manager.wxcList[selectPost].postId
        last.offset = self.ListTableView.contentOffset
        last.ch = self.channel.selectedSegmentIndex
        read = read.union([next.postid])
    }
    
    fileprivate func reload(){
        DispatchQueue.main.async{
            self.ListTableView.reloadData()
            self.loading.stopAnimating()
        }
    }
    
    fileprivate func updateImg(_ index: Int){
        if index == -1 {
            queue_getListImg.async{
                log("add a new job to update images",self)
                manager.wxcList.forEach({
                    $0.updateLogo()
                    self.reload()
                })
            }
        }
        else {
            queue_getListInfo.async{
                log("update img for index \(index)",self)
                manager.wxcList[index].updateLogo()
                self.reload()
            }
        }
    }
    
    
    @objc func updateLatesList(){
        queue_getListInfo.async{
            log("add a new job to update list info",self)
            manager.updateData(last.news, mode: DataRequestMode.latestItems)
            self.reload()
            self.sliding.endRefreshing()
            self.updateImg(-1)
        }//async end
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //log(scrollView.contentOffset, decelerate)
        if (scrollView.contentOffset.y > (scrollView.contentSize.height - scrollView.frame.size.height) + 70) && (manager.wxcList.count > 0) //70是触发操作的阀值
        {
            log(scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height), "44444444444" as AnyObject?)//触发上拉刷新
            loading.startAnimating()
            queue_getListInfo.async{
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
    
    
    @IBAction func channelChanged(_ sender: AnyObject)  {
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
