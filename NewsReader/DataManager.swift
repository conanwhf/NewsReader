//
//  DataManager.swift
//  NewsReader
//
//  Created by Conan on 17/12/15.
//  Copyright © 2015年 Conan. All rights reserved.
//

import Foundation

let manager = NewsDataManager()


func log<T>(_ message: T, _ marker: Any? = nil) {
    #if DEBUG
        //print(" \(__FUNCTION__) in \(__FILE__): \(message), from \(self)")
        NSLog("\(message), mark: \(marker ?? "nil")")
    #else
        //print("\(message), mark: \(marker)")
    #endif
}

func logn(_ n: Int) {
    #if DEBUG
        NSLog(String(repeating: "\(n)", count: 14))
    #else
        //print("\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)\(n)")
    #endif
}


enum NewsType: Int {
    case wenxuecity = 3
    case qiushi
    case channel8
    case wuyun
    case lifeinterst
}

enum DataRequestMode {
    case moreItems
    case latestItems
    case post
}

class NewsDataManager {
    private var url: URL
    private var wxc = (api: WxcAPI(), list: Array<Array<WxcListItem>>(repeating: [], count: 5), post: WxcPostItem?, channel: WxcChannels.news)
    
    private init() {
        url = URL(string: "")!
    }

    func updateData(news: NewsType, mode: DataRequestMode, id: Int = 0) {
        switch (news, mode) {
        case (.wenxuecity, .latestItems):
            url = wxc.api.getURL(requestChannel: wxc.channel, last: id)
        case (.wenxuecity, .moreItems):
            url = wxc.api.getURL(requestChannel: wxc.channel, last: wxc.list[wxc.channel.rawValue].last?.postId ?? 0)
        case (.wenxuecity, .post):
            url = wxc.api.getURL(postId: id, requestChannel: wxc.channel)
        default:
            break
        }
        fillData(news: news)
        log(url, self)
    }
    
    
    /**
     填数据，通过拿到的URL，把list或post数据根据JSON解析出来，填到数据结构中
     - parameter news: 指定新闻网站
     */
    private func fillData(news: NewsType) {
        guard let data = try? Data(contentsOf: url) else {
            log("No data", self)
            return
        }
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            
            if let more = json["list"] as? [[String: Any]] {
                for item in more {
                    if let temp = WxcListItem(fromdict: item) {
                        inserItemToList(target: temp, arr: &wxc.list[wxc.channel.rawValue])
                    }
                }
            }
            
            if let newpost = json as? [String: Any] {
                wxc.post = WxcPostItem(fromdict: newpost)
            }
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
    private func inserItemToList<T: Comparable>(target: T, arr: inout [T]) {
        if arr.isEmpty {
            arr.append(target)
            return
        }
        if arr.contains(target) {
            return
        }
        if let first = arr.first, first < target {
            arr.insert(target, at: 0)
            return
        }
        if let last = arr.last, last > target {
            arr.append(target)
            return
        }
        for i in 0..<arr.count-1 {
            if let current = arr[i], let next = arr[i+1] {
                if current > target && next < target {
                    arr.insert(target, at: i+1)
                    return
                }
            }
        }
    }
    
    /// 计算属性，用来获取属性，实现只读封装
    var wxcList: [WxcListItem] {
        get {
            return wxc.list[wxc.channel.rawValue]
        }
    }
    var wxcPost: WxcPostItem? {
        get {
            return wxc.post
        }
    }
    var wxcCh: WxcChannels {
        get {
            return wxc.channel
        }
        set(channel) {
            wxc.channel = channel
        }
    }
    var wxcGetItemNum: Int {
        get {
            return wxc.api.pagesize
        }
        set(size) {
            if size > 100 {
                log("Too many data will be refused", self)
            } else {
                wxc.api.pagesize = size
            }
        }
    }
    
}
