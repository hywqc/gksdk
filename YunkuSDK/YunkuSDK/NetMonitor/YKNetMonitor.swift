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
    
    var reachability: Reachability?
    
    private init(){
        self.reachability = Reachability()
    }
    
    func start() {
        
        if self.reachability == nil {
            self.reachability = Reachability()
        }
        
        if self.reachability == nil {
            return
        }
        
        self.reachability!.whenReachable = { reach in
            DispatchQueue.main.async {
                if reach.isReachableViaWiFi {
                    self.status = .Wifi
                } else if reach.isReachableViaWWAN {
                    self.status = .WWAN
                }
            }
        }
        
        self.reachability!.whenUnreachable = { reach in
            DispatchQueue.main.async {
                self.status = .Off
            }
        }
        
        do {
            try self.reachability!.startNotifier()
        } catch  {
            print("Unable to start notifier")
        }
    }
    
    func stop() {
        self.reachability?.stopNotifier()
    }
    
    
    var status: Status = .Wifi {
        
        didSet {
            if oldValue == status {
                return
            }
            
            YKSafePostNotification(YKNetChangeNotificationName,(oldValue,status),nil)
            
        }
    }
    
}
