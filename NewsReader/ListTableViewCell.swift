//
//  ListTableViewCell.swift
//  NewsReader
//
//  Created by Conan on 08/01/16.
//  Copyright © 2016年 Conan. All rights reserved.
//

import UIKit

let CELL_ID = "NewsList"

private let BASE_FONT_SIZE: CGFloat = 18
private let V_BLANK = 10
private let ITEM_OFFSET = 5

class ListTableViewCell: UITableViewCell {

    @IBOutlet weak var imgImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset any custom configurations
    }

    func showListItemInfo(index: Int) {
        //Title Config
        titleLabel.lineBreakMode = .byClipping
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.text = manager.wxcList[index].title
        
        //Info config
        infoLabel.font = UIFont.systemFont(ofSize: BASE_FONT_SIZE - 6)
        infoLabel.numberOfLines = 1
        infoLabel.adjustsFontSizeToFitWidth = true
        infoLabel.textColor = .gray
        infoLabel.text = "🖊" + manager.wxcList[index].time + "    📖 \(manager.wxcList[index].count)"
        
        // Image config
        imgImageView.image = UIImage(data: manager.wxcList[index].logodata!)
        imgImageView.contentMode = .scaleAspectFit
        imgImageView.layer.masksToBounds = true
        imgImageView.layer.cornerRadius = 8.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
