//
//  TopicTableViewCell.swift
//  JS_Swift
//
//  Created by mac on 15/10/28.
//  Copyright © 2015年 mac. All rights reserved.
//

import UIKit
import SDWebImage

class TopicTableViewCell: UITableViewCell {

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var authorLabel: UILabel!
  @IBOutlet weak var briefLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var readCounts: UILabel!
  @IBOutlet weak var simpleImageView: UIImageView!
  
  var model: Topic? {
    didSet{
      titleLabel.text = model?.title
      authorLabel.text = model?.author
      briefLabel.text = model?.brief
      readCounts.text = "阅读量：\(model!.readCounts)"
      let format = NSDateFormatter()
      format.dateFormat = "yyyy-MM-dd"
      let dateString = format.stringFromDate(model!.date)
      dateLabel.text = dateString
      
      let imageURL = NSURL(string: model!.headpic)!
      simpleImageView.sd_setImageWithURL(imageURL)
    }
  }
  
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
      simpleImageView.clipsToBounds = true
      simpleImageView.layer.borderWidth = 1
      simpleImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
