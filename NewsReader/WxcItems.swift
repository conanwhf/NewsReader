//
//  WxcItems.swift
//  NewsReader
//
//  Created by Conan on 17/12/15.
//  Copyright © 2015年 Conan. All rights reserved.
//

import Foundation
import UIKit

private let default_logo = NSData(contentsOf: URL(string: "http://www.wenxuecity.com/images/wxc-logo.gif")!)

/**
 *  List Item, info for each item in list
 */
class WxcItems: Comparable {
    var postId: Int = 0
    var title: String = ""
    var time: String = ""
    
    private enum ItemLabel: String {
        case postid = "postid"
        case subid = "subid"
        case title = "title"
        case dateline = "dateline"
        case datetime = "datetime"
        case count = "count"
        case images = "images"
        case author = "author"
        case content = "content"
        case basecode = "basecode"
        case comment = "comment"
        case usr = "username"
        case usrface = "userface"
        case url = "url"
        case previous = "previous_news"
        case next = "next_news"
    }
    
    init? (fromdict dict: [String: Any]?) {
        // dict
        guard dict != nil else {
            return nil
        }
    }
    
    private func checkDataAvailable(fromdict dict: [String: Any], musthave must: ItemLabel...) -> Bool {
        let hasKeys = dict.keys
        var ret = true
        must.forEach { ret = ret && hasKeys.contains($0.rawValue) }
        return ret
    }
    
    private func refresh<T1, T2>(target: inout T1, value: T2?) {
        if let test = value as? T1 {
            target = test
        }
    }
}



// List Item, info for each item in list
class WxcListItem: WxcItems {
    var count: Int = 0
    private var images: [String] = []
    private var imgdata: NSData? = nil
    //private let _DEFAULT_LOGO_ = "http://www.wenxuecity.com/images/wxc-logo.gif"
    
    
    override init? (fromdict dict: [String: Any]?) {
        super.init(fromdict: dict)
        if !checkDataAvailable(fromdict: dict ?? [:], musthave: .postid, .title, .dateline, .count) {
            //printf("No data needed")
            return nil
        }
        dict?.forEach {
            switch $0.key {
            case ItemLabel.postid.rawValue:
                refresh(target: &postId, value: $0.value as? Int)
            case ItemLabel.title.rawValue:
                refresh(target: &title, value: $0.value as? String)
            case ItemLabel.dateline.rawValue:
                refresh(target: &time, value: $0.value as? String)
            case ItemLabel.count.rawValue:
                refresh(target: &count, value: $0.value as? Int)
            case ItemLabel.images.rawValue:
                //refresh(&images, value: $0.value)
                if let temp = $0.value as? [String] {
                    images.append(contentsOf: temp)
                }
            default:
                break
            }
        }
        //logodata = default_logo
        return
    }
    
    func updateLogo() {
        if imgdata == nil {
            log("img for \(self.postId), url=" + (self.images.isEmpty ? "nil" : "\(self.images[0])"))
            self.imgdata = self.images.isEmpty ? default_logo : NSData(contentsOf: URL(string: self.images[0])!)
            /*
            let before = UIImage(data: imgdata!)
            let after = reSizeImage(before!, toSize: CGSize(width: 150,height: 150))
            log("before: \(imgdata?.length), after:  \(UIImagePNGRepresentation(after)?.length))",self)
             imgdata = UIImagePNGRepresentation(after)
            */
        }
    }
    
    var logodata: NSData? {
        get {
            return imgdata == nil ? default_logo : imgdata
            /*
            if imgdata == nil {
                return (default_logo, true)
            }
            else {
                return (imgdata, false)
            }
*/
        }
    }
    
    func reSizeImage(image: UIImage, toSize reSize: CGSize) -> UIImage {
        let temp: Float = Float(image.size.width) / Float(reSize.width)
        reSize.height = CGFloat(Float(image.size.height) / temp)
        //print(reSize)
        UIGraphicsBeginImageContext(reSize)
        image.draw(in: CGRect(x: 0, y: 0, width: reSize.width, height: reSize.height))
        let reSizeImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return reSizeImage
    }

}

/// Post Comment Item
class WxcPostComment: WxcItems {
    var usrface: String = ""
    var usr: String = "NO-NAME"
    var content: String = ""
    
    override init? (fromdict dict: [String: Any]?) {
        super.init(fromdict: dict)
        
        if !checkDataAvailable(fromdict: dict ?? [:], musthave: .postid, .dateline, .usr) {
            //printf("No data needed")
            return nil
        }
        
        dict?.forEach {
            switch $0.key {
            case ItemLabel.postid.rawValue:
                refresh(target: &postId, value: $0.value as? Int)
            case ItemLabel.content.rawValue:
                refresh(target: &content, value: $0.value as? String)
            case ItemLabel.dateline.rawValue:
                refresh(target: &time, value: $0.value as? String)
            case ItemLabel.usr.rawValue:
                refresh(target: &usr, value: $0.value as? String)
            case ItemLabel.usrface.rawValue:
                refresh(target: &usrface, value: $0.value as? String)
            default:
                break
            }
        }
        return
    }
}

// Post Item, info about every post
class WxcPostItem: WxcItems {
    var content: String = ""
    var url: String = ""
    var subid: String = "news"
    var author: String = "UNKNOWN"
    var basecode: Int = 0
    var previous: Int = 0
    var next: Int = 0
    var count: Int = 0
    var images: [String] = []
    var comment: [WxcPostComment] = []
    
    override init? (fromdict dict: [String: Any]?) {
        super.init(fromdict: dict)
        
        if !checkDataAvailable(fromdict: dict ?? [:], musthave: .postid, .datetime, .title, .content) {
            return nil
        }
        
        dict?.forEach {
            switch $0.key {
            case ItemLabel.postid.rawValue:
                refresh(target: &postId, value: $0.value as? Int)
            case ItemLabel.title.rawValue:
                refresh(target: &title, value: $0.value as? String)
            case ItemLabel.content.rawValue:
                refresh(target: &content, value: $0.value as? String)
            case ItemLabel.datetime.rawValue:
                refresh(target: &time, value: $0.value as? String)
            case ItemLabel.images.rawValue:
                refresh(target: &images, value: $0.value as? [String])
            case ItemLabel.subid.rawValue:
                refresh(target: &subid, value: $0.value as? String)
            case ItemLabel.author.rawValue:
                refresh(target: &author, value: $0.value as? String)
            case ItemLabel.basecode.rawValue:
                refresh(target: &basecode, value: $0.value as? Int)
            case ItemLabel.count.rawValue:
                refresh(target: &count, value: $0.value as? Int)
            case ItemLabel.url.rawValue:
                refresh(target: &url, value: $0.value as? String)
            case ItemLabel.comment.rawValue:
                if let temp = $0.value as? [[String: String]] {
                    temp.forEach {
                        let new = WxcPostComment(fromdict: $0)
                        if new != nil {
                            comment.append(new!)
                        }
                    }
                }
            default:
                break
            }
        }
        return
    }
}


func < (lhs: WxcItems, rhs: WxcItems) -> Bool {
    return lhs.postId < rhs.postId
}

func == (lhs: WxcItems, rhs: WxcItems) -> Bool {
    return lhs.postId == rhs.postId
}
