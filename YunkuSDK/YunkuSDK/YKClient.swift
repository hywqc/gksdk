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


@objc public enum YKSDKLanguage : Int {
    case CH = 1
    case TW
    case EN
}

public final class YKClient : NSObject {
    
    public static let shareInstance = YKClient()
    
    public enum ExtensionType : Int {
        case None = 0
        case Share
        case Action
        case Document
        case iCloud
    }
    
    var isLogined = false
    var appGroupID: String?
    var extensionType: ExtensionType = .None
    var serverInfo = GKServerInfo()
    
    required public override init() {
        super.init()
        
    }
    
    private func getDeviceID() -> String {
        var devicePath = gkutility.docPath(groupID: appGroupID)
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
    
    public func config(host: String,client_id: String, client_secret: String,https: Bool,groupID: String? = nil,extensionType: ExtensionType = .None) {
        self.config(https: https, client_id: client_id, client_secret: client_secret, webHost: host, apiHost: nil, webPort: nil, webHttpsPort: nil, apiPort: nil, apiHttpsPort: nil, groupID: groupID, extensionType: extensionType)
    }
    
    public func config(https: Bool,client_id: String, client_secret: String, webHost: String, apiHost: String?, webPort: String? = nil,webHttpsPort: String? = nil,apiPort: String? = nil,apiHttpsPort: String? = nil, groupID: String? = nil,extensionType: ExtensionType = .None) {
        
        serverInfo.https = https
        serverInfo.clientID = client_id
        serverInfo.clientSecret = client_secret
        serverInfo.webHost = webHost
        serverInfo.apiHost = (apiHost ?? webHost)
        serverInfo.webPort = webPort
        serverInfo.apiPort = apiPort
        serverInfo.webHttpsPort = webHttpsPort
        serverInfo.apiHttpsPort = apiHttpsPort
        
        self.appGroupID = groupID
        self.extensionType = extensionType
        
        YKAppDelegate.shareInstance.setup()
        
        let deviceID = getDeviceID()
        GKHttpEngine.default.configServerInfo(serverInfo, deviceID: deviceID) { (ret: GKRequestBaseRet) in
            print(ret.errorLogInfo)
            YKLog.shanreLog.log(msg: ret.errorLogInfo)
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
    
    public func showSaveSelect(url:URL, fromVC: UIViewController) {
        let localpath = url.path
        let filename = localpath.gkFileName
        YKSelectFileComponent.showOutSaveSelect(localFiles: [localpath:filename], fromVC: fromVC)
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

public extension YKClient {
    
    public func checkHaveLoginInfo() -> Bool {
        
        return false
    }
    
    public func getShareExtensionViewController(title: String, extensionContext: NSExtensionContext) -> UIViewController {
        
        let vc = YKShareExtensionController(title: title, extensionContext: extensionContext)
        return vc
    }
    
}
