//
//  YKFileItemCell.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/11.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit

protocol YKFileItemCellDelegate : AnyObject {
    func didClickAccessortBtn(file: YKFileItemCellWrap) -> Void
    func didClickArrow(cell:YKFileItemCell, fileItem:YKFileItemCellWrap, show:Bool) -> Void
    func didClickCancelDownload(cell:YKFileItemCell, fileItem:YKFileItemCellWrap) -> Void
    func didClickRetryDownload(cell:YKFileItemCell, fileItem:YKFileItemCellWrap) -> Void
    func didClickSuspendDownload(cell:YKFileItemCell, fileItem:YKFileItemCellWrap) -> Void
}

class YKFileItemCell: UITableViewCell {
    
    var selectIcon: UIImageView!
    var avatar: UIImageView!
    var titleLabel: UILabel!
    var subtitleLabel: UILabel!
    var arrow: UIImageView!
    var lockIcon: UIImageView!
    var sepline: UIView!
    
    var progressView: UIProgressView!
    var cancelBtn: UIButton!
    var retryBtn: UIButton!
    var stopBtn: UIButton!
    var errorInfoLabel: UILabel!
    var errorBtn: UIButton!
    
    var accessoryBtn: UIButton!
    
    weak var celldelegate: YKFileItemCellDelegate?
    
    var arrowFold = true
    
    var roundAvatar = false
    
    var fileItem: YKFileItemCellWrap!
    
    init(style: UITableViewCellStyle, reuseIdentifier: String?,delegate: YKFileItemCellDelegate) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.celldelegate = delegate
        self.setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bindData(file: YKFileItemCellWrap) {
        
        self.fileItem = file
        
        self.subtitleLabel.isHidden = !file.showSubTitle
        self.progressView.isHidden = !file.showProgress
        self.cancelBtn.isHidden = !file.showCancelBtn
        self.retryBtn.isHidden = !file.showRetryBtn
        self.stopBtn.isHidden = !file.showStopBtn
        self.errorInfoLabel.isHidden = !file.showErrorInfo
        self.errorBtn.isHidden = !file.showErrorInfo
        self.selectIcon.isHidden = !file.showSelectIcon
        self.arrow.isHidden = !file.showArrow
        self.accessoryBtn.isHidden = !file.showAccessoryBtn
        
        self.arrowFold = file.fold
        if !arrow.isHidden {
            if file.fold {
                arrow.image = YKImage("fileListArrowDown")
            } else {
                arrow.image = YKImage("fileListArrowUp")
            }
        }
        
        
        if file.disableSelect {
            titleLabel.textColor = YKColor.Disable
            subtitleLabel.textColor = YKColor.Disable
        } else {
            if file.isCached {
                titleLabel.textColor = YKAppearance.flCachedColor
                subtitleLabel.textColor = YKAppearance.flCachedColor
            } else {
                titleLabel.textColor = YKAppearance.flTitleColor
                subtitleLabel.textColor = YKAppearance.flSubtitleColor
            }
        }
        
        if !selectIcon.isHidden && file.selectType == .Hidden {
            selectIcon.image = nil
        }
        
        titleLabel.text = file.formatTitle
        if !subtitleLabel.isHidden { subtitleLabel.text = file.formatSubTitle }
        if !progressView.isHidden {
            if file.downloadItem != nil {
                let f: Float
                if file.downloadItem!.filesize == 0 {
                    f = 0
                } else {
                    f = Float(file.downloadItem!.offset)/Float(file.downloadItem!.filesize)
                }
                
                progressView.setProgress(f, animated: false)
            }
        }
        
        lockIcon.isHidden = (file.file.lock == 0)
        
        if !YKCommon.isSupportImage(file.file.filename) {
            let icon = YKFileIcon(file.file.filename, file.file.dir)
            avatar.image = icon
        } else {
            let webhost = YKClient.shareInstance.serverInfo.fullWebURL(path: "")
            avatar.sd_setImage(with: URL(string: file.file.thumb(webhost: webhost)), placeholderImage: YKFileIcon("1.xxx"), completed: nil)
        }
        
        selectIcon.isHidden = false
        switch file.selectType {
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
    
    private let AVATAR_SIZE: CGFloat = 36
    private let ARROW_WIDTH: CGFloat = 44
    
    func setupViews() {
        self.contentView.backgroundColor = UIColor.white
        
        var imageview = UIImageView(frame: CGRect(x: 15, y: 0, width: 16, height: 16))
        imageview.clipsToBounds = true
        imageview.contentMode = .scaleAspectFit
        imageview.image = YKImage("iconUnSelect")
        self.contentView.addSubview(imageview)
        self.selectIcon = imageview
        
        imageview = UIImageView(frame: CGRect(x: 0, y: 0, width: AVATAR_SIZE, height: AVATAR_SIZE))
        if roundAvatar {
            imageview.layer.masksToBounds = true
            imageview.layer.cornerRadius = AVATAR_SIZE/2
        }
        imageview.contentMode = .scaleAspectFit
        self.contentView.addSubview(imageview)
        self.avatar = imageview
        
        var label = UILabel(frame: CGRect.zero)
        label.textColor = YKAppearance.flTitleColor
        label.backgroundColor = self.contentView.backgroundColor
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingMiddle
        label.font = YKAppearance.flTitleFont
        label.numberOfLines = 0
        self.contentView.addSubview(label)
        self.titleLabel = label
        
        imageview = UIImageView(frame: CGRect.zero)
        imageview.image = YKImage("iconLock")
        imageview.backgroundColor = self.contentView.backgroundColor
        imageview.contentMode = .scaleAspectFit
        imageview.isHidden = true
        self.contentView.addSubview(imageview)
        self.lockIcon = imageview
        
        label = UILabel(frame: CGRect.zero)
        label.textColor = YKAppearance.flSubtitleColor
        label.backgroundColor = self.contentView.backgroundColor
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.font = YKAppearance.flSubtitleFont
        self.contentView.addSubview(label)
        self.subtitleLabel = label
        
        imageview = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        imageview.image = YKImage("fileListArrowDown")
        imageview.backgroundColor = self.contentView.backgroundColor
        imageview.contentMode = .center
        imageview.isUserInteractionEnabled = true
        self.contentView.addSubview(imageview)
        self.arrow = imageview
        
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(onArrowViewClick(gesture:)))
        self.arrow.addGestureRecognizer(tapgesture)
        
        let progress = UIProgressView(frame: CGRect.zero)
        self.contentView.addSubview(progress)
        progress.setProgress(0, animated: false)
        self.progressView = progress
        
        var button = UIButton(type: .custom)
        button.setImage(YKImage("iconCellCancel"), for: .normal)
        button.contentMode = .center
        self.contentView.addSubview(button)
        self.cancelBtn = button
        button.addTarget(self, action: #selector(onBtnCancel), for: .touchUpInside)
        
        button = UIButton(type: .custom)
        button.setImage(YKImage("iconCellStop"), for: .normal)
        button.contentMode = .center
        self.contentView.addSubview(button)
        self.stopBtn = button
        self.stopBtn.addTarget(self, action: #selector(onStopBtn), for: .touchUpInside)
        
        button = UIButton(type: .custom)
        button.setImage(YKImage("iconCellRetry"), for: .normal)
        button.contentMode = .center
        self.contentView.addSubview(button)
        self.retryBtn = button
        self.retryBtn.addTarget(self, action: #selector(onRetryBtn), for: .touchUpInside)
        
        
        button = UIButton(type: .custom)
        button.setImage(YKImage("iconCellInfo"), for: .normal)
        button.contentMode = .center
        button.isHidden = true
        self.contentView.addSubview(button)
        self.errorBtn = button
        
        label = UILabel(frame: CGRect.zero)
        label.textColor = YKAppearance.flSubtitleColor
        label.backgroundColor = self.contentView.backgroundColor
        label.textAlignment = .left
        label.font = YKAppearance.flSubtitleFont
        label.text = YKLocalizedString("缓存失败")
        label.sizeToFit()
        label.isHidden = true
        self.contentView.addSubview(label)
        self.errorInfoLabel = label
        
        button = UIButton(type: .custom)
        button.setImage(YKImage("iconRightArrow"), for: .normal)
        button.contentMode = .center
        button.isHidden = true
        self.contentView.addSubview(button)
        self.accessoryBtn = button
        button.addTarget(self, action: #selector(onAccessoryBtnClick), for: .touchUpInside)
        
        let line = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1.0/UIScreen.main.scale))
        line.backgroundColor = YKColor.Separator
        line.isOpaque = true
        self.contentView.addSubview(line)
        self.sepline = line
//        
//        switch downloadstatus {
//        case .Normal,.Error,.Start:
//            self.subtitleLabel.isHidden = true
//            self.lockIcon.isHidden = true
//            self.arrow.isHidden = true
//            self.progressView.isHidden = false
//        default:
//            self.subtitleLabel.isHidden = false
//            self.lockIcon.isHidden = false
//            self.arrow.isHidden = false
//            self.progressView.isHidden = true
//        }
    }
    
    func onBtnCancel() {
        if celldelegate != nil {
            celldelegate?.didClickCancelDownload(cell:self, fileItem:self.fileItem)
        }
    }
    
    func onRetryBtn() {
        if celldelegate != nil {
            celldelegate?.didClickRetryDownload(cell:self, fileItem:self.fileItem)
        }
    }
    
    func onStopBtn() {
        if celldelegate != nil {
            celldelegate?.didClickSuspendDownload(cell:self, fileItem:self.fileItem)
        }
    }
    
    func onAccessoryBtnClick() {
        if celldelegate != nil {
            celldelegate?.didClickAccessortBtn(file: fileItem)
        }
    }
    
    func onArrowViewClick(gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            if arrowFold {
                arrow.image = YKImage("fileListArrowUp")
                celldelegate?.didClickArrow(cell:self, fileItem:fileItem, show:true)
            } else {
                arrow.image = YKImage("fileListArrowDown")
                celldelegate?.didClickArrow(cell:self, fileItem:fileItem, show:false)
            }
            arrowFold = !arrowFold
        }
    }
    
    func setFold(_ fold: Bool) {
        if fold {
            arrow.image = YKImage("fileListArrowDown")
        } else {
            arrow.image = YKImage("fileListArrowUp")
        }
        self.arrowFold = fold
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let sz = CGSize(width: self.contentView.frame.size.width, height: fileItem.rowHeight) // self.contentView.frame.size
        
        let avatarSize = YKAppearance.flAvatarSize
        var rect = CGRect(x: 15, y: (sz.height-avatarSize)/2, width: avatarSize, height: avatarSize)
        if !selectIcon.isHidden {
            selectIcon.frame = CGRect(x: 15, y: (sz.height - 16)/2, width: 16, height: 16)
            rect.origin.x = selectIcon.frame.maxX + 10
        }
        
        self.avatar.frame = rect
        
        titleLabel.frame = CGRect(x: rect.maxX + 10, y: (sz.height - fileItem.titleSize.height - fileItem.subcontentSize.height)/2, width: fileItem.titleSize.width, height: fileItem.titleSize.height)
        
        if !subtitleLabel.isHidden {
            let lockW: CGFloat = (self.lockIcon.isHidden ? 0 : 11)
            
            var subtitleX = titleLabel.frame.minX
            if !self.lockIcon.isHidden {
                rect.origin.x = titleLabel.frame.minX
                rect.origin.y = titleLabel.frame.maxY + (fileItem.subcontentSize.height - lockW)/2
                rect.size = CGSize(width: lockW, height: lockW)
                self.lockIcon.frame = rect
                subtitleX = rect.maxX + 2
            }
            
            subtitleLabel.frame = CGRect(x: subtitleX, y: titleLabel.frame.maxY, width: titleLabel.frame.size.width - lockW, height: fileItem.subcontentSize.height)
        }
        
        if !arrow.isHidden {
            arrow.frame = CGRect(x: sz.width - ARROW_WIDTH, y: 0, width: ARROW_WIDTH, height: sz.height)
        }
        
        if !progressView.isHidden {
            let progressH: CGFloat = 5
            progressView.frame = CGRect(x: titleLabel.frame.minX, y: titleLabel.frame.maxY + fileItem.subcontentSize.height-progressH, width: titleLabel.frame.size.width, height: progressH)
        }
        
        var atail: CGFloat = 0
        if !cancelBtn.isHidden {
            cancelBtn.frame = CGRect(x: sz.width-44, y: 0, width: 44, height: sz.height-1)
            atail = (44 + 10)
        }
        
        if !retryBtn.isHidden {
            retryBtn.frame = CGRect(x: sz.width - atail - 44, y: 0, width: 44, height: sz.height-1)
        }
        
        if !stopBtn.isHidden {
            stopBtn.frame = CGRect(x: sz.width - atail - 44, y: 0, width: 44, height: sz.height-1)
        }
        
        if !accessoryBtn.isHidden {
            accessoryBtn.frame = CGRect(x: sz.width-44, y: 0, width: 44, height: sz.height-1)
        }
        
        if !errorInfoLabel.isHidden {
            errorInfoLabel.frame = CGRect(x: titleLabel.frame.minX, y: titleLabel.frame.maxY, width: errorInfoLabel.frame.size.width, height: fileItem.subcontentSize.height)
            let errorBtnSize: CGFloat = 16
            errorBtn.frame = CGRect(x: errorInfoLabel.frame.maxX+2, y: titleLabel.frame.maxY + (fileItem.subcontentSize.height - errorBtnSize)/2, width: errorBtnSize, height: errorBtnSize)
        }
        
        
//        let titleH = CGFloat(ceilf(Float(self.titleLabel.font.lineHeight)))
//        let subtitleH = CGFloat(ceilf(Float(self.subtitleLabel.font.lineHeight)))
//        
//        var subLabelH: CGFloat = subtitleH
//        if subtitleLabel.isHidden {
//            if progressView.isHidden && errorInfoLabel.isHidden {
//                subLabelH = 0
//            }
//        }
        
//        var tail: CGFloat = 15
//        
//        if !self.arrow.isHidden {
//            arrow.frame = CGRect(x: sz.width-ARROW_WIDTH, y: 0, width: ARROW_WIDTH, height: sz.height)
//            tail = (ARROW_WIDTH + 5)
//        } else if !self.cancelBtn.isHidden {
//            cancelBtn.frame = CGRect(x: sz.width-30, y: 0, width: 30, height: sz.height-1)
//            tail = cancelBtn.frame.size.width + 5
//        }
//        
//        let y = (sz.height - titleH - subLabelH)/2
//        rect.origin.y = y
//        rect.origin.x = rect.maxX + 10
//        rect.size = CGSize(width: sz.width-rect.origin.x-tail, height: titleH)
//        self.titleLabel.frame = rect
//        
//        let lockW: CGFloat = (self.lockIcon.isHidden ? 0 : 11)
//        
//        var subtitleX = titleLabel.frame.minX
//        if !self.lockIcon.isHidden {
//            rect.origin.y = titleLabel.frame.maxY + (subtitleH - lockW)/2
//            rect.size = CGSize(width: lockW, height: lockW)
//            self.lockIcon.frame = rect
//            subtitleX = rect.maxX + 2
//        }
//        
//        if !self.subtitleLabel.isHidden {
//            rect.origin.x = subtitleX
//            rect.origin.y = self.titleLabel.frame.maxY
//            rect.size = CGSize(width: sz.width - subtitleX - tail, height: subtitleH)
//            self.subtitleLabel.frame = rect
//        } else if !progressView.isHidden {
//            progressView.frame = CGRect(x: titleLabel.frame.minX, y: titleLabel.frame.maxY+(subLabelH-5)/2, width: titleLabel.frame.size.width, height: 5)
//        } else if !errorInfoLabel.isHidden {
//            errorInfoLabel.frame = CGRect(x: titleLabel.frame.minX, y: titleLabel.frame.maxY + (subLabelH-errorInfoLabel.frame.size.height)/2, width: errorInfoLabel.frame.size.width, height: errorInfoLabel.frame.size.height)
//            errorBtn.frame = CGRect(x: errorInfoLabel.frame.maxX+1, y: titleLabel.frame.maxY, width: 16, height: 16)
//        }
        
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
    
//    override func setEditing(_ editing: Bool, animated: Bool) {
//        super.setEditing(editing, animated: animated)
//        
//        if editing {
//            self.fileItem.showArrow = false
//            self.arrow.isHidden = true
//        } else {
//            self.fileItem.showArrow = true
//            self.arrow.isHidden = false
//        }
//    }
    
}
