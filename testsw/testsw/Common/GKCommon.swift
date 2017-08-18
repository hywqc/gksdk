//
//  GKCommon.swift
//  testsw
//
//  Created by wqc on 2017/8/8.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit

func GKLocalizedString(_ key: String, _ value: String? = nil) -> String {
    return Bundle.main.localizedString(forKey: key, value: value, table: nil)
}

@inline(__always) func GKImage(_ name: String) -> UIImage? {
    return UIImage(named: name)
}

func GKFont(_ size: Int, _ weight: Int? = nil) -> UIFont {
    if weight != nil {
        return UIFont.systemFont(ofSize: CGFloat(size), weight: CGFloat(weight!))
    } else {
        return UIFont.systemFont(ofSize: CGFloat(size))
    }
    
}
