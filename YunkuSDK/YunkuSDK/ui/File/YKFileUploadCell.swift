//
//  YKFileUploadCell.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/24.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation

protocol YKFileUploadCellDelegate : AnyObject {
    func didClickStopBtn(cell:YKFileUploadCell, uploadItem: YKUploadItemData?) -> Void
    func didClickCancelBtn(cell:YKFileUploadCell, uploadItem: YKUploadItemData?) -> Void
    func didClickRetryBtn(cell:YKFileUploadCell, uploadItem: YKUploadItemData?) -> Void
    func didClickErrorBtn(cell:YKFileUploadCell, uploadItem: YKUploadItemData?) -> Void
}


class YKFileUploadCell: UITableViewCell {
    
    var avatar: UIImageView!
    var titleLabel: UILabel!
    
    var sepline: UIView!
    
    var progressView: UIProgressView!
    var cancelBtn: UIButton!
    var stopBtn: UIButton!
    var retryBtn: UIButton!
    var infoLabel: UILabel!
    var errorBtn: UIButton!
    
    var uploadItem: YKUploadItemData?
    
    weak var celldelegate: YKFileUploadCellDelegate?
    
    init(style: UITableViewCellStyle, reuseIdentifier: String?,delegate: YKFileUploadCellDelegate) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.celldelegate = delegate
        self.setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setprogress(_ p: Float) {
        self.progressView.isHidden = false
        self.cancelBtn.isHidden = false
        self.stopBtn.isHidden = false
        self.retryBtn.isHidden = true
        self.errorBtn.isHidden = true
        self.infoLabel.isHidden = true
        self.progressView.setProgress(p, animated: false)
    }
    
    func bindData(item: YKUploadItemData) {
        
        self.uploadItem = item
        
        self.titleLabel.text = item.filename
        
        
        switch item.status {
        case .Normal:
            self.progressView.isHidden = true
            self.cancelBtn.isHidden = false
            self.retryBtn.isHidden = true
            self.stopBtn.isHidden = true
            self.errorBtn.isHidden = true
            self.infoLabel.isHidden = false
            self.infoLabel.text = YKLocalizedString("等待上传")
        case .Start:
            self.progressView.isHidden = false
            self.cancelBtn.isHidden = false
            self.stopBtn.isHidden = false
            self.retryBtn.isHidden = true
            self.errorBtn.isHidden = true
            self.infoLabel.isHidden = true
            let p: Float = Float((Double(item.offset)/Double(item.filesize)))
            self.progressView.setProgress(p, animated: false)
        case .Stop:
            self.progressView.isHidden = false
            self.cancelBtn.isHidden = false
            self.retryBtn.isHidden = false
            self.stopBtn.isHidden = true
            self.errorBtn.isHidden = true
            self.infoLabel.isHidden = true
            let p: Float = Float((Double(item.offset)/Double(item.filesize)))
            self.progressView.setProgress(p, animated: false)
        case .Error:
            self.progressView.isHidden = true
            self.cancelBtn.isHidden = false
            self.retryBtn.isHidden = false
            self.stopBtn.isHidden = true
            self.errorBtn.isHidden = false
            self.infoLabel.isHidden = false
            self.infoLabel.text = YKLocalizedString("上传失败")
        case .Finish:
            self.progressView.isHidden = true
            self.cancelBtn.isHidden = true
            self.retryBtn.isHidden = true
            self.stopBtn.isHidden = true
            self.errorBtn.isHidden = true
            self.infoLabel.isHidden = false
            self.infoLabel.text = YKLocalizedString("上传完成")
        default:
            self.progressView.isHidden = true
        }
        
        if item.status != .Finish {
            if !YKCommon.isSupportImage(item.filename) {
                let icon = YKFileIcon(item.filename, item.dir)
                avatar.image = icon
            } else {
                avatar.image = UIImage(contentsOfFile: item.localpath)
            }
        }
        
    }
    
    
    private let AVATAR_SIZE: CGFloat = 36
    private let ARROW_WIDTH: CGFloat = 44
    
    func setupViews() {
        self.contentView.backgroundColor = UIColor.white
        
        let imageview = UIImageView(frame: CGRect(x: 0, y: 0, width: AVATAR_SIZE, height: AVATAR_SIZE))
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
        
        let progress = UIProgressView(frame: CGRect.zero)
        self.contentView.addSubview(progress)
        self.progressView = progress
        
        var button = UIButton(type: .custom)
        button.setImage(YKImage("iconCellCancel"), for: .normal)
        button.contentMode = .center
        self.contentView.addSubview(button)
        self.cancelBtn = button
        self.cancelBtn.addTarget(self, action: #selector(onCancelBtn), for: .touchUpInside)
        
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
        self.errorBtn.addTarget(self, action: #selector(onErrorInfoBtn), for: .touchUpInside)
        
        label = UILabel(frame: CGRect.zero)
        label.textColor = YKAppearance.flSubtitleColor
        label.backgroundColor = self.contentView.backgroundColor
        label.textAlignment = .left
        label.font = YKFont.make(12)
        label.text = YKLocalizedString("等待上传")
        label.sizeToFit()
        self.contentView.addSubview(label)
        self.infoLabel = label
        
        
        let line = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1.0/UIScreen.main.scale))
        line.backgroundColor = YKColor.Separator
        line.isOpaque = true
        self.contentView.addSubview(line)
        self.sepline = line

    }
    
    func onCancelBtn() {
        celldelegate?.didClickCancelBtn(cell:self, uploadItem: self.uploadItem)
    }
    
    func onStopBtn() {
        celldelegate?.didClickStopBtn(cell:self, uploadItem: self.uploadItem)
    }
    
    func onErrorInfoBtn() {
        celldelegate?.didClickErrorBtn(cell:self, uploadItem: self.uploadItem)
    }
    
    func onRetryBtn() {
        celldelegate?.didClickRetryBtn(cell:self, uploadItem: self.uploadItem)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let sz = self.contentView.frame.size
        
        let avatarSize = YKAppearance.flAvatarSize
        var rect = CGRect(x: 15, y: (sz.height-avatarSize)/2, width: avatarSize, height: avatarSize)
        
        self.avatar.frame = rect
        
        let titleH = CGFloat(ceilf(Float(self.titleLabel.font.lineHeight)))
        let infotitleH = CGFloat(ceilf(Float(self.infoLabel.font.lineHeight)))

        let subLabelH: CGFloat = 20

        var tail: CGFloat = 15

        if !self.cancelBtn.isHidden {
            cancelBtn.frame = CGRect(x: sz.width-44, y: 0, width: 44, height: sz.height-1)
            tail = 44 + 10
        }
        
        
        if !self.retryBtn.isHidden {
            retryBtn.frame = CGRect(x: sz.width - tail - 44, y: 0, width: 44, height: sz.height-1)
            tail = (sz.width - retryBtn.frame.minX + 10)
        }
        
        if !self.stopBtn.isHidden {
            stopBtn.frame = CGRect(x: sz.width - tail - 44, y: 0, width: 44, height: sz.height-1)
            tail = (sz.width - stopBtn.frame.minX + 10)
        }
        

        let y = (sz.height - (titleH + subLabelH))/2
        rect.origin.y = y
        rect.origin.x = self.avatar.frame.maxX + 10
        rect.size = CGSize(width: sz.width-rect.origin.x-tail, height: titleH)
        self.titleLabel.frame = rect
        
        var infolabelX = titleLabel.frame.minX
        if !errorBtn.isHidden {
            rect.size = CGSize(width: 16, height: 16)
            rect.origin.x = self.titleLabel.frame.minX
            rect.origin.y = self.titleLabel.frame.maxY + (subLabelH - 16)/2
            errorBtn.frame = rect
            infolabelX = rect.maxX + 2
        }
        
        if !infoLabel.isHidden {
            infoLabel.frame = CGRect(x: infolabelX, y: titleLabel.frame.maxY + (subLabelH - infotitleH)/2, width: infoLabel.frame.size.width, height: infoLabel.frame.size.height)
        }
        
        if !progressView.isHidden {
            progressView.frame = CGRect(x: titleLabel.frame.minX, y: titleLabel.frame.maxY+(subLabelH-5)/2, width: titleLabel.frame.size.width, height: 5)

        
        self.sepline.frame = CGRect(x: titleLabel.frame.minX, y: sz.height-sepline.frame.size.height, width: sz.width - titleLabel.frame.minX, height: sepline.frame.size.height)
        }
    }
}
