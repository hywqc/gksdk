//
//  YKEntManager.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/8.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gknet
import gkutility

let YKSHORTCUT_ENTID: Int = -1
let YKPERSONAL_ENTID: Int = 0

class YKEntManager {
    
    var ent: GKEntDataItem
    var subMounts = [YKMountManager]()
    var subShortItems = [GKShortcutItem]()
    
    var isFold = false
    
    var subCount: Int {
        if ent.ent_id == YKSHORTCUT_ENTID {
            return subShortItems.count
        } else {
            return subMounts.count;
        }
    }
    
    var isShortcut: Bool {
        return (ent.ent_id == YKSHORTCUT_ENTID)
    }
    
    var isPersonEnt: Bool {
        return (ent.ent_id == YKPERSONAL_ENTID)
    }
    
    var bremoved = false
    
    class func shortcutEntManager() -> YKEntManager {
        let e = GKEntDataItem()
        e.ent_id = YKSHORTCUT_ENTID
        e.ent_name = "置顶"
        return YKEntManager(ent: e)
    }
    
    class func personalEntManager() -> YKEntManager {
        let e = GKEntDataItem()
        e.ent_id = YKPERSONAL_ENTID
        e.ent_name = "个人库"
        return YKEntManager(ent: e)
    }
    
    init(ent: GKEntDataItem) {
        self.ent = ent
    }
    
    func updateWithMounts(_ mounts: [GKMountDataItem]) {
        
        var theMounts = [GKMountDataItem]()
        for mount in mounts {
            if mount.ent_id == ent.ent_id {
                theMounts.append(mount)
            }
        }
        
        for m in self.subMounts {
            m.bremoved = false
        }
        
        var result = [YKMountManager]()
        
        var exist: YKMountManager? = nil
        for mount in theMounts {
            exist = nil
            for manager in self.subMounts {
                if manager.mountItem.mount_id == mount.mount_id {
                    exist = manager
                    manager.bremoved = true
                    break
                }
            }
            
            if exist == nil {
                exist = YKMountManager(mount: mount)
            } else {
                exist!.mountItem = mount
            }
            result.append(exist!)
        }
        
        for manager in self.subMounts {
            if !manager.bremoved {
                manager.stop()
            }
        }
        
        if !result.isEmpty {
            result.sort { (item1:YKMountManager, item2:YKMountManager) -> Bool in
                if item1.mountItem.add_dateline <= item2.mountItem.add_dateline {
                    return true
                } else {
                    return false
                }
            }
        }
        
        self.subMounts = result

    }
    
    func updateWithShortcuts(_ shortcuts: [GKShortcutItem]) {
        
        self.subShortItems = shortcuts
        
    }
    
    func stop() {
        
    }
}
