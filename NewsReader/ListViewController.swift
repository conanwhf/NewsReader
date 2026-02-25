//
//  ListViewController.swift
//  NewsReader
//
//  Created by Conan on 18/12/15.
//  Copyright © 2015年 Conan. All rights reserved.
//

import UIKit
// import iAd // iAd is deprecated, remove if not used

@MainActor private var last = (offset: CGPoint(x: 0, y: 0), ch: 0, news: NewsType.wenxuecity)
private let queue_getListInfo = DispatchQueue.global(qos: .userInitiated)
private let queue_getListImg = DispatchQueue.global(qos: .background)
@MainActor private var read: Set<Int> = []

class ListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var channelSegmentedControl: UISegmentedControl!
    @IBOutlet weak var listTableView: UITableView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    private var selectedPost = 0
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
      
        // 初始化频道
        channelSegmentedControl.removeAllSegments()
        for (index, title) in wxcChannelArr.enumerated() {
            channelSegmentedControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        channelSegmentedControl.selectedSegmentIndex = last.ch
        if manager.wxcList.isEmpty {
            self.updateLatestList()
        } else {
            // 显示之前位置
            log("channel=\(last.ch), offset=\(last.offset)")
            listTableView.setContentOffset(last.offset, animated: false)
            self.updateImg(index: -1)
        }
        // 添加下拉刷新
        refreshControl.addTarget(self, action: #selector(updateLatestList), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "下拉刷新...")
        self.listTableView.addSubview(refreshControl)
        // 添加上拉更多
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
        listTableView.register(ListTableViewCell.self, forCellReuseIdentifier: CELL_ID)
        // 注册横竖屏变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(statusBarOrientationChange),
            name: UIApplication.didChangeStatusBarOrientationNotification,
            object: nil
        )

    }
    
    @objc func statusBarOrientationChange() {
        self.reload()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   
    // Number of Cell & Section
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manager.wxcList.count
    }
    
    // Show Cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_ID, for: indexPath) as? ListTableViewCell
        //log("cellForRowAtIndexPath, index=\(indexPath.row), post=\(manager.wxcList[indexPath.row].postId), title=\(manager.wxcList[indexPath.row].title)", cell)
        guard let listCell = cell else {
            return UITableViewCell()
        }

        listCell.showListItemInfo(indexPath.row)
        if read.contains(manager.wxcList[indexPath.row].postId) {
            log("read!@    post=\(manager.wxcList[indexPath.row]), set=\(read)")
            listCell.title.textColor = .gray
        } else {
            listCell.title.textColor = .black
        }
        return listCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        log("will select, get title =\(manager.wxcList[indexPath.row].title)", self)
        selectedPost = indexPath.row
        self.performSegue(withIdentifier: "ShowPost", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        log("id = \(segue.identifier ?? "nil"), \(sender.debugDescription)", self)
        // Get the new view controller using segue.destinationViewController, and pass the selected object to the new view controller.
        guard let next = segue.destination as? PostViewController else {
            return
        }
        next.postid = manager.wxcList[selectedPost].postId
        last.offset = self.listTableView.contentOffset
        last.ch = self.channelSegmentedControl.selectedSegmentIndex
        read.insert(next.postid)
    }
    
    nonisolated private func reload() {
        DispatchQueue.main.async {
            self.listTableView.reloadData()
            self.loadingIndicator.stopAnimating()
        }
    }
    
    private func updateImg(index: Int) {
        if index == -1 {
            queue_getListImg.async {
                log("add a new job to update images", self)
                manager.wxcList.forEach {
                    $0.updateLogo()
                    self.reload()
                }
            }
        } else {
            queue_getListInfo.async {
                log("update img for index \(index)", self)
                manager.wxcList[index].updateLogo()
                self.reload()
            }
        }
    }
    
    
    @objc func updateLatestList() {
        queue_getListInfo.async {
            log("add a new job to update list info", self)
            manager.updateData(news: last.news, mode: DataRequestMode.latestItems)
            self.reload()
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
            }
            self.updateImg(index: -1)
        } // async end
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //log(scrollView.contentOffset, decelerate)
        if (scrollView.contentOffset.y > (scrollView.contentSize.height - scrollView.frame.size.height) + 70) && (manager.wxcList.count > 0) //70是触发操作的阀值
        {
            log(scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height), "44444444444") //触发上拉刷新
            DispatchQueue.main.async {
                self.loadingIndicator.startAnimating()
            }
            queue_getListInfo.async {
                log("add a new job to get more", self)
                manager.updateData(news: last.news, mode: DataRequestMode.moreItems)
                self.reload()
                self.updateImg(index: -1)
            }
        }
        /*
        log("scrollView.contentOffset.y =\(scrollView.contentOffset.y), scrollView.contentSize.height=\(scrollView.contentSize.height),  scrollView.frame.size.height=\(scrollView.frame.size.height)")
        if (scrollView.contentOffset.y < -70  && manager.wxcList.count > 0) //触发下拉刷新
        {
            loadingIndicator.startAnimating()
            queue_getListInfo.async {
                log("add a new job to update list info", self)
                manager.updateData(last.news, mode: DataRequestMode.latestItems)
                self.reload()
                self.loadingIndicator.stopAnimating()
                queue_getListImg.async {
                    log("add a new job to update images", self)
                    manager.wxcList.forEach {
                        $0.updateLogo()
                        self.reload()
                    }
                }
            } // async end
        }
         */
    } // End scrollViewDidEndDragging
    
    
    @IBAction func channelChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            manager.wxcCh = WxcChannels.news
        case 1:
            manager.wxcCh = WxcChannels.ent
        case 2:
            manager.wxcCh = WxcChannels.social
        case 3:
            manager.wxcCh = WxcChannels.blog
        default:
            break
        }
        self.listTableView.reloadData()
        log("segment.selectedSegmentIndex=\(sender.selectedSegmentIndex)")
        self.updateLatestList()
    }
    
} // End All for ListViewController
