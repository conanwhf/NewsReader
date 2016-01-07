//
//  DataManager.swift
//  NewsReader
//
//  Created by Conan on 17/12/15.
//  Copyright © 2015年 Conan. All rights reserved.
//

import Foundation

var manager : NewsDataManager = NewsDataManager()


func log <T> (message: T , _ marker: AnyObject? = nil )  {
    #if DEBUG
        //print(" \(__FUNCTION__) in \(__FILE__): \(message), from \(self)")
        NSLog("\(message), mark: \(marker)")
    #endif
}
func logn (n :Int )  {
    #if DEBUG
        print("\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)")
    #endif
}


enum NewsType{
    case wenxuecity
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
    private var url :NSURL
    private var wxc = ( api : WxcAPI, list:  Array<Array<WxcListItem>>,  post: WxcPostItem?,  channel: WxcChannels) (WxcAPI(), list: [[],[],[],[],[]], post: nil, .news)
    
    private init (){
        url = NSURL(string:"")!
        return
    }

    func updateData(news: NewsType, mode: DataRequestMode, id: Int = 0) {
        switch (news, mode) {
        case (.wenxuecity, .latestItems) :            url = wxc.api.getURL(requestChannel: wxc.channel, last: id)
        case (.wenxuecity, .moreItems) :            url = wxc.api.getURL(requestChannel: wxc.channel, last: wxc.list[wxc.channel.rawValue].last!.postId)
        case (.wenxuecity, .post) :                      url = wxc.api.getURL(postId: id, requestChannel: wxc.channel)
        default: break
        }
        fillData(news)
        log(url, self)
    }
    
    
    /**
     填数据，通过拿到的URL，把list或post数据根据JSON解析出来，填到数据结构中
     - parameter news: 指定新闻网站
     */
    private func fillData(news: NewsType)  {
        guard let data = NSData(contentsOfURL: url) else {
            log("No data",self)
            return
        }
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)
            
            let more : NSArray? = json["list"] as? NSArray
            more?.forEach({
                let temp = WxcListItem(fromdict: ($0 as! ([ String: AnyObject]) ))
                if temp != nil {
                    inserItemToList(temp!, arr: &wxc.list[wxc.channel.rawValue])
                }
            })
            
            let newpost = json as? ([ String: AnyObject])
            wxc.post = WxcPostItem(fromdict: newpost)
            //log(wxc.post?.content)
        } catch {
            print("JSONObjectWithData: \(error)")
        }
    }
    
    /**
     插入一个新的item进入List，list由大到小排列（新闻最新的显示在最前），有相同的数据则丢弃
     - parameter target: 待处理数据item
     - parameter arr:    目标List
     */
    private func inserItemToList < T: Comparable > (target: T, inout arr:Array< T >) {
        target
        if arr.isEmpty {
            return arr.append(target)
        }
        if arr.contains(target){
            return
        }
        if arr.first < target {
            return arr.insert(target, atIndex: 0)
        }
        if arr.last > target {
            return arr.append(target)
        }
        for i in 0...arr.count-2 {
            if (arr[i] > target) && (arr[i+1] < target) {
                return arr.insert(target, atIndex: i+1)
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

