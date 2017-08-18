//
//  YKNetMonitor.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/15.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation

let YKNetChangeNotificationName = "YKNetChangeNotificationName"

@inline(__always) func netWifi() -> Bool {
    return YKNetMonitor.shareInstance.status == .Wifi
}

@inline(__always) func netWWAN() -> Bool {
    return YKNetMonitor.shareInstance.status == .WWAN
}

@inline(__always) func netOff() -> Bool {
    return YKNetMonitor.shareInstance.status == .Off
}

final class YKNetMonitor {
    
    enum Status {
        case Off
        case Wifi
        case WWAN
    }
    
    static let shareInstance = YKNetMonitor()
    
    private init(){
        
    }
    
    func start() {
        
    }
    
    
    var status: Status = .Wifi {
        
        didSet {
            if oldValue == status {
                return
            }
            
            if Thread.isMainThread {
                
            }
            
            YKSafePostNotification(YKNetChangeNotificationName,(oldValue,status),nil)
            
        }
    }
    
}
