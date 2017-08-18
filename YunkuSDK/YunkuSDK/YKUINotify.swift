//
//  YKUINotify.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/7.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation

public let YKNotification_UpdateEnts = "YKNotification_UpdateEnts"
public let YKNotification_UpdateMounts = "YKNotification_UpdateMounts"
public let YKNotification_UpdateShortcuts = "YKNotification_UpdateShortcuts"

class YKUINotify {
    
    enum YKUINotifyType : Int {
        case updateEnts = 1
        case updateMounts
        case updateShortcuts
    }
    
    class func notify(json: String, type: YKUINotifyType) {
        
        DispatchQueue.main.sync {
            let center = NotificationCenter.default
            switch type {
            case .updateEnts:
                center.post(name: NSNotification.Name(YKNotification_UpdateEnts), object: json, userInfo: nil)
            case .updateMounts:
                center.post(name: NSNotification.Name(YKNotification_UpdateMounts), object: json, userInfo: nil)
            case .updateShortcuts:
                center.post(name: NSNotification.Name(YKNotification_UpdateShortcuts), object: json, userInfo: nil)
            }
        }
    }
    
}
