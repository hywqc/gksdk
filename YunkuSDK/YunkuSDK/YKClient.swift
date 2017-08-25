//
//  YKClient.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/4.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import UIKit
import gkutility
import gknet

enum YKStatus : Int {
    case unlogin = 0
    case unloadData
    case ready
}

@objc public enum YKSDKLanguage : Int {
    case CH = 1
    case TW
    case EN
}

public final class YKClient : NSObject {
    
    public static let shareInstance = YKClient()
    
    var webHost: String = ""
    var https = false
    
    var status: YKStatus = .unlogin
    
    required public override init() {
        super.init()
        YKAppDelegate.shareInstance.setup()
    }
    
    private func getDeviceID() -> String {
        var devicePath = gkutility.docPath()
        devicePath.append("/gkdeviceid")
        var deviceid = ""
        if let s = try? String(contentsOfFile: devicePath, encoding: .utf8) {
            deviceid = s
        }
        if deviceid.isEmpty {
            deviceid = gkutility.createUUID()
            do {
                try deviceid.write(toFile: devicePath, atomically: true, encoding: .utf8)
            } catch  {
                
            }
        }
        return deviceid
    }
    
    public func config(client_id: String, client_secret: String, host: String? = nil, apiPort: String? = nil, webPort: String? = nil,https: Bool = false) {
        let webhost = (host ?? "yk3.gokuai.com")
        self.webHost = webhost
        self.https = https
        let deviceID = getDeviceID()
        GKHttpEngine.default.configServerInfo(https: https, apiHost: webhost, apiPort: apiPort, webHost: webhost, webPort: webPort, client_id: client_id, client_secret: client_secret, deviceID: deviceID) { (ret: GKRequestBaseRet) in 
            print(ret.errorLogInfo)
        }
        
        GKHttpEngine.default.refreshTokenNotifyCallback = { (accessToken:String, refreshToken:String,errcode: Int?, errmsg:String?) -> Void in
            DispatchQueue.global().async {
                if errcode != nil {
                    print("should force logout: \(errmsg ?? "")")
                    YKLoginManager.shareInstance.logout()
                    YKEventNotify.notify((errmsg ?? ""), type: .forceLogout)
                } else {
                    YKAppDelegate.shareInstance.settingDB.updateTokenInfo(accessToken, refreshToken)
                }
                
            }
        }
        
        print(YKLocalizedString("测试"))
    }
    
    public func setLan(_ language: Int) {
        if let new = YKSDKLanguage(rawValue: language) {
            let old = YKAppDelegate.shareInstance.laugnage
            YKAppDelegate.shareInstance.laugnage = new
            if old != new {
                YKAppDelegate.shareInstance.getAppLanguage()
            }
        }
    }
    
    public func getPeddingLoginRecord() -> [GKRequestAccountInfo] {
        return YKAppDelegate.shareInstance.settingDB.getall()
    }
    
    public func checkFastLogin() -> Bool {
        if YKAppDelegate.shareInstance.settingDB.checkLastLogin() > 0 {
            return true
        }
        return false
    }
    
    public func fastLogin(completion: ((Int,String)->Void)? ) {
        YKLoginManager.shareInstance.fastLogin(completion: completion)
    }
    
    public func login(account: String, password: String, completion: @escaping (Int,String)->Void )  {
        YKLoginManager.shareInstance.login(account: account, password: password, completion: completion)
    }
    
    
    public func getMessageViewController() -> UIViewController {
        
        return YKMessageMainViewController()
    }
    
    public func getMountListViewController() -> UIViewController {
        
        return YKMountListViewController(datasource: YKMountsDataTableSourceNormal())
    }
    
//    public func getSingleSelectMountListViewController() -> UIViewController {
//        
//        return YKMountListViewController.singleSelectMountListController()
//    }
//    
//    public func getMultiSelectMountListViewController() -> UIViewController {
//        
//        return YKMountListViewController.multiSelectMountListController()
//    }
    
    public func getContactViewController() -> UIViewController {
        
        return YKContactMainViewController()
    }
    
    public func getSettingViewController() -> UIViewController {

        return YKSettingViewController()
    }
    
    //0:没有 1:移动网络  2:wifi
    public func setNetStatus(_ status: Int) {
        switch status {
        case 0:
            YKNetMonitor.shareInstance.status = .Off
        case 1:
            YKNetMonitor.shareInstance.status = .WWAN
        default:
            YKNetMonitor.shareInstance.status = .Wifi
        }
    }
    
}
