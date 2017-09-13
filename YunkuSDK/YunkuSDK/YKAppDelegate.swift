//
//  YKAppDelegate.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/4.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gkutility

fileprivate let LANGUAGE_PACK_EN  =  "en"
fileprivate let LANGUAGE_PACK_CH  =  "zh-Hans"
fileprivate let LANGUAGE_PACK_TW  =  "zh-Hant-TW"




@inline(__always) func YKFileIcon(_ filename: String, _ dir: Bool = false) -> UIImage? {
    let name = gkutility.getIconWithFileName(filename, dir)
    return YKImage(name, nil, "fileicons")
}


class YKAppDelegate {
    
    var bNetLink = true
    var laugnage: YKSDKLanguage = .EN
    var sdkBundle: Bundle?
    var languageBundle: Bundle?
    var resourceBundle: Bundle?
    
    var settingDB: YKSettingDB!
    
    public static let shareInstance = YKAppDelegate()
    
    private init() {
        var path = gkutility.docPath(groupID: YKClient.shareInstance.appGroupID).gkAddLastSlash
        path.append("yksetting.db")
        self.settingDB = YKSettingDB(path: path)
    }
    
    func setup() {
        
        let logpath = gkutility.docPath().gkAddLastSlash + "gklog.log"
        YKLog.shanreLog.setpath(logpath)
        
        
        if let frameworkpath = Bundle.main.privateFrameworksPath {
            let path = frameworkpath.gkRemoveLastSlash.appending("/YunkuSDK.framework")
            self.sdkBundle = Bundle(path: path)
            
            if var resourcePath = self.sdkBundle?.resourcePath {
                resourcePath = resourcePath.gkRemoveLastSlash
                resourcePath = resourcePath.appending("/YKResource.bundle")
                self.resourceBundle = Bundle(path: resourcePath)
            }
            self.getAppLanguage()
        }
        
        self.configlog()
    }
    
    private func configlog() {
        
    }
    
    func getAppLanguage() {
        
        var lprojName = ""
        switch self.laugnage {
        case .CH:
            lprojName = LANGUAGE_PACK_CH
        case .TW:
            lprojName = LANGUAGE_PACK_TW
        case .EN:
            lprojName = LANGUAGE_PACK_EN
        }
        
        if resourceBundle != nil {
            if let path = sdkBundle?.path(forResource: lprojName, ofType: "lproj") {
                self.languageBundle = Bundle(path: path)
            }
        }
    }
    
}
