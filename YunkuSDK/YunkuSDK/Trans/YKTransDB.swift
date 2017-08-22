//
//  YKTransDB.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/14.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gkutility

class YKTransDB : YKBaseDB {
    
    override func createTable() {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            var sql = "CREATE TABLE IF NOT EXISTS Uploads(id INTEGER PRIMARY KEY AUTOINCREMENT,mountid int,fullpath varchar[2000] COLLATE NOCASE,parent varchar[1000] COLLATE NOCASE,filename varchar[1000] COLLATE NOCASE,dir smallint,filehash char[100],uuidhash char[100],status int,filesize bigint,offset bigint, localpath varchar[2000],editupload smallint,expand int,errcode int,errmsg varchar[1000],errcount int,actlast bigint);"
            try? db.executeUpdate(sql, values: nil)
            
            sql = "CREATE TABLE IF NOT EXISTS Download(id INTEGER PRIMARY KEY AUTOINCREMENT,mountid int,fullpath varchar[1000] COLLATE NOCASE,parent varchar[1000] COLLATE NOCASE,filename varchar[1000] COLLATE NOCASE, localpath varchar[1000] COLLATE NOCASE,filehash varchar[50],uuidhash varchar[50],filesize bigint,dir int,status int,offset bigint,expand int,errcode int,errmsg varchar[1024],errcount int,actlast bigint,hid char[100],net char[20],convert smallint);"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func addUpload(mountid:Int,webpath:String,localpath:String, edit:Bool = false,expand: YKTransExpand = .None) -> YKUploadItemData {
        
        let item = YKUploadItemData()
        item.mountid = mountid
        item.webpath = webpath
        item.localpath = localpath
        item.editupload = edit
        item.expand = expand
        item.status = .Normal
        item.filesize = Int64(gkutility.fileSizeByPath(localpath))
        
        let rwebpath = webpath.gkReplaceToSQL
        let rlocal = localpath.gkReplaceToSQL
        self.dbQueue.inDatabase { (db:FMDatabase) in
            var sql = "select * from Uploads where mountid=\(mountid) and fullpath='\(rwebpath)' ;"
            var bhave = false
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    bhave = true
                    break
                }
                rs.close()
            }
            
            if bhave {
                sql = "update Uploads set status=\(item.status.rawValue),filesize=\(item.filesize),offset=\(item.offset),localpath='\(rlocal)',errcode=\(item.errcode),errmsg='\(item.errmsg)' where mountid=\(mountid) and fullpath='\(rwebpath)' ;"
            } else {
                sql = "insert into Uploads(mountid,fullpath,filehash,uuidhash,status,filesize,offset,localpath,editupload,expand,errcode,errmsg) values(\(mountid),'\(rwebpath)','\(item.filehash)','\(item.uuidhash)',\(item.status.rawValue),\(item.filesize),\(item.offset),'\(rlocal)',\(item.editupload),\(item.expand.rawValue),\(item.errcode),'\(item.errmsg)') ;"
            }
            
            if db.executeUpdate(sql, withArgumentsIn: []) {
                
                var nid = -1
                sql = "select * from Uploads where mountid=\(mountid) and fullpath='\(rwebpath)' ;"
                if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                    while rs.next() {
                        nid = Int(rs.int(forColumn: "id"))
                        break
                    }
                    rs.close()
                }
                item.nID = nid
                
            } else {
                
            }
        }
        
        return item
    }
    
    func getUploads() -> [YKUploadItemData] {
        var result = [YKUploadItemData]()
        let now = Int64(Date().timeIntervalSince1970)
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "select * from Uploads where status=\(YKTransStatus.Normal.rawValue) and actlast<\(now) order by editupload desc,id asc limit 100 ;"
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    let item = uploadItemFromRs(rs)
                    result.append(item)
                }
                rs.close()
            }
        }
        return result
    }
    
    func updateUploadFilehash(taskID: Int,filehash: String,filesize: Int64?) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql: String
            if filesize != nil {
                sql = "update Uploads set filehash='\(filehash)', filesize=\(filesize!) where id=\(taskID) ;"
            } else {
                sql = "update Uploads set filehash='\(filehash)' where id=\(taskID) ;"
            }
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func updateUploadUuidhash(taskID: Int,uuidhash: String,filesize: Int64?) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql: String
            if filesize != nil {
                sql = "update Uploads set uuidhash='\(uuidhash)', filesize=\(filesize!) where id=\(taskID) ;"
            } else {
                sql = "update Uploads set uuidhash='\(uuidhash)' where id=\(taskID) ;"
            }
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func updateUploadStart(taskID:Int) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql: String = "update Uploads set status=\(YKTransStatus.Start.rawValue), offset=0, errcode=0, errmsg='' where id=\(taskID) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func updateUploadFinish(taskID:Int) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql: String = "update Uploads set status=\(YKTransStatus.Finish.rawValue), offset=filesize  where id=\(taskID) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func updateUploadStatus(taskID:Int,status: YKTransStatus,offset: Int64?) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql: String
            if offset != nil {
                sql = "update Uploads set status=\(status.rawValue), offset=\(offset!) where id=\(taskID) ;"
            } else {
                sql = "update Uploads set status=\(status.rawValue) where id=\(taskID) ;"
            }
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    private func uploadItemFromRs(_ rs: FMResultSet) -> YKUploadItemData {
        
        let item = YKUploadItemData()
        item.nID = Int(rs.int(forColumn: "id"))
        item.mountid = Int(rs.int(forColumn: "mountid"))
        item.webpath = (rs.string(forColumn: "fullpath") ?? "")
        item.parent = (rs.string(forColumn: "parent") ?? "")
        item.filename = (rs.string(forColumn: "filename") ?? "")
        item.filehash = (rs.string(forColumn: "filehash") ?? "")
        item.uuidhash = (rs.string(forColumn: "uuidhash") ?? "")
        item.localpath = (rs.string(forColumn: "localpath") ?? "")
        item.filesize = rs.longLongInt(forColumn: "filesize")
        item.offset = rs.longLongInt(forColumn: "offset")
        item.status = (YKTransStatus(rawValue: Int(rs.int(forColumn: "status"))) ?? .Normal)
        item.expand = (YKTransExpand(rawValue: Int(rs.int(forColumn: "expand"))) ?? .None)
        item.editupload = (rs.int(forColumn: "editupload") > 0)
        item.errcode = Int(rs.int(forColumn: "errcode"))
        item.errmsg = (rs.string(forColumn: "errmsg") ?? "")
        
        return item
    }
    
    private func downloadItemFromRs(_ rs: FMResultSet) -> YKDownloadItemData {
        
        let item = YKDownloadItemData()
        item.nID = Int(rs.int(forColumn: "id"))
        item.mountid = Int(rs.int(forColumn: "mountid"))
        item.webpath = (rs.string(forColumn: "fullpath") ?? "")
        item.parent = (rs.string(forColumn: "parent") ?? "")
        item.filename = (rs.string(forColumn: "filename") ?? "")
        item.filehash = (rs.string(forColumn: "filehash") ?? "")
        item.uuidhash = (rs.string(forColumn: "uuidhash") ?? "")
        item.localpath = (rs.string(forColumn: "localpath") ?? "")
        item.filesize = rs.longLongInt(forColumn: "filesize")
        item.offset = rs.longLongInt(forColumn: "offset")
        item.status = (YKTransStatus(rawValue: Int(rs.int(forColumn: "status"))) ?? .Normal)
        item.expand = (YKTransExpand(rawValue: Int(rs.int(forColumn: "expand"))) ?? .None)
        item.hid = rs.string(forColumn: "hid")
        item.net = rs.string(forColumn: "net")
        item.convert = (rs.int(forColumn: "convert") > 0)
        item.errcode = Int(rs.int(forColumn: "errcode"))
        item.errmsg = (rs.string(forColumn: "errmsg") ?? "")
        return item
    }
}