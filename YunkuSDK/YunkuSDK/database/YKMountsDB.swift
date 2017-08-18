//
//  YKMountsDB.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/4.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gknet
import gkutility

class YKMountsDB : YKBaseDB {
    
    override func createTable() {
        
        
        self.dbQueue.inDatabase { (db: FMDatabase) in
            
            var sql = "CREATE TABLE IF NOT EXISTS ENTS(entid int,entname varchar[100],adddateline bigint,enable_create_org smallint,enable_manage_member smallint,enable_publish_notice smallint,enable_manage_groups varchar[200],ent_admin smallint,ent_super_admin smallint,state smallint,is_expired smallint,trial smallint,rawjson vchar[4000],PRIMARY KEY (entid));";
            
            try? db.executeUpdate(sql, values: nil)
            
            sql = "CREATE TABLE IF NOT EXISTS MOUNTS(mountid int, orgid int, entid int, orgname varchar[200],orgtype int, membercount int,memberid int, membertype int,roleid int,add_dateline bigint,owner_member_id int,state int,rawjson varchar[4000],PRIMARY KEY (mountid));";
            
            try? db.executeUpdate(sql, values: nil)
            
            sql = "CREATE TABLE IF NOT EXISTS SHORTCUTS(type int,value int,uuidhash char[100]);"
            
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    override func updateTable() {
        
    }
    
    
    func getEnts() -> [GKEntDataItem] {
        var result = [GKEntDataItem]()
        let sql = "select * from ENTS order by entid asc ;"
        self.dbQueue.inDatabase { (db:FMDatabase) in
            if let res = db.executeQuery(sql, withParameterDictionary: nil) {
                while res.next() {
                    if let ent = self.entFromRes(res) {
                        result.append(ent)
                    }
                }
                res.close()
            }
        }
        return result
    }
    
    func getEnt(_ id: Int) -> GKEntDataItem? {
        let sql = "select * from ENTS where entid=\(id) ;"
        var result: GKEntDataItem? = nil
        self.dbQueue.inDatabase { (db:FMDatabase) in
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    result = entFromRes(rs)
                }
                rs.close()
            }
        }
        return result
    }
    
    func addEnt(ent:GKEntDataItem) {
        self.dbQueue .inDatabase { (db:FMDatabase) in
            var sql = "select * from ENTS where entid=\(ent.ent_id)"
            var bhave = false
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    bhave = true
                    break
                }
                rs.close()
            }
            
            var enable_manage_groups = ""
            if !ent.enable_manage_groups.isEmpty {
                for g in ent.enable_manage_groups {
                    if enable_manage_groups.isEmpty {
                        enable_manage_groups.append("\(g)")
                    } else {
                        enable_manage_groups.append("|\(g)")
                    }
                }
            }
            
            let rjson = ent.rawJson?.gkReplaceToSQL
            let rname = ent.ent_name.gkReplaceToSQL
            
            if bhave {
                sql = "update ENTS set entname='\(rname)',enable_create_org=\(ent.enable_create_org),enable_manage_member=\(ent.enable_manage_member),enable_publish_notice=\(ent.enable_publish_notice),enable_manage_groups='\(enable_manage_groups)',ent_admin=\(ent.ent_admin),ent_super_admin=\(ent.ent_super_admin),state=\(ent.state),is_expired=\(ent.is_expired),trial=\(ent.trial),rawjson='\(rjson ?? "")' where entid=\(ent.ent_id);"
            } else {
                sql = "insert into ENTS(entid,entname,adddateline,enable_create_org,enable_manage_member,enable_publish_notice,enable_manage_groups,ent_admin,ent_super_admin,state,is_expired,trial,rawjson) values(\(ent.ent_id),'\(rname)',\(ent.add_dateline),\(ent.enable_create_org),\(ent.enable_manage_member),\(ent.enable_publish_notice),'\(enable_manage_groups)',\(ent.ent_admin),\(ent.ent_super_admin),\(ent.state),\(ent.is_expired),\(ent.trial),'\(rjson ?? "")');"
            }
            try? db.executeUpdate(sql, values: nil)
            
        }
    }
    
    func deleteEnt(entID: Int) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            
            let sql = "delete from ENTS where entid=\(entID) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    
    func addMount(_ mount: GKMountDataItem) {
        self.dbQueue .inDatabase { (db:FMDatabase) in
            var sql = "select * from MOUNTS where mountid=\(mount.mount_id)"
            var bhave = false
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    bhave = true
                    break
                }
                rs.close()
            }
            
            let rjson = mount.rawJson?.gkReplaceToSQL
            let rname = mount.org_name.gkReplaceToSQL
            
            if bhave {
                sql = "update MOUNTS set orgname='\(rname)',orgtype=\(mount.org_type),membercount=\(mount.member_count),memberid=\(mount.member_id),membertype=\(mount.member_type),roleid=\(mount.role_id),owner_member_id=\(mount.owner_member_id),state=\(mount.state),rawjson='\(rjson ?? "")' where mountid=\(mount.mount_id);"
            } else {
                sql = "insert into MOUNTS(mountid,orgid,entid,orgname,orgtype,membercount,memberid,membertype,roleid,add_dateline,owner_member_id,state,rawjson) values(\(mount.mount_id),\(mount.org_id),\(mount.ent_id),'\(rname)',\(mount.org_type),\(mount.member_count),\(mount.member_id),\(mount.member_type),\(mount.role_id),\(mount.add_dateline),\(mount.owner_member_id),\(mount.state),'\(rjson ?? "")');"
            }
            try? db.executeUpdate(sql, values: nil)
            
        }
    }
    
    func getMounts() -> [GKMountDataItem] {
        var result = [GKMountDataItem]()
        let sql = "select * from MOUNTS ;"
        self.dbQueue.inDatabase { (db:FMDatabase) in
            if let res = db.executeQuery(sql, withParameterDictionary: nil) {
                while res.next() {
                    if let item = self.mountFromRes(res) {
                        result.append(item)
                    }
                }
                res.close()
            }
        }
        return result
    }
    
    func deleteMount(id: Int) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            
            let sql = "delete from MOUNTS where mountid=\(id) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    
    func addShortcut(_ shortcut: GKShortcutItem) {
        self.dbQueue .inDatabase { (db:FMDatabase) in
            var sql = "select * from SHORTCUTS where type=\(shortcut.type.rawValue) and value=\(shortcut.value) ;"
            var bhave = false
            
            if let rs = try? db.executeQuery(sql, values: nil) {
                while rs.next() {
                    bhave = true
                    break
                }
                rs.close()
            }
            
            if !bhave {
                sql = "insert into SHORTCUTS(type,value,uuidhash) values(\(shortcut.type.rawValue),\(shortcut.value),'\(shortcut.uuidhash)');"
                try? db.executeUpdate(sql, values: nil)
            }
        }
    }
    
    func getShortcuts() -> [GKShortcutItem] {
        var result = [GKShortcutItem]()
        let sql = "select * from SHORTCUTS ;"
        self.dbQueue.inDatabase { (db:FMDatabase) in
            if let res = db.executeQuery(sql, withParameterDictionary: nil) {
                while res.next() {
                    if let item = self.shortcutFromRes(res) {
                        result.append(item)
                    }
                }
                res.close()
            }
        }
        return result
    }
    
    func deleteShortcut(_ shortcut: GKShortcutItem) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            
            let sql = "delete from SHORTCUTS where type=\(shortcut.type.rawValue) and value=\(shortcut.value) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    
    private func entFromRes(_ res: FMResultSet) -> GKEntDataItem? {
        if let json = res.string(forColumn: "rawjson") {
            return GKEntDataItem(json: json)
        }
        return nil
    }
    
    private func mountFromRes(_ res: FMResultSet) -> GKMountDataItem? {
        if let json = res.string(forColumn: "rawjson") {
            return GKMountDataItem(json: json)
        }
        return nil
    }
    
    private func shortcutFromRes(_ res: FMResultSet) -> GKShortcutItem? {
        let item = GKShortcutItem()
        if let t = GKShortcutItem.GKShortcutType(rawValue:Int(res.int(forColumn: "type"))) {
            item.type = t
        } else {
            return nil;
        }
        item.value = Int( res.int(forColumn: "value"))
        if let h = res.string(forColumn: "uuidhash") {
            item.uuidhash = h
        }
        return item
    }
}
