//
//  YKFavFiles.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/14.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gknet
import gkutility

class YKFavDB : YKBaseDB {
    
    override func createTable() {
        
        self.dbQueue.inDatabase { (db:FMDatabase) in
            
            let sql = "CREATE TABLE IF NOT EXISTS FAV(type int, path varchar[1000] COLLATE NOCASE UNIQUE,mountid int,parent varchar[1000] COLLATE NOCASE, dir int, filehash char[40], uuidhash char[40], filesize bigint,filename varchar[2000],lasttime bigint,lastid int,lastname varchar[50],createtime bigint,createid int,createname varchar[50],lock int,lockid int,lockname varchar[50],property varchar[1000]);"
            
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    private func sqlForUpdate(_ file: GKFileDataItem, _ type: Int, _ isupdate: Bool) -> String {
        
        let rpath = file.fullpath.gkReplaceToSQL
        let rparent = rpath.gkParentPath.gkReplaceToSQL
        let rfilename = file.filename.gkReplaceToSQL
        let rproperty = file.property.gkReplaceToSQL
        let rcreatename = file.create_member_name.gkReplaceToSQL
        let rlastname = file.last_member_name.gkReplaceToSQL
        let rlockname = file.lock_member_name.gkReplaceToSQL
        
        if isupdate {
            return "update FAV set uuidhash='\(file.uuidhash)',filehash='\(file.filehash)',filesize=\(file.filesize),filename='\(rfilename)',lasttime=\(file.last_dateline),lastid=\(file.last_member_id),lastname='\(rlastname)',createid=\(file.create_member_id),createname='\(rcreatename)',lock=\(file.lock),lockid=\(file.lock_member_id),lockname='\(rlockname)',property='\(rproperty)' where type=\(type) and mountid=\(file.mount_id) and path='\(rpath)' ;"
        } else {
            return "insert into FAV(type,path,mountid,parent,dir,filehash,uuidhash,filesize,filename,lasttime,lastid,lastname,createtime,createid,createname,lock,lockid,lockname,property) values(\(type),'\(rpath)',\(file.mount_id),'\(rparent)',\(file.dir ? 1 : 0),'\(file.filehash)','\(file.uuidhash)',\(file.filesize),'\(rfilename)',\(file.last_dateline),\(file.last_member_id),'\(rlastname)',\(file.create_dateline),\(file.create_member_id),'\(rcreatename)',\(file.lock),\(file.lock_member_id),'\(rlockname)','\(rproperty)') ;"
        }
    }
    
    func addFiles(_ files: [GKFileDataItem], type: Int) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            
            if files.count > 1 { db.beginTransaction() }
            
            for file in files {
                
                let rpath = file.fullpath.gkReplaceToSQL
                
                let sql = "select * from FAV where type=\(type) and mountid=\(file.mount_id) and path='\(rpath)' ;"
                var bhave = false
                if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                    while rs.next() {
                        bhave = true
                        break
                    }
                    rs.close()
                }
                
                try? db.executeUpdate(self.sqlForUpdate(file,type, bhave), values: nil)
            }
            
            if files.count > 1 { db.commit() }
        }
    }
    
    func getFile(type: Int, mountID: Int, fullpath: String) -> GKFileDataItem? {
        
        var file: GKFileDataItem? = nil
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let rpath = fullpath.gkReplaceToSQL
            let sql = "select * from FAV where type=\(type) and mountid=\(mountID) and path='\(rpath)' ;"
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
    
    func getFile(type: Int, mountID: Int,hash: String) -> GKFileDataItem? {
        var file: GKFileDataItem? = nil
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "select * from FAV where type=\(type) and mountid=\(mountID) and uuidhash='\(hash)' ;"
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
    
    func getFiles(_ type: Int) -> [GKFileDataItem] {
        var result = [GKFileDataItem]()
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "select * from FAV where type=\(type) ;"
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
    
    func deleteFile(type: Int, mountID: Int, path: String, dir: Bool = false) {
        let rpath = path.gkReplaceToSQL
        self.dbQueue.inDatabase { (db:FMDatabase) in
            var sql = "delete from FAV where type=\(type) and mountid=\(mountID) and path='\(rpath)' ;"
            if dir {
                sql = "delete from FAV where type=\(type) and mountid=\(mountID) and (path='\(rpath)' or path like '\(rpath)/%%') ;"
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
