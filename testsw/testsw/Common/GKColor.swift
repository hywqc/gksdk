//
//  GKColor.swift
//  testsw
//
//  Created by wqc on 2017/8/8.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit

class GKColor {
    
    static let BKG = RGBA(245, 245, 250)
    static let Title = Hex(0x222222)
    static let SubTitle = Hex(0x999999)
    static let Blue = Hex(0x00a0e9)
    static let Separator = Hex(0xd2d2d2)
    
    
    class func Hex(_ hex: Int, _ alpha: CGFloat? = 1.0) -> UIColor {
        return UIColor(red: CGFloat((hex & 0xFF0000) >> 16)/255.0, green: CGFloat((hex & 0x00FF00) >> 8)/255.0, blue: CGFloat((hex & 0x0000FF))/255.0, alpha: (alpha ?? 1.0))
    }
    
    class func RGBA(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1.0) -> UIColor {
        return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
    }
    
}
