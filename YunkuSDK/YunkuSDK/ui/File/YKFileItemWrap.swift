//
//  YKFileItemData.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/14.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gknet
import gkutility


class YKFileItemCellWrap {
    
    var file: GKFileDataItem!
    
    var downloadItem: YKDownloadItemData? {

        didSet {
            self.calc()
        }
    }
    
    var formatTitle = ""
    var formatSubTitle = ""
    
    var rowHeight: CGFloat = 0
    var titleSize: CGSize = CGSize.zero
    var subcontentSize: CGSize = CGSize.zero
    
    
    
    var isCached = false
    
    var fold = true
    
    var disableSelect: Bool {
        return selectType == .Disable
    }
    
    var showArrow = true
    
    var showSelectIcon: Bool{
        return (selectType != .None && selectType != .Disable)
    }
    
    var showProgress: Bool {
        if downloadItem != nil {
            switch downloadItem!.status {
            case .Normal,.Stop,.Start:
                return true
            default:
                break
            }
        }
        return false
    }
    
    var showErrorInfo: Bool {
        if downloadItem != nil {
            if downloadItem!.status == .Error {
                return true
            }
        }
        return false
    }
    
    var showSubTitle: Bool {
        if downloadItem == nil {
            return true
        }
        switch downloadItem!.status {
        case .None,.Finish,.Removed:
            return YKAppearance.flShowSubtitle
        case .Error,.Normal,.Start,.Stop:
            return false
        }
    }
    
    var showCancelBtn: Bool {
        if downloadItem != nil {
            switch downloadItem!.status {
            case .Normal,.Start,.Error,.Stop:
                return true
            default:
                break
            }
        }
        return false
    }
    
    var showRetryBtn: Bool {
        if downloadItem != nil {
            switch downloadItem!.status {
            case .Error,.Stop:
                return true
            default:
                break
            }
        }
        return false
    }
    
    var showStopBtn: Bool {
        if downloadItem != nil {
            switch downloadItem!.status {
            case .Start:
                return true
            default:
                break
            }
        }
        return false
    }
    
    var showAccessoryBtn = false
    
    var selectType: YKSelectIconType = .None
    
    var cellid: String {
        let isimage = (YKCommon.isSupportImage(file.filename) ? 1 : 0)
        var download = 0
        if downloadItem != nil {
            switch downloadItem!.status {
            case .Normal,.Start,.Error,.Stop:
                download = 1
            default:
                break
            }
        }
        
        return "filenormalcell\(isimage)-\(download)"
    }
    
    init(file: GKFileDataItem, showArrow: Bool = true, selectType: YKSelectIconType = .None, showAccessoryBtn: Bool = false, downloadItem: YKDownloadItemData? = nil) {
        self.file = file
        self.showArrow = showArrow
        self.selectType = selectType
        self.showAccessoryBtn = showAccessoryBtn
        self.downloadItem = downloadItem
        self.calc()
    }
    
    func calc() {
        
        if downloadItem != nil {
            switch downloadItem!.status {
            case .Start,.Normal,.Error,.Stop:
                self.showArrow = false
            default:
                break
            }
        }
        
        self.isCached = (YKCacheManager.shareManager.checkCache(key: file.filehash, type: nil) != nil)
        
        self.formatTitle = file.filename
        
        var maxTitleWidth = UIScreen.main.bounds.size.width - 15
        
        if selectType != .None  {
            maxTitleWidth -= (20 + 10)
        }
        
        maxTitleWidth -= (YKAppearance.flAvatarSize + 10)
        
        if self.showArrow {
            let arrowSize: CGFloat = 44
            maxTitleWidth -= (arrowSize + 10)
        } else if self.showCancelBtn {
            let cancelBtnSize: CGFloat = 44
            maxTitleWidth -= (cancelBtnSize + 10)
        } else if self.showAccessoryBtn {
            maxTitleWidth -= (44 + 10)
        } else {
            maxTitleWidth -= 15
        }
        
        if self.showRetryBtn || self.showStopBtn {
            maxTitleWidth -= (44 + 10)
        }

        if self.showSubTitle {
            let time = gkutility.formatDateline(TimeInterval(file.last_dateline), format: GKTimeFormatYMDHM)
            let size = gkutility.formatSize(size: file.filesize, precision: 1, compact: false)
            
            if file.dir {
                self.formatSubTitle = "\(file.last_member_name) \(time)"
            } else {
                self.formatSubTitle = "\(file.last_member_name) \(time) \(size)"
            }
        }
        
        var font = YKAppearance.flTitleFont
        var titleH: CGFloat = 0
        
        let marginV: CGFloat = 10
        
        if YKAppearance.flAllowMultiLines {
            titleH = CGFloat(ceilf(Float(formatTitle.gkSize(maxWidth: maxTitleWidth, font: font).height)))
        } else {
            titleH = CGFloat(ceilf(Float(font.lineHeight)))
        }
        
        titleSize = CGSize(width: maxTitleWidth, height: titleH)
        
        var subtitleH: CGFloat = 0
        if showSubTitle {
            font = YKAppearance.flSubtitleFont
            subtitleH = CGFloat(ceilf(Float(font.lineHeight)))
        } else if self.showProgress {
            subtitleH = 20
        } else if self.showErrorInfo {
            subtitleH = 20
        }
        
        subcontentSize = CGSize(width: maxTitleWidth, height: subtitleH)
        
        let avatarH = YKAppearance.flAvatarSize

        
        var rawH = max(avatarH, titleH + subtitleH)
        rawH += (marginV*2)
        
        self.rowHeight = rawH
        
    }
}
