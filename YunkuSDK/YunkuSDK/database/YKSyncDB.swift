//
//  YKSyncDB.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/8.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gknet
import gkutility

class YKSyncDB : YKBaseDB {
    
    override func createTable() {
        
        self.dbQueue.inDatabase { (db:FMDatabase) in
            
            let sql = "CREATE TABLE IF NOT EXISTS SYNC(path varchar[1000] COLLATE NOCASE UNIQUE,mountid int,parent varchar[1000] COLLATE NOCASE, dir int, filehash char[40], uuidhash char[40], filesize bigint,filename varchar[2000],lasttime bigint,lastid int,lastname varchar[50],createtime bigint,createid int,createname varchar[50],lock int,lockid int,lockname varchar[50],property varchar[1000],PRIMARY KEY (path));"
            
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    private func sqlForUpdate(_ file: GKFileDataItem, _ isupdate: Bool) -> String {
        
        let rpath = file.fullpath.gkReplaceToSQL
        let rparent = rpath.gkParentPath.gkReplaceToSQL
        let rfilename = file.filename.gkReplaceToSQL
        let rproperty = file.property.gkReplaceToSQL
        let rcreatename = file.create_member_name.gkReplaceToSQL
        let rlastname = file.last_member_name.gkReplaceToSQL
        let rlockname = file.lock_member_name.gkReplaceToSQL
        
        if isupdate {
            return "update SYNC set uuidhash='\(file.uuidhash)',filehash='\(file.filehash)',filesize=\(file.filesize),filename='\(rfilename)',lasttime=\(file.last_dateline),lastid=\(file.last_member_id),lastname='\(rlastname)',createid=\(file.create_member_id),createname='\(rcreatename)',lock=\(file.lock),lockid=\(file.lock_member_id),lockname='\(rlockname)',property='\(rproperty)' where path='\(rpath)' ;"
        } else {
            return "insert into SYNC(path,mountid,parent,dir,filehash,uuidhash,filesize,filename,lasttime,lastid,lastname,createtime,createid,createname,lock,lockid,lockname,property) values('\(rpath)',\(file.mount_id),'\(rparent)',\(file.dir ? 1 : 0),'\(file.filehash)','\(file.uuidhash)',\(file.filesize),'\(rfilename)',\(file.last_dateline),\(file.last_member_id),'\(rlastname)',\(file.create_dateline),\(file.create_member_id),'\(rcreatename)',\(file.lock),\(file.lock_member_id),'\(rlockname)','\(rproperty)') ;"
        }
    }
    
    func updateFiles(_ files: [GKFileDataItem], _ parent: String) {
        
        var rparent = parent.gkReplaceToSQL
        if parent == "/" {
            rparent = ""
        }
        self.dbQueue.inDatabase { (db:FMDatabase) in
            var sql = "select * from SYNC where parent='\(rparent)' ;"
            var locals = [GKFileDataItem]()
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    let f = self.fileFromRes(rs)
                    locals.append(f)
                }
                rs.close()
            }
            
            for file in files {
                for l in locals {
                    if l.fullpath == file.fullpath {
                        l.bremoved = true
                        break
                    }
                }
            }
            
            db.beginTransaction()
            
            for file in locals {
                if file.bremoved { continue }
                let rpath = file.fullpath.gkReplaceToSQL
                if file.dir {
                    sql = "delete from SYNC where path='\(rpath)' or path like '\(rpath)/%%' ;"
                } else {
                    sql = "delete from SYNC where path='\(rpath)' ;"
                }
                
                try? db.executeUpdate(sql, values: nil)
            }
            
            for file in files {
                
                let rpath = file.fullpath.gkReplaceToSQL
                
                let sql = "select * from SYNC where path='\(rpath)' ;"
                var bhave = false
                if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                    while rs.next() {
                        bhave = true
                        break
                    }
                    rs.close()
                }
                
                try? db.executeUpdate(self.sqlForUpdate(file, bhave), values: nil)
            }
            
            
            db.commit()
        }
    }
    
    func addFiles(_ files: [GKFileDataItem]) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            
            if files.count > 1 { db.beginTransaction() }
            
            for file in files {
                
                let rpath = file.fullpath.gkReplaceToSQL
                
                let sql = "select * from SYNC where path='\(rpath)' ;"
                var bhave = false
                if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                    while rs.next() {
                        bhave = true
                        break
                    }
                    rs.close()
                }
                
                try? db.executeUpdate(self.sqlForUpdate(file, bhave), values: nil)
            }
            
            if files.count > 1 { db.commit() }
        }
    }
    
    func getFile(fullpath: String) -> GKFileDataItem? {
        
        var file: GKFileDataItem? = nil
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let rpath = fullpath.gkReplaceToSQL
            let sql = "select * from SYNC where path='\(rpath)' ;"
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    file = self.fileFromRes(rs)
                    break
                }
                rs.close()
            }
        }
        
        return file
    }
    
    func getFile(hash: String) -> GKFileDataItem? {
        var file: GKFileDataItem? = nil
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "select * from SYNC where uuidhash='\(hash)' ;"
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    file = self.fileFromRes(rs)
                    break
                }
                rs.close()
            }
        }
        
        return file
    }
    
    func getFiles(_ parent: String = "") -> [GKFileDataItem] {
        var result = [GKFileDataItem]()
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let rparent = parent.gkReplaceToSQL
            let sql = "select * from SYNC where parent='\(rparent)' ;"
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    let f = self.fileFromRes(rs)
                    result.append(f)
                }
                rs.close()
            }
        }
        return result
    }
    
    func deleteFile(path: String, dir: Bool = false) {
        let rpath = path.gkReplaceToSQL
        self.dbQueue.inDatabase { (db:FMDatabase) in
            var sql = "delete from SYNC where path='\(rpath)' ;"
            if dir {
                sql = "delete from SYNC where (path='\(rpath)' or path like '\(rpath)/%%') ;"
            }
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    private func fileFromRes(_ res: FMResultSet) -> GKFileDataItem  {
        
        let file = GKFileDataItem()
        file.fullpath = res.string(forColumn: "path") ?? ""
        file.mount_id = Int(res.int(forColumn: "mountid"))
        file.uuidhash = (res.string(forColumn: "uuidhash") ?? "")
        file.filehash = (res.string(forColumn: "filehash") ?? "")
        file.filename = (res.string(forColumn: "filename") ?? "")
        file.dir = (res.int(forColumn: "dir") > 0)
        file.filesize = res.longLongInt(forColumn: "filesize")
        file.create_member_id = Int(res.int(forColumn: "createid"))
        file.create_dateline = res.longLongInt(forColumn: "createtime")
        file.create_member_name = (res.string(forColumn: "createname") ?? "")
        file.last_member_id = Int(res.int(forColumn: "lastid"))
        file.last_dateline = res.longLongInt(forColumn: "lasttime")
        file.last_member_name = (res.string(forColumn: "lastname") ?? "")
        file.lock = Int(res.int(forColumn: "lock"))
        file.lock_member_id = Int(res.int(forColumn: "lockid"))
        file.lock_member_name = (res.string(forColumn: "lockname") ?? "")
        file.property = (res.string(forColumn: "property") ?? "")
        file.setothers()
        return file
    }
}
