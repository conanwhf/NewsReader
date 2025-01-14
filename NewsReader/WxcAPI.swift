//
//  WxcAPI.swift
//  NewsReader
//
//  Created by Conan on 17/12/15.
//  Copyright © 2015年 Conan. All rights reserved.
//

import Foundation

enum WxcChannels : Int {
    case news = 0
    case ent = 1
    case social = 2
    case blog = 3
    case bbs = 4
}
let wxcChannelArr = ["新闻", "娱乐", "社会"]

struct WxcAPI  {
    fileprivate let _APIURL_BASE      = "http://api.wenxuecity.com/service/api/?"
    fileprivate let _CALLBACK_ID      = "CONANTEST"
    fileprivate let _FORMAT_             =  "json"
    fileprivate let _CHANNELS           = ["&channel=news", "&channel=ent", "&channel=gossip", "&func=blog", "&func=bbs"]
    var pagesize = 30
    /*  - act: {
            view. ( - id)
            list.    ( - lastID,  - pagesize)
            index(永远返回24个)}
        - version:      1. 2
        - channel:      news. bbs. blog. ent
        - format:   {jsonp(- callback:). json. xml}
        bbs&blog数据不一样
    */
    
    /**
     根据需要生成URL （请求List数据)
     - parameter ch: 请求的频道名字， news. bbs. blog. hot. passport. search. ads. qqh
     - parameter last: 最后post ID，为0的时候为请求最新数据
     - parameter num:  返回的item数量
     */
    func getURL( requestChannel ch : WxcChannels, last: Int = 0 ) -> URL {
        //act=list, channel, format, lastid, pagesize
        var st = _APIURL_BASE + "&act=list&version=2" + ("&format=" + _FORMAT_ )
        st = st + _CHANNELS[ch.rawValue] + "&lastID=\(last)" + "&pagesize=\(pagesize)"
        return URL(string: st)!
    }
    
    /**请求单篇文章数据）
     - parameter id: 请求的PostID
     - parameter ver: 返回数据使用版本，默认为2
     */
    func getURL(postId id: Int, requestChannel ch : WxcChannels, ver : Int = 2 ) -> URL {
        //act=view, format, version
        var st = _APIURL_BASE + "&act=view" + ("&format=" + _FORMAT_ )
        st = st + "&version=\(ver)" + "&id=\(id)" + _CHANNELS[ch.rawValue]
        return URL(string: st)!
    }

    //如果需要针对网站预先处理
    fileprivate func operation(_ st: inout String) {
        //TODO: do sth. about string
    }

    func speicalForData(_ data : Data) -> Data? {
        var st = String(data: data, encoding: String.Encoding.utf8)!
        self.operation(&st)
        return st.data(using: String.Encoding.utf8)
    }
    
    func speicalForData(_ st : String) -> Data? {
        var st = st
        self.operation(&st)
        return st.data(using: String.Encoding.utf8)
    }
}

