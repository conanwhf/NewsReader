//
//  wxcItems.swift
//  NewsReader
//
//  Created by Conan on 17/12/15.
//  Copyright © 2015年 Conan. All rights reserved.
//

import Foundation
import UIKit

private let default_logo = try? Data(contentsOf: URL(string: "http://www.wenxuecity.com/images/wxc-logo.gif")!)

/**
 *  List Item, info for each item in list
 */
class WxcItems : Comparable {
    var postId : Int = 0
    var title: String = ""
    var time : String = ""
    
    fileprivate enum ItemLable : String {
        case postid  = "postid"
        case subid     = "subid"
        case title   = "title"
        case dateline     = "dateline"
        case datetime   = "datetime"
        case count  = "count"
        case images  = "images"
        case author  = "author"
        case content     = "content"
        case basecode  = "basecode"
        case comment    = "comment"
        case usr   = "username"
        case usrface   = "userface"
        case url   = "url"
        case previous  = "previous_news"
        case next  = "next_news"
    }
    
    init? (fromdict dict: [ String: AnyObject ]?){
        // dict
        guard dict != nil else{
            return nil
        }
    }
    
    fileprivate func checkDataAviliable(fromdict dict: [ String: AnyObject ], musthave must: ItemLable...) -> Bool {
        let hasKeys = dict.keys
        var ret = true
        must.forEach({ret = ret && hasKeys.contains($0.rawValue)})
        return ret
    }
    
    fileprivate func refresh < T1, T2 > (_ target: inout T1, value : T2?){
        let test = value as? T1
        target = ((test == nil) ? target : (test!))
    }
}



// List Item, info for each item in list
class WxcListItem : WxcItems {
    var count : Int = 0
    fileprivate var images : Array<String> = []
    fileprivate var imgdata : Data? = nil
    //private let _DEFAULT_LOGO_ = "http://www.wenxuecity.com/images/wxc-logo.gif"
    
    
    override init? (fromdict dict: [ String: AnyObject ]?){
        super.init(fromdict: dict)
        if !checkDataAviliable(fromdict: dict!, musthave: .postid, .title, .dateline, .count) {
            //printf("No data needed")
            return nil
        }
        dict!.forEach({
            switch $0.0 {
            case ItemLable.postid.rawValue :    refresh(&postId, value: ($0.1 as? NSNumber)?.intValue)
            case ItemLable.title.rawValue :         refresh(&title, value: $0.1)
            case ItemLable.dateline.rawValue :  refresh(&time, value: $0.1)
            case ItemLable.count.rawValue :     refresh(&count, value: ($0.1 as? NSNumber)?.intValue)
            case ItemLable.images.rawValue :    //refresh(&images, value: $0.1)
                let temp = $0.1 as? Array<String>
                temp?.forEach{ images.append($0)}
            default: break
            }
        })
        //logodata = default_logo
        return
    }
    
    func updateLogo() {
        if imgdata == nil {
            log("img for \(self.postId), url=" + (self.images.isEmpty ? "nil" : "\(self.images[0])"))
            self.imgdata = self.images.isEmpty ? default_logo :(try? Data(contentsOf: URL(string: self.images[0])!))
            /*
            let before = UIImage(data: imgdata!)
            let after = reSizeImage(before!, toSize: CGSize(width: 150,height: 150))
            log("before: \(imgdata?.length), after:  \(UIImagePNGRepresentation(after)?.length))",self)
             imgdata = UIImagePNGRepresentation(after)
            */
        }
    }
    
    var logodata : Data?{
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
    
    func reSizeImage(_ image: UIImage, toSize reSize: CGSize) -> UIImage {
        var reSize = reSize
        let temp:Float = Float(image.size.width) / Float(reSize.width)
        reSize.height = CGFloat(Float(image.size.height) / temp)
        //print(reSize)
        UIGraphicsBeginImageContext(CGSize(width: reSize.width, height: reSize.height))
        image.draw(in: CGRect(x: 0, y: 0, width: reSize.width, height: reSize.height))
        let reSizeImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return reSizeImage
    }

}

/// Post Comment Item
class WxcPostComment  : WxcItems{
    var usrface : String = ""
    var usr : String     = "NO-NAME"
    var content : String = ""
    
    override init? (fromdict dict: [ String: AnyObject ]?){
        super.init(fromdict: dict)
        
        if !checkDataAviliable(fromdict: dict!, musthave: .postid,  .dateline, .usr) {
            //printf("No data needed")
            return nil
        }
        
        dict!.forEach({
            switch $0.0 {
            case ItemLable.postid.rawValue :    refresh(&postId, value: ($0.1 as? NSNumber)?.intValue)
            case ItemLable.content.rawValue :   refresh(&content, value: $0.1)
            case ItemLable.dateline.rawValue :  refresh(&time, value: $0.1)
            case ItemLable.usr.rawValue :           refresh(&usr, value: $0.1)
            case ItemLable.usrface.rawValue :   refresh(&usrface, value: $0.1)
            default: break
            }
        })
        return
    }
}

// Post Item, info about every post
class WxcPostItem : WxcItems {
    var content : String       = ""
    var url : String           = ""
    var subid : String         = "news"
    var author : String        = "UNKNOWN"
    var basecode : Int         = 0
    var previous : Int         = 0
    var next : Int             = 0
    var count : Int            = 0
    var images : Array<String> = []
    var comment : Array<WxcPostComment> = []
    
    override init? (fromdict dict: [ String: AnyObject ]?){
        super.init(fromdict: dict)
        
        if !checkDataAviliable(fromdict: dict!, musthave: .postid,  .datetime, .title, .content) {
            return nil
        }
        
        dict!.forEach({
            switch $0.0 {
            case ItemLable.postid.rawValue :        refresh(&postId, value: ($0.1 as? NSNumber)?.intValue)
            case ItemLable.title.rawValue :             refresh(&title, value: $0.1)
            case ItemLable.content.rawValue :       refresh(&content, value: $0.1)
            case ItemLable.datetime.rawValue :     refresh(&time, value: $0.1)
            case ItemLable.images.rawValue :       refresh(&images, value: $0.1)
            case ItemLable.subid.rawValue :          refresh(&subid, value: $0.1)
            case ItemLable.author.rawValue :         refresh(&author, value: $0.1)
            case ItemLable.basecode.rawValue :    refresh(&basecode, value: ($0.1 as? NSNumber)?.intValue)
            case ItemLable.count.rawValue :         refresh(&count, value: ($0.1 as? NSNumber)?.intValue)
            case ItemLable.url.rawValue :               refresh(&url, value: $0.1)
            case ItemLable.comment.rawValue :
                let temp = $0.1 as? Array<AnyObject>
                temp?.forEach({
                    let new = WxcPostComment(fromdict: ($0 as! ([ String: String]) as [String : AnyObject]? ))
                    if new != nil {
                        comment.append(new!)
                    }
                })
            default: break
            }
        })
        return
    }
}


func < (lhs: WxcItems, rhs: WxcItems) -> Bool {
    return lhs.postId < rhs.postId
}

func == (lhs: WxcItems, rhs: WxcItems) -> Bool{
    return lhs.postId == rhs.postId
}
