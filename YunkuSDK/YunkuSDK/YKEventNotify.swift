//
//  YKUINotify.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/7.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation

public let YKNotification_ForceLogout = "YKNotification_ForceLogout"
public let YKNotification_UpdateEnts = "YKNotification_UpdateEnts"
public let YKNotification_UpdateMounts = "YKNotification_UpdateMounts"
public let YKNotification_UpdateShortcuts = "YKNotification_UpdateShortcuts"
public let YKNotification_UploadFile = "YKNotification_UploadFile"
public let YKNotification_DownloadFile = "YKNotification_DownloadFile"

class YKEventNotify {
    
    enum EventType : Int {
        case forceLogout = 1
        case updateEnts
        case updateMounts
        case updateShortcuts
        case uploadFile
        case downloadFile
    }
    
    class func notify(_ param: Any?, type: EventType) {
        
        DispatchQueue.main.async {
            let center = NotificationCenter.default
            var postname = ""
            var json = ""
            switch type {
            case .forceLogout:
                postname = YKNotification_ForceLogout
                if param is String {
                    json = (param as! String)
                }
            case .updateEnts:
                postname = YKNotification_UpdateEnts
            case .updateMounts:
                postname = YKNotification_UpdateMounts
            case .updateShortcuts:
                postname = YKNotification_UpdateShortcuts
            case .uploadFile:
                postname = YKNotification_UploadFile
                if param is YKUploadItemData {
                    json = (param as! YKUploadItemData).notifyInfo
                }
            case .downloadFile:
                postname = YKNotification_DownloadFile
                if param is YKDownloadItemData {
                    json = (param as! YKDownloadItemData).notifyInfo
                }
            }
            
            center.post(name: NSNotification.Name(postname), object: json, userInfo: nil)

        }
    }
    
}
