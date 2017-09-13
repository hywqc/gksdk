//
//  YKMountCenter.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/4.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gkutility
import gknet


final class YKMountCenter {
    
    static let shareInstance = YKMountCenter()
    
    var lock: gklock?
    var bStop = false
    private var mountsDB: YKMountsDB?
    
    
    var entManagers = [YKEntManager]()
    
    var isReseting = false
    var status = (errcode:200,errmsg:"")
    
    
    required init() {
        
    }
    
    private func getMountsDBPath() -> String {
        var path = YKLoginManager.shareInstance.getUserFolder().gkAddLastSlash
        path.append("ykmounts.db")
        return path
    }
    
    func stop() {
        bStop = true
    }

    
    func reload(type: YKFechType, updateDB: Bool , notifyUI:Bool,reason: String? = nil) {
        if self.isReseting {
            return
        }
        
        self.isReseting = true
        
        DispatchQueue.global().async {
            
            if updateDB {
                if self.mountsDB == nil {
                    self.mountsDB = YKMountsDB(path: self.getMountsDBPath())
                }
            }
            
            if type == .OnlyLocal || type == .Both {
                if self.mountsDB == nil {
                    self.isReseting = false
                    return
                }
                self.loadEnts(source: self.mountsDB!.getEnts())
                self.loadMounts(source: self.mountsDB!.getMounts())
                self.loadShortcuts(source: self.mountsDB!.getShortcuts())
                if notifyUI {
                    YKEventNotify.notify(nil, type: .updateEnts)
                }
                if type == .OnlyLocal {
                    self.isReseting = false
                    return
                }
            }
            
            if updateDB {
                if self.mountsDB != nil {
                    var ret = self.resetEnt()
                    if ret.errcode == 200 {
                        ret = self.resetMount()
                        if ret.errcode == 200 {
                            let _ = self.resetShortcuts()
                        }
                    }
                    
                    if ret.errcode == GKOperationExitCode {
                        self.isReseting = false
                        return
                    }
                    
                    self.status = ret
                    self.loadEnts(source: self.mountsDB!.getEnts())
                    self.loadMounts(source: self.mountsDB!.getMounts())
                    self.loadShortcuts(source: self.mountsDB!.getShortcuts())
                }
                
            } else {
                let retEnts = GKHttpEngine.default.fetchEnts()
                if retEnts.statuscode != 200 {
                    self.status = (retEnts.errcode,retEnts.errmsg)
                    if notifyUI {
                        YKEventNotify.notify(nil, type: .updateEnts)
                    }
                    self.isReseting = false
                    return
                }
                
                if self.bStop {
                    self.isReseting = false
                    return
                }
                
                let retMounts = GKHttpEngine.default.fetchMounts(org_id: nil)
                if retMounts.statuscode != 200 {
                    self.status = (retEnts.errcode,retEnts.errmsg)
                    if notifyUI {
                        YKEventNotify.notify(nil, type: .updateEnts)
                    }
                    self.isReseting = false
                    return
                }
                
                if self.bStop {
                    self.isReseting = false
                    return
                }
                
                self.status = (200,"")
                self.loadEnts(source: retEnts.ents)
                self.loadMounts(source: retMounts.mounts)
            }
            
            if notifyUI {
                YKEventNotify.notify(nil, type: .updateEnts)
            }
            
            self.isReseting = false
            print("reload mounts finish")
        }
    }
    
    

    func resetEnt() -> (errcode:Int,errmsg:String) {
        
        if mountsDB == nil{
            return (1,"mount db open error: \(self.getMountsDBPath())")
        }
        
        let retEnts = GKHttpEngine.default.fetchEnts()
        if retEnts.statuscode != 200 {
            return (retEnts.errcode,retEnts.errmsg)
        }
        
        if self.bStop {
            return (GKOperationExitCode,"")
        }
        
        let localEnts = mountsDB!.getEnts()
        
        var noRemoves = [Int]()
        
        var bChanged = false
        
        if self.bStop {
            return (GKOperationExitCode,"")
        }
        
        for item in retEnts.ents {
            var bhave = false
            for l in localEnts {
                if item.ent_id == l.ent_id {
                    bhave = true
                    noRemoves.append(l.ent_id)
                    if !bChanged && item.rawJson != l.rawJson {
                        bChanged = true
                    }
                    break
                }
            }
            
            if !bhave {
                bChanged = true
            }
            
            mountsDB?.addEnt(ent: item)
        }
        
        for item in localEnts {
            if !noRemoves.contains(item.ent_id) {
                bChanged = true
                mountsDB?.deleteEnt(entID: item.ent_id)
            }
        }
        
        if self.bStop {
            return (GKOperationExitCode,"")
        }
        
        if bChanged {
            YKEventNotify.notify(nil, type: .updateEnts)
        }
        
        return (200,"")
    }
    
    func resetMount() -> (errcode:Int,errmsg:String) {
        if mountsDB == nil{
            return (1,"mount db open error: \(self.getMountsDBPath())")
        }
        
        let retMounts = GKHttpEngine.default.fetchMounts(org_id: nil)
        if retMounts.statuscode != 200 {
            return (retMounts.errcode,retMounts.errmsg)
        }
        
        if self.bStop {
            return (GKOperationExitCode,"")
        }
        
        let localMounts = mountsDB!.getMounts()
        
        var noRemoves = [Int]()
        
        var bChanged = false
        
        for item in retMounts.mounts {
            var bhave = false
            for l in localMounts {
                if item.mount_id == l.mount_id {
                    bhave = true
                    noRemoves.append(l.mount_id)
                    if !bChanged && item.rawJson != l.rawJson {
                        bChanged = true
                    }
                    break
                }
            }
            
            if self.bStop {
                return (GKOperationExitCode,"")
            }
            
            if !bhave {
                bChanged = true
            }
            
            mountsDB?.addMount(item)
        }
        
        for item in localMounts {
            if !noRemoves.contains(item.mount_id) {
                bChanged = true
                mountsDB?.deleteMount(id: item.mount_id)
            }
        }
        
        if bChanged {
            YKEventNotify.notify(nil, type: .updateMounts)
        }
        
        return (200,"")
    }
    
    func resetShortcuts() -> (errcode:Int,errmsg:String) {
        
        if !YKCustomConfig.showShortcut {
            return (200,"")
        }
        
        if mountsDB == nil{
            return (1,"mount db open error: \(self.getMountsDBPath())")
        }
        
        let retShortcuts = GKHttpEngine.default.fetchShortcuts()
        if retShortcuts.statuscode != 200 {
            return (retShortcuts.errcode,retShortcuts.errmsg)
        }
        
        if self.bStop {
            return (GKOperationExitCode,"")
        }
        
        let localShortcuts = mountsDB!.getShortcuts()
        
        var bChanged = false
        
        for item in retShortcuts.shortcuts {
            var bhave = false
            for l in localShortcuts {
                if item.type == l.type && item.value == l.value {
                    bhave = true
                    l.bremoved = true
                    break
                }
            }
            
            if !bhave {
                bChanged = true
            }
            
            if self.bStop {
                return (GKOperationExitCode,"")
            }
            
            mountsDB?.addShortcut(item)
        }
        
        for item in localShortcuts {
            if !item.bremoved {
                bChanged = true
                mountsDB?.deleteShortcut(item)
            }
        }
        
        if bChanged {
            YKEventNotify.notify(nil, type: .updateShortcuts)
        }
        
        return (200,"")
    }
    
    func loadEnts(source:[GKEntDataItem]) {
        
        var result = [YKEntManager]()
        
        for em in self.entManagers {
            
            if em.isShortcut || em.isPersonEnt{
                em.bremoved = true
                continue
            }
            em.bremoved = false
        }
        
        var exist: YKEntManager? = nil
        for item in source {
            exist = nil
            for em in self.entManagers {
                if em.ent.ent_id == item.ent_id {
                    exist = em
                    em.bremoved = true
                    break
                }
            }
            
            if exist == nil {
                exist = YKEntManager(ent: item)
            } else {
                exist!.ent = item
            }
            result.append(exist!)
        }
        
        
        for item in self.entManagers {
            if !item.bremoved {
                item.stop()
            }
        }
        
        result.sort(by: { (item1:YKEntManager, item2:YKEntManager) -> Bool in
            if item1.ent.add_dateline <= item2.ent.add_dateline {
                return true
            } else {
                return false
            }
        })
        
        var personem: YKEntManager?
        var shortem: YKEntManager?
        for em in entManagers {
            if em.ent.ent_id == YKPERSONAL_ENTID {
                personem = em
            }
            if em.isShortcut {
                shortem = em
            }
        }
        
        if personem == nil {
            personem = YKEntManager.personalEntManager()
        }
        
        result.insert(personem!, at: 0)
        
        if YKCustomConfig.showShortcut {
            if shortem == nil { shortem = YKEntManager.shortcutEntManager() }
            result.insert(shortem!, at: 0)
        }
        
        self.entManagers = result
        
    }
    
    func loadMounts(source:[GKMountDataItem]) {
        
        for em in self.entManagers {
            if em.ent.ent_id == YKSHORTCUT_ENTID {
                continue
            }
            em.updateWithMounts(source)
            if self.bStop {
                return
            }
        }
    }
    
    func loadShortcuts(source:[GKShortcutItem]) {
        if !YKCustomConfig.showShortcut {
            return
        }
        for em in self.entManagers {
            if em.ent.ent_id == YKSHORTCUT_ENTID {
                em.updateWithShortcuts(source)
                break
            }
        }
    }
    
    func entManagerBy(entID: Int) -> YKEntManager? {
        for em in self.entManagers {
            if em.ent.ent_id == entID {
                return em
            }
        }
        return nil
    }
    
    func mountItemBy(mountID: Int) -> GKMountDataItem? {
        for em in self.entManagers {
            if !em.isShortcut {
                for m in em.subMounts {
                    if m.mountItem.mount_id == mountID {
                        return m.mountItem
                    }
                }
            }
        }
        return nil
    }
    
    func mountManagerBy(mountID: Int) -> YKMountManager? {
        for em in self.entManagers {
            if !em.isShortcut {
                for m in em.subMounts {
                    if m.mountItem.mount_id == mountID {
                        return m
                    }
                }
            }
        }
        return nil
    }
    
    func getShortcutName(_ shortcut: GKShortcutItem) -> String {
        switch shortcut.type {
        case .Mount:
            let mountid = shortcut.value
            if let mount = self.mountItemBy(mountID: mountid) {
                return mount.org_name
            } else {
                return ""
            }
        case .Smart:
            let favid = shortcut.value
            return YKLoginManager.shareInstance.getFavName(favID: favid)
            
        default:
            return ""
        }
    }
    
}


private let MagicID_Star  =     1
private let MagicID_Moon  =     2
private let MagicID_Heart =     3
private let MagicID_Class =     4
private let MagicID_Cone  =     5
private let MagicID_Arris =     6

extension Int {
    
    var magicColor: UIColor? {
        switch self {
        case MagicID_Star:
            return YKColor.Hex(0xfda739)
        case MagicID_Moon:
            return YKColor.Hex(0xfbe064)
        case MagicID_Heart:
            return YKColor.Hex(0xfc6e51)
        case MagicID_Class:
            return YKColor.Hex(0x30c7b0)
        case MagicID_Cone:
            return YKColor.Hex(0x5e9fe2)
        case MagicID_Arris:
            return YKColor.Hex(0xb79ff2)
        default:
            return nil
        }
    }
}

