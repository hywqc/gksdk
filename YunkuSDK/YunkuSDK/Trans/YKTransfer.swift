//
//  YKTransCallback.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/22.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation

class YKTransfer {
    
    static let shanreInstance = YKTransfer()
    
    var transDB: YKTransDB?
    
    var uploadManager: YKUploadManager!
    
    private func getTransDBPath() -> String {
        var path = YKLoginManager.shareInstance.getUserFolder().gkAddLastSlash
        path.append("yktrans.db")
        return path
    }
    
    private init() {
        
    }
    
    func start() {
        transDB = YKTransDB(path: self.getTransDBPath())
        transDB?.resetForSimulate(transCahePath: YKLoginManager.shareInstance.getTransCacheFolder())
        transDB?.resetUploads()
        uploadManager = YKUploadManager()
    }
    
    func exit() {
        uploadManager.exit()
        if transDB != nil {
            transDB!.close()
        }
    }
    
    
}
