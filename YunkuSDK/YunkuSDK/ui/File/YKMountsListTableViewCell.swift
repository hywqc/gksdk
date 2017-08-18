//
//  YKMountsListTableViewCell.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/9.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit
import gknet
import gkutility

fileprivate let _AVATAR_SIZE: CGFloat = 40.0

class YKMountsListTableViewCell: UITableViewCell {
    
    var titleLabel: UILabel!
    var subtitleLabel: UILabel!
    var avatarImageView: UIImageView!
    var sepline: UIView!
    var selectIcon: UIImageView!
    
    var itemData: YKMountItemCellWrap!
    
    
    init(style: UITableViewCellStyle, reuseIdentifier: String?, isMount: Bool) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupViews(isMount: isMount)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    func  bindData(item: YKMountItemCellWrap?) {
        if item != nil {
            itemData = item!
            titleLabel.numberOfLines = itemData.titleLines
            titleLabel.text = itemData.formatTitle
            subtitleLabel.text = itemData.formatSubtitle
            if itemData.mountItem != nil {
                let url = URL(string: itemData.mountItem!.org_logo_url)
                self.avatarImageView.sd_setImage(with: url, placeholderImage: YKImage("iconDefaultLib"))
            } else if itemData.favid != nil {
                self.avatarImageView.backgroundColor = itemData.favid!.magicColor
            }
            
            subtitleLabel.isHidden = (itemData.subtitleHeight <= 0)
            
            selectIcon.isHidden = false
            switch itemData.selectType {
            case .None,.Disable:
                selectIcon.isHidden = true
            case .Hidden:
                selectIcon.image = nil
            case .Selected:
                selectIcon.image = YKImage("iconSelect")
            case .UnSelected:
                selectIcon.image = YKImage("iconUnSelect")
            case .DiableSelected:
                selectIcon.image = YKImage("iconDisableSelect")
            }
        }
    }
    
    func setupViews(isMount: Bool) {
        
        let avatarSize = YKAppearance.mlAvatarSize
        
        var imageview = UIImageView(frame: CGRect(x: 15, y: 0, width: avatarSize, height: avatarSize))
        imageview.clipsToBounds = true
        if isMount {
            imageview.image = YKImage("iconDefaultLib")
        }
        imageview.layer.masksToBounds = true
        imageview.layer.cornerRadius = avatarSize/2
        self.contentView.addSubview(imageview)
        self.avatarImageView = imageview
        
        imageview = UIImageView(frame: CGRect(x: 15, y: 0, width: 16, height: 16))
        imageview.clipsToBounds = true
        imageview.contentMode = .scaleAspectFit
        imageview.image = YKImage("iconUnSelect")
        self.contentView.addSubview(imageview)
        self.selectIcon = imageview
        
        
        var label = UILabel(frame: CGRect.zero)
        label.textColor = YKAppearance.mlTitleColor
        label.textAlignment = .left
        label.font = YKAppearance.mlTitleFont
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingMiddle
        self.contentView.addSubview(label)
        self.titleLabel = label
        
        label = UILabel(frame: CGRect.zero)
        label.textColor = YKAppearance.mlSubtitleColor
        label.textAlignment = .left
        label.font = YKAppearance.mlSubtitleFont
        self.contentView.addSubview(label)
        self.subtitleLabel = label
        
        label.isHidden = !isMount
        
        let line = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1.0/UIScreen.main.scale))
        line.backgroundColor = YKColor.Separator
        line.isOpaque = true
        self.contentView.addSubview(line)
        self.sepline = line
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let sz = CGSize(width: self.contentView.frame.size.width, height: itemData.rowHeight)
        
        let avatarSize = YKAppearance.mlAvatarSize
        let selectIconSize: CGFloat = 20
        
        var rect = CGRect(x: 15, y: (sz.height-avatarSize)/2, width: avatarSize, height: avatarSize)
        
        if !self.selectIcon.isHidden {
            selectIcon.frame = CGRect(x: 15, y: (sz.height-selectIconSize)/2, width: selectIconSize, height: selectIconSize)
            rect.origin.x = selectIcon.frame.maxX + 10
        }
        
        self.avatarImageView.frame = rect
        
//        let titleH = CGFloat(ceilf(Float(self.titleLabel.font.lineHeight)))
//        let subtitleH = (subtitleLabel.isHidden ? 0 :  CGFloat(ceilf(Float(self.subtitleLabel.font.lineHeight))))
        
        let titleH = itemData.titleHeight
        let subtitleH = itemData.subtitleHeight
        
        let y = (sz.height - titleH - subtitleH)/2
        rect.origin.y = y
        rect.origin.x = rect.maxX + 10
        rect.size = CGSize(width: sz.width-rect.origin.x-10, height: titleH)
        self.titleLabel.frame = rect
        
        if !self.subtitleLabel.isHidden {
            rect.origin.y = rect.maxY
            rect.size = CGSize(width: self.titleLabel.frame.size.width, height: itemData.subtitleHeight)
            self.subtitleLabel.frame = rect
        }
        
        self.sepline.frame = CGRect(x: titleLabel.frame.minX, y: sz.height-sepline.frame.size.height, width: sz.width - titleLabel.frame.minX, height: sepline.frame.size.height)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            selectIcon.image = YKImage("iconSelect")
        } else {
            selectIcon.image = YKImage("iconUnSelect")
        }
    }
}
