//
//  ListTableViewCell.swift
//  NewsReader
//
//  Created by Conan on 08/01/16.
//  Copyright © 2016年 Conan. All rights reserved.
//

import UIKit

private let BASE_FONT_SIZE :CGFloat = 18
private let V_BLANK = 10
private let ITEM_OFFSET = 5

class ListTableViewCell: UITableViewCell {

    var img:UIImageView!
    var title:UILabel!
    var info:UILabel!
    
    func layout() ->(frameImg: CGRect, FrameTitle: CGRect, FrameInfo: CGRect){
        let totalx = Int(self.frame.width)
        let totaly = Int(self.frame.height)
        let img_w = (totaly-ITEM_OFFSET*2)*4/3
        let title_x = V_BLANK+img_w+ITEM_OFFSET
        let title_h = Int(Float(totaly - ITEM_OFFSET*3)*4/5)
        let title_w = totalx-img_w-V_BLANK*2-ITEM_OFFSET

        let frameImg = CGRect(x: V_BLANK, y: ITEM_OFFSET, width: img_w, height: totaly - ITEM_OFFSET*2)
        let frameTitle = CGRect(x: title_x, y: ITEM_OFFSET, width: title_w, height: title_h)
        let frameInfo = CGRect(x: title_x, y: ITEM_OFFSET*2+Int(frameTitle.height), width: title_w, height: totaly - ITEM_OFFSET*3-title_h)

        return (frameImg, frameTitle, frameInfo)
    }
    
/*
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        logn(1)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        logn(2)
        print(aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
*/
    func showListItemInfo(index: Int){
//        let labelWitdth = Int(self.frame.width) - IMG_WIDTH - 20
        let temp = layout()

        // Configure the cell...

        //先删掉旧的
        self.subviews.filter({$0.tag == 0x119}).forEach{$0.removeFromSuperview()}
        title = UILabel(frame: temp.1)
        info = UILabel(frame: temp.2)
        img = UIImageView(frame: temp.0)
        
        //Title Config
        title.lineBreakMode = .ByClipping
//            title.font = UIFont.systemFontOfSize(BASE_FONT_SIZE)
        title.numberOfLines = 2
        title.adjustsFontSizeToFitWidth = true
        title.text = manager.wxcList[index].title
        
        //Info config
        info.font = UIFont.systemFontOfSize(BASE_FONT_SIZE-6)
        info.numberOfLines = 1
//            info.minimumScaleFactor = 10.0
        info.adjustsFontSizeToFitWidth = true
        info.textColor = UIColor.grayColor()
        info.text = "🖊"+manager.wxcList[index].time + "    📖 \(manager.wxcList[index].count)"
        
        // Image config
        img.image = UIImage(data: manager.wxcList[index].logodata!)
        img.contentMode = .ScaleAspectFit
        img.layer.masksToBounds = true
        img.layer.cornerRadius = 8.0
        
        title.tag = 0x119
        info.tag = 0x119
        img.tag = 0x119
        self.addSubview(title)
        self.addSubview(info)
        self.addSubview(img!)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
