//
//  YKMountItemWrap.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/15.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit
import gknet
import gkutility

final class YKMountItemCellWrap {
    
    var mountItem: GKMountDataItem?
    var rowHeight: CGFloat = 0
    
    var titleLines = 1
    var titleHeight: CGFloat = 0
    var subtitleHeight: CGFloat = 0
    
    var formatTitle = ""
    var formatSubtitle = ""
    
    var favid: Int?
    
    var selectType: YKSelectIconType = .None
    
    init(mount:GKMountDataItem, selectType: YKSelectIconType = .None) {
        self.selectType = selectType
        mountItem = mount
        calc()
    }
    
    init(favid: Int, selectType: YKSelectIconType = .None) {
        self.selectType = selectType
        self.favid = favid
        calc()
    }
    
    private func calc() {
        
         var showSubTitle = YKAppearance.mlShowSubtitle
        
        if favid != nil {
            
            formatTitle = YKLoginManager.shareInstance.getFavName(favID: favid!)
            showSubTitle = false
            
        } else if mountItem != nil {
            
            formatTitle = mountItem!.org_name
            if formatTitle.contains("hywqc") {
                formatTitle = "hywqc sdfjhg fgjhjf是多少的金凤凰案件的方法💰 2334 官方覆盖 8778";
            }
            formatSubtitle = "\(gkutility.formatSize(size: mountItem!.size_org_use)) \(mountItem!.member_count)" +  YKLocalizedString("个成员")
        }
        
        var font = YKAppearance.mlTitleFont
        var titleH: CGFloat = 0
        
        let marginV: CGFloat = 10
        
        if YKAppearance.mlAllowMultiLines {
            let marginH: CGFloat = 15
            let selectIconSize: CGFloat = ((selectType != .None) ? (20 + 10) : 0)
            let maxW = UIScreen.main.bounds.size.width - marginH - selectIconSize - YKAppearance.mlAvatarSize - 10 - marginH
            titleH = CGFloat(ceilf(Float(formatTitle.gkSize(maxWidth: maxW, font: font).height)))
            if titleH > (YKAppearance.mlTitleFont.lineHeight + 1) {
                titleLines = 0
            }
        } else {
            titleH = CGFloat(ceilf(Float(font.lineHeight)))
        }
        
        var subtitleH: CGFloat = 0
        if showSubTitle {
            font = YKAppearance.mlSubtitleFont
            subtitleH = CGFloat(ceilf(Float(font.lineHeight)))
        }
        
        let avatarH = YKAppearance.mlAvatarSize
        
        titleHeight = titleH
        subtitleHeight = subtitleH
        
        var rawH = max(avatarH, titleH + subtitleH)
        rawH += (marginV*2)
        
        self.rowHeight = rawH
        
    }
    
}
