//
//  YKAppearance.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/9.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit

class YKColor {
    
    static let BKG = RGBA(245, 245, 250)
    static let Title = Hex(0x222222)
    static let SubTitle = Hex(0x999999)
    static let Blue = Hex(0x00a0e9)
    static let Separator = Hex(0xd2d2d2)
    static let Disable = Hex(0x999999)
    
    
    class func Hex(_ hex: Int, _ alpha: CGFloat? = 1.0) -> UIColor {
        return UIColor(red: CGFloat((hex & 0xFF0000) >> 16)/255.0, green: CGFloat((hex & 0x00FF00) >> 8)/255.0, blue: CGFloat((hex & 0x0000FF))/255.0, alpha: (alpha ?? 1.0))
    }
    
    class func RGBA(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1.0) -> UIColor {
        return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
    }
    
}


class YKFont {
    
    static let Title = YKFont.make(17)
    static let SubTitle = YKFont.make(12)
    
    class func make(_ size: Int, _ weight: Int? = nil) -> UIFont {
        if weight != nil {
            return UIFont.systemFont(ofSize: CGFloat(size), weight: CGFloat(weight!))
        } else {
            return UIFont.systemFont(ofSize: CGFloat(size))
        }
    }
}




class YKAppearance {
    
   
    static let bkgColor = YKColor.BKG
    
    //MARK: 库列表
    static let mlAvatarSize: CGFloat = 40
    static let mlRowHeight: CGFloat = 64
    static let mlTitleFont = YKFont.make(16)
    static let mlSubtitleFont = YKFont.make(12)
    static let mlTitleColor = YKColor.Hex(0x3b4f61) // YKColor.Title
    static let mlSubtitleColor = YKColor.SubTitle
    static let mlAllowMultiLines = true
    static let mlShowSubtitle = true
    
    //MARK: 文件列表
    static let flAvatarSize: CGFloat = 36
    static let flRowHeight: CGFloat = 64
    static let flTitleFont = YKFont.make(15)
    static let flSubtitleFont = YKFont.make(12)
    static let flTitleColor = YKColor.Hex(0x3b4f61) // YKColor.Title
    static let flSubtitleColor = YKColor.SubTitle
    static let flAllowMultiLines = true
    static let flShowSubtitle = true
    static let flCachedColor = YKColor.Blue
    
}
