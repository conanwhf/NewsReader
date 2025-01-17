//
//  DataManager.swift
//  NewsReader
//
//  Created by Conan on 17/12/15.
//  Copyright © 2015年 Conan. All rights reserved.
//

import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


var manager : NewsDataManager = NewsDataManager()


func log <T> (_ message: T , _ marker: AnyObject? = nil )  {
    #if DEBUG
        //print(" \(__FUNCTION__) in \(__FILE__): \(message), from \(self)")
        NSLog("\(message), mark: \(marker)")
    #else
        //print("\(message), mark: \(marker)")
    #endif
}
func logn (_ n :Int )  {
    #if DEBUG
        NSlog("\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)")
    #else
        //print("\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)")
    #endif
}


enum NewsType :Int {
    case wenxuecity = 3
    case qiushi
    case channel8
    case wuyun
    case lifeinterst
}

enum DataRequestMode{
    case moreItems
    case latestItems
    case post
}

class NewsDataManager {    
    fileprivate var url :URL
    fileprivate var wxc = ( api : WxcAPI, list:  Array<Array<WxcListItem>>,  post: WxcPostItem?,  channel: WxcChannels) (WxcAPI(), list: [[],[],[],[],[]], post: nil, .news)
    
    fileprivate init (){
        url = URL(string:"")!
        return
    }

    func updateData(_ news: NewsType, mode: DataRequestMode, id: Int = 0) {
        switch (news, mode) {
        case (.wenxuecity, .latestItems) :            url = wxc.api.getURL(requestChannel: wxc.channel, last: id) as URL
        case (.wenxuecity, .moreItems) :            url = wxc.api.getURL(requestChannel: wxc.channel, last: wxc.list[wxc.channel.rawValue].last!.postId) as URL
        case (.wenxuecity, .post) :                      url = wxc.api.getURL(postId: id, requestChannel: wxc.channel) as URL
        default: break
        }
        fillData(news)
        log(url, self)
    }
    
    
    /**
     填数据，通过拿到的URL，把list或post数据根据JSON解析出来，填到数据结构中
     - parameter news: 指定新闻网站
     */
    fileprivate func fillData(_ news: NewsType)  {
        guard let data = try? Data(contentsOf: url) else {
            log("No data",self)
            return
        }
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
            
            let more : NSArray? = (json as? [String: Any])?["list"] as? NSArray
            more?.forEach({
                let temp = WxcListItem(fromdict: ($0 as! ([ String: AnyObject]) ))
                if temp != nil {
                    inserItemToList(temp!, arr: &wxc.list[wxc.channel.rawValue])
                }
            })
            
            let newpost = (json as? [String: AnyObject])
            wxc.post = WxcPostItem(fromdict: newpost)
            //log(wxc.post?.content)
        } catch {
            NSLog("JSONObjectWithData: \(error)")
        }
    }
    
    /**
     插入一个新的item进入List，list由大到小排列（新闻最新的显示在最前），有相同的数据则丢弃
     - parameter target: 待处理数据item
     - parameter arr:    目标List
     */
    fileprivate func inserItemToList < T: Comparable > (_ target: T, arr:inout Array< T >) {
        target
        if arr.isEmpty {
            return arr.append(target)
        }
        if arr.contains(target){
            return
        }
        if arr.first < target {
            return arr.insert(target, at: 0)
        }
        if arr.last > target {
            return arr.append(target)
        }
        for i in 0...arr.count-2 {
            if (arr[i] > target) && (arr[i+1] < target) {
                return arr.insert(target, at: i+1)
            }
        }
    }
    
    /// 计算属性，用来获取属性，实现只读封装
    var wxcList : Array<WxcListItem> {
        get {
            return wxc.list[wxc.channel.rawValue]
        }
    }
    var wxcPost : WxcPostItem? {
        get {
            return wxc.post
        }
    }
    var wxcCh : WxcChannels {
        get {
            return wxc.channel
        }
        set (channel) {
            wxc.channel = channel
        }
    }
    var wxcGetItemNum : Int {
        get {
            return wxc.api.pagesize
        }
        set (size) {
            if size > 100 {
                log("Too many data will be refused",self)
            }
            else {
                wxc.api.pagesize = size
            }
        }
    }
    
}
