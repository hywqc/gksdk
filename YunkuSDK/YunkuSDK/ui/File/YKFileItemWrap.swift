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
    var downloadstatus: YKTransStatus = .None
    var downerrormsg: String?
    var progress: Float = 0.0
    
    var formatTitle = ""
    var formatSubTitle = ""
    
    var rowHeight: CGFloat = 0
    var titleSize: CGSize = CGSize.zero
    var subcontentSize: CGSize = CGSize.zero
    
    var showArrow = true
    
    var isCached = false
    
    var disableSelect: Bool {
        return selectType == .Disable
    }
    
    var showSelectIcon: Bool{
        return (selectType != .None && selectType != .Disable)
    }
    
    var showProgress: Bool {
        return (downloadstatus == .Normal || downloadstatus == .Start)
    }
    
    var showErrorInfo: Bool {
        return (downloadstatus == .Error)
    }
    
    var showSubTitle: Bool {
        switch downloadstatus {
        case .None,.Finish,.Stop,.Removed:
            return YKAppearance.flShowSubtitle
        case .Error,.Normal,.Start:
            return false
        }
    }
    
    var showCancelBtn: Bool {
        return (downloadstatus == .Normal || downloadstatus == .Start || downloadstatus == .Error)
    }
    
    var showAccessoryBtn = false
    
    var selectType: YKSelectIconType = .None
    
    var cellid: String {
        let isimage = (YKCommon.isSupportImage(file.filename) ? 1 : 0)
        var download = 0
        switch downloadstatus {
        case .Normal,.Start,.Error:
            download = 1
        default:
            break
        }
        return "filenormalcell\(isimage)-\(download)"
    }
    
    init(file: GKFileDataItem, showArrow: Bool = true, selectType: YKSelectIconType = .None, downloadStatus: YKTransStatus = .None, progress: Float = 0, errorInfo: String = "", showAccessoryBtn: Bool = false) {
        self.file = file
        self.showArrow = showArrow
        self.downloadstatus = downloadStatus
        self.selectType = selectType
        self.progress = progress
        self.downerrormsg = errorInfo
        self.showAccessoryBtn = showAccessoryBtn
        self.calc()
    }
    
    private func calc() {
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
