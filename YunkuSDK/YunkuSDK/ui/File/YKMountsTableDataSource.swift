//
//  YKMountsTableDataSource.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/9.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gknet

protocol YKMountsDataTableSource  {
    func reload()
    func numberOfSections() -> Int
    func numberOfRowsInSection(_ section: Int) -> Int
    func nameOfSection(_ section: Int) -> (title:String,subtitle:String)
    func isFoldOfSection(_ section: Int) -> Bool
    func itemWithSection(_ section: Int, _ row: Int) -> AnyObject
    func setFoldOfSection(_ section: Int, _ fold: Bool)
}

class YKEntForTable {
    
    var entManager: YKEntManager
    var subitems = [YKMountItemCellWrap]()
    
    init(entManager: YKEntManager, selectType:YKSelectIconType = .None) {
        self.entManager = entManager
        
        if entManager.isShortcut {
            for item in entManager.subShortItems {
                if item.type == .Smart {
                    let m = YKMountItemCellWrap(favid: item.value,selectType: selectType)
                    subitems.append(m)
                } else if item.type == .Mount {
                    if let mount = YKMountCenter.shareInstance.mountItemBy(mountID: item.value) {
                        let m = YKMountItemCellWrap(mount: mount,selectType: selectType)
                        subitems.append(m)
                    }
                    
                }
            }
        } else {
            for item in entManager.subMounts {
                let m = YKMountItemCellWrap(mount: item.mountItem,selectType: selectType)
                subitems.append(m)
            }
        }
    }
}

class YKMountsDataTableSourceNormal : YKMountsDataTableSource {
    
    static var theSources = [YKMountsDataTableSourceNormal]()
    
    var entList = [YKEntForTable]()
    
    init() {
        self.reload()
    }
    
    deinit {
        //YKMountsDataTableSourceNormal.theSources.removeAll()
    }
    
   func reload() {
        var result = [YKEntForTable]()
    
        for em in YKMountCenter.shareInstance.entManagers {
            let item = YKEntForTable(entManager: em, selectType: .None)
            result.append(item)
        }
        
        entList = result
    }
    
    
    func numberOfSections() -> Int {
        return self.entList.count
    }
    
    func numberOfRowsInSection(_ section: Int) -> Int {
        let em = self.entList[section]
        if em.entManager.isFold {
            return 0
        }
        return em.subitems.count
    }
    
    func nameOfSection(_ section: Int) -> (title:String,subtitle:String) {
        let em = self.entList[section]
        let t = em.entManager.ent.ent_name
        let s = "(\(em.subitems.count))"
        return (t,s)
    }
    
    func isFoldOfSection(_ section: Int) -> Bool {
        let em = self.entList[section]
        return em.entManager.isFold
    }
    
    func itemWithSection(_ section: Int, _ row: Int) -> AnyObject {
        let em = self.entList[section]
        return em.subitems[row]
    }
    
    func setFoldOfSection(_ section: Int, _ fold: Bool) {
        let em = self.entList[section]
        em.entManager.isFold = fold
    }
}

class YKMountsDataTableSourceSingleSelect: YKMountsDataTableSourceNormal {
    
    
    override func reload() {
        var result = [YKEntForTable]()
        
        for em in YKMountCenter.shareInstance.entManagers {
            if em.isShortcut {
                continue
            }
            let item = YKEntForTable(entManager: em, selectType: .None)
            result.append(item)
        }
        
        entList = result
    }
}

class YKMountsDataTableSourceMultiSelect: YKMountsDataTableSourceNormal {
    
    
    override func reload() {
        var result = [YKEntForTable]()
        
        for em in YKMountCenter.shareInstance.entManagers {
            if em.isShortcut {
                continue
            }
            let item = YKEntForTable(entManager: em, selectType: .UnSelected)
            result.append(item)
        }
        
        entList = result
    }
}
