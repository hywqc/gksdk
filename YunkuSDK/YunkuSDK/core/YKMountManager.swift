//
//  YKMountManager.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/8.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gknet

class YKMountManager {
    
    var mountItem: GKMountDataItem
    var syncDB: YKSyncDB?
    var bremoved = false
    
    init(mount: GKMountDataItem) {
        self.mountItem = mount
        var path = YKLoginManager.shareInstance.getMountFolder(mountID: mount.mount_id).gkRemoveLastSlash
        path = path.appending("/yksyncex.db")
        self.syncDB = YKSyncDB(path: path)
    }
    
    func stop() {
        
    }
    
    func getFiles(fullpath:String, type: YKFechType, updateDB: Bool, completion: (([GKFileDataItem],String?)->Void)? ) -> GKRequestID {
        
        let taskID = GKHttpEngine.default.fetchFileList(reget: false, mountID: mountItem.mount_id, fullpath: fullpath, dir: 0, hashs: nil, start: 0, size: 10000, dialog_id: nil, message_id: nil) { (retFiles:GKRequestRetFiles) in
            
            if retFiles.statuscode == 200 {
                if updateDB {
                    self.syncDB?.updateFiles(retFiles.files, fullpath)
                }
                if completion != nil {
                    completion!(retFiles.files,nil)
                }
            } else {
                if completion != nil {
                    completion!(retFiles.files,retFiles.errmsg)
                }
            }
        }
        
        return taskID
    }
    
}
