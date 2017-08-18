//
//  YKLoginManager.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/4.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gkutility
import gknet


final class YKLoginManager {
    
    static let shareInstance = YKLoginManager()
    
    var userInfo: GKRequestAccountInfo?
    
    required init() {
        
    }
    
    func checkHaveLogin() -> Bool {
        let userid = YKAppDelegate.shareInstance.settingDB.checkLastLogin()
        if userid > 0 {
            return true
        }
        return false
    }
    
    func fastLogin(completion: ((Int,String)->Void)?) {
        
        DispatchQueue.global().async {
            let userid = YKAppDelegate.shareInstance.settingDB.checkLastLogin()
            if userid > 0 {
                let tokens = YKAppDelegate.shareInstance.settingDB.getTokenInfo(userid)
                if !tokens.accesstoken.isEmpty && !tokens.refreshtoken.isEmpty {
                    if let acc = YKAppDelegate.shareInstance.settingDB.getAccount(userid) {
                        GKHttpEngine.default.setToken(tokens.accesstoken, tokens.refreshtoken)
                        
                        self.userInfo = acc
                        YKClient.shareInstance.status = .unloadData
                        DispatchQueue.main.async {
                            completion?(YKErrorCode_OK,"")
                        }
                        YKMountCenter.shareInstance.start()
                        YKAppDelegate.shareInstance.settingDB.updateDateline(userid)
                        self.updateUserInfo()
                        return
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion?(YKErrorCode_UnLogin,"登录失败")
            }
        }
        
    }
    
    func login(account: String, password: String, completion: @escaping (Int,String)->Void )  {
        DispatchQueue.global().async {
            
            
            let tokenRet = GKHttpEngine.default.login(account: account, password: password)
            if tokenRet.statuscode == 200 {
                
                let accountRet = GKHttpEngine.default.fetchAccountInfo()
                if accountRet.statuscode == 200 {
                    
                    YKAppDelegate.shareInstance.settingDB.addAccount(token: tokenRet.accessToken, refreshtoken: tokenRet.refreshToken, accountRet)
                    
                    self.userInfo = accountRet
                    YKClient.shareInstance.status = .unloadData
                    DispatchQueue.main.async {
                        completion(YKErrorCode_OK,"")
                    }
                    YKMountCenter.shareInstance.start()
                } else {
                    DispatchQueue.main.async {
                        completion(accountRet.errcode,accountRet.errmsg)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(tokenRet.errcode,tokenRet.errmsg)
                }
            }
        }
    }
    
    func exchangeLogin(json: String, completion: @escaping (Int,String)->Void) {
        
    }
    
    func ssoLogin(json: String, completion: @escaping (Int,String)->Void) {
        
    }
    
    
    
    func updateUserInfo() {
        DispatchQueue.global().async {
            let accountRet = GKHttpEngine.default.fetchAccountInfo()
            if accountRet.statuscode == 200 {
                
                YKAppDelegate.shareInstance.settingDB.updateAccountInfo(accountRet)
                self.userInfo = accountRet
            }
        }
    }
    
    func logout() {
        self.userInfo = nil
    }
    
    func getUserFolder() -> String {
        var userpath = gkutility.docPath().gkAddLastSlash
        if let userid = YKLoginManager.shareInstance.userInfo?.member_id {
            userpath = userpath.appendingFormat("%ld", userid)
            let _ = gkutility.createDir(path: userpath)
            return userpath
        }
        return ""
    }
    
    func getMountFolder(mountID: Int) -> String {
        var path = self.getUserFolder().gkAddLastSlash
        path = path.appendingFormat("%ld", mountID)
        let _ = gkutility.createDir(path: path)
        return path
    }
    
    func getCacheFolder() -> String {
        var path = self.getUserFolder().gkAddLastSlash
        path.append("cache")
        let _ = gkutility.createDir(path: path)
        return path
    }
    
    func getTransFolder() -> String {
        var path = self.getUserFolder().gkAddLastSlash
        path.append("trans")
        let _ = gkutility.createDir(path: path)
        return path
    }
    
    func getFavName(favID: Int) -> String {
        if let info = self.userInfo {
            for magic in info.favorites {
                if magic.favid == favID {
                    return magic.name
                }
            }
        }
        return ""
    }
    
    
}
