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
    
    static let shareDB = YKTransDB(path: "")
    
    override func createTable() {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            var sql = "CREATE TABLE IF NOT EXISTS Uploads(id INTEGER PRIMARY KEY AUTOINCREMENT,mountid int,fullpath varchar[2000] COLLATE NOCASE,parent varchar[1000] COLLATE NOCASE,filename varchar[1000] COLLATE NOCASE,dir smallint,filehash char[100],uuidhash char[100],status int,filesize bigint,offset bigint, localpath varchar[2000],overwrite smallint,expand int,errcode int,errmsg varchar[1000],errcount int,actlast bigint);"
            try? db.executeUpdate(sql, values: nil)
            
            sql = "CREATE TABLE IF NOT EXISTS Download(id INTEGER PRIMARY KEY AUTOINCREMENT,mountid int,fullpath varchar[1000] COLLATE NOCASE,parent varchar[1000] COLLATE NOCASE,filename varchar[1000] COLLATE NOCASE, localpath varchar[1000] COLLATE NOCASE,filehash varchar[50],uuidhash varchar[50],filesize bigint,dir int,status int,offset bigint,expand int,errcode int,errmsg varchar[1024],errcount int,hid char[100],net char[20],convert smallint,actlast bigint);"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func addUpload(mountid:Int,webpath:String,localpath:String, overwrite:Bool = false,expand: YKTransExpand = .None) -> YKUploadItemData {
        
        let item = YKUploadItemData()
        item.mountid = mountid
        item.webpath = webpath
        item.parent = webpath.gkParentPath
        item.filename = webpath.gkFileName
        item.dir = false
        item.localpath = localpath
        item.overwrite = overwrite
        item.expand = expand
        item.status = .Normal
        item.filesize = Int64(gkutility.fileSizeByPath(localpath))
        
        let rwebpath = webpath.gkReplaceToSQL
        let rlocal = localpath.gkReplaceToSQL
        let rfilename = item.filename.gkReplaceToSQL
        let rparent = item.parent.gkReplaceToSQL
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
                sql = "insert into Uploads(mountid,fullpath,parent,filename,dir,filehash,uuidhash,status,filesize,offset,localpath,overwrite,expand,errcode,errmsg,errcount,actlast) values(\(mountid),'\(rwebpath)','\(rparent)','\(rfilename)',\(item.dir ? 1 : 0),'\(item.filehash)','\(item.uuidhash)',\(item.status.rawValue),\(item.filesize),\(item.offset),'\(rlocal)',\(item.overwrite ? 1 : 0),\(item.expand.rawValue),\(item.errcode),'\(item.errmsg)',0,0) ;"
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
            let sql = "select * from Uploads where status=\(YKTransStatus.Normal.rawValue) and actlast<\(now) order by overwrite desc,id asc limit 100 ;"
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
    
    func getUploadItems(mountID:Int,parent:String) -> [YKUploadItemData] {
        var result = [YKUploadItemData]()
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "select * from Uploads where mountid=\(mountID) and parent='\(parent.gkReplaceToSQL)' and (status=\(YKTransStatus.Normal.rawValue) or status=\(YKTransStatus.Start.rawValue) or status=\(YKTransStatus.Stop.rawValue) or status=\(YKTransStatus.Error.rawValue))  order by id asc ;"
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
    
    func getStopUploads() -> [YKUploadItemData] {
        var result = [YKUploadItemData]()
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "select * from Uploads where status=\(YKTransStatus.Stop.rawValue)  order by id asc ;"
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
    
    func getUploadItemBy(id: Int) -> YKUploadItemData? {
        var result: YKUploadItemData?
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "select * from Uploads where id=\(id) ;"
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    let item = uploadItemFromRs(rs)
                    result = item
                }
                rs.close()
            }
        }
        return result
    }
    
    func getUploadItemBy(localPath: String) -> YKUploadItemData? {
        var result: YKUploadItemData?
        let rpath = localPath.gkReplaceToSQL
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "select * from Uploads where localpath='\(rpath)' ;"
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    let item = uploadItemFromRs(rs)
                    result = item
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
    
    func updateUploadStartActlast(taskID:Int) {
        let now = Int64(Date().timeIntervalSince1970)
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql: String = "update Uploads set status=\(YKTransStatus.Start.rawValue), actlast=\(now) where id=\(taskID) ;"
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
    
    func updateUploadError(taskID:Int,offset: Int64,errcode:Int,errmsg:String) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "update Uploads set status=\(YKTransStatus.Error.rawValue), offset=\(offset),errcode=\(errcode), errmsg='\(errmsg)' where id=\(taskID) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func updateUploadsToStop() {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "update Uploads set status=\(YKTransStatus.Stop.rawValue) where status=\(YKTransStatus.Normal.rawValue) or status=\(YKTransStatus.Start.rawValue) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func deleteUpload(taskID: Int) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            try? db.executeUpdate("delete from Uploads where id=\(taskID) ;", values: nil)
        }
    }
    
    func resetForSimulate(transCahePath:String) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            var sql = "select * from Uploads where status!=\(YKTransStatus.Finish.rawValue) and status!=\(YKTransStatus.Removed.rawValue) ;"
            var uploads = [YKUploadItemData]()
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    let item = uploadItemFromRs(rs)
                    uploads.append(item)
                }
                rs.close()
            }
            
            if uploads.count > 0 {
                db.beginTransaction()
                
                for item in uploads {
                    let local = transCahePath.gkAddLastSlash + item.filename
                    sql = "update Uploads set localpath='\(local)' where id=\(item.nID) ;"
                    try? db.executeUpdate(sql, values: nil)
                }
                
                db.commit()
            }
            
            
            sql = "select * from Download where status!=\(YKTransStatus.Finish.rawValue) and status!=\(YKTransStatus.Removed.rawValue) ;"
            var downloads = [YKDownloadItemData]()
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    let item = downloadItemFromRs(rs)
                    downloads.append(item)
                }
                rs.close()
            }
            
            if downloads.count > 0 {
                db.beginTransaction()
                
                for item in downloads {
                    let local = YKCacheManager.shareManager.cachePath(key: item.filehash, type: (item.convert ? .Convert : .Original ))
                    sql = "update Download set localpath='\(local)' where id=\(item.nID) ;"
                    try? db.executeUpdate(sql, values: nil)
                }
                
                db.commit()
            }
            
        }
    }
    
    func resetUploads() {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            var sql = "update Uploads set status=\(YKTransStatus.Error.rawValue),errcode=1, errmsg='\(YKLocalizedString("上传被取消"))' where status=\(YKTransStatus.Stop.rawValue) or status=\(YKTransStatus.Start.rawValue)  or status=\(YKTransStatus.Normal.rawValue) ;"
            try? db.executeUpdate(sql, values: nil)
            
            sql = "delete from Uploads where status=\(YKTransStatus.Finish.rawValue) or status=\(YKTransStatus.Removed.rawValue) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    
    func addDownload(mountid:Int,webpath:String,filehash:String,dir:Bool,filesize:Int64,localpath:String, convert:Bool, hid:String? = nil, net:String? = nil, expand: YKTransExpand = .None) -> YKDownloadItemData {
        
        let item = YKDownloadItemData()
        item.mountid = mountid
        item.webpath = webpath
        item.parent = webpath.gkParentPath
        item.filename = webpath.gkFileName
        item.dir = dir
        item.filehash = filehash
        item.localpath = localpath
        item.convert = convert
        item.expand = expand
        item.status = .Normal
        item.filesize = filesize
        item.hid = hid
        item.net = net
        item.offset = 0
        
        let rwebpath = webpath.gkReplaceToSQL
        let rlocal = localpath.gkReplaceToSQL
        let rfilename = item.filename.gkReplaceToSQL
        let rparent = item.parent.gkReplaceToSQL
        self.dbQueue.inDatabase { (db:FMDatabase) in
            var thehid = ""
            var thenet = ""
            if hid != nil { thehid = hid! }
            if net != nil { thenet = net! }
            var sql = "select * from Download where mountid=\(mountid) and fullpath='\(rwebpath)' and hid='\(thehid)' and convert=\(convert ? 1 : 0) and expand=\(expand.rawValue) ;"
            var bhave = false
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    bhave = true
                    break
                }
                rs.close()
            }
            
            if bhave {
                sql = "update Download set status=\(item.status.rawValue),filehash='\(filehash)',filesize=\(filesize),localpath='\(rlocal)',errcode=\(item.errcode),errmsg='\(item.errmsg)' where mountid=\(mountid) and fullpath='\(rwebpath)' and hid='\(thehid)' and convert=\(convert ? 1 : 0) and expand=\(expand.rawValue) ;"
            } else {
                sql = "insert into Download(mountid,fullpath,parent,filename,dir,filehash,uuidhash,status,filesize,offset,localpath,hid,net,convert,expand,errcode,errmsg,errcount,actlast) values(\(mountid),'\(rwebpath)','\(rparent)','\(rfilename)',\(item.dir ? 1 : 0),'\(item.filehash)','\(item.uuidhash)',\(item.status.rawValue),\(item.filesize),\(item.offset),'\(rlocal)','\(thehid)','\(thenet)',\(item.convert ? 1 : 0),\(item.expand.rawValue),\(item.errcode),'\(item.errmsg)',0,0) ;"
            }
            
            if db.executeUpdate(sql, withArgumentsIn: []) {
                
                var nid = -1
                sql = "select * from Download where mountid=\(mountid) and fullpath='\(rwebpath)' and convert=\(convert ? 1 : 0) and hid='\(thehid)' and expand=\(expand.rawValue) ;"
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
    
    
    func getDownloadItems(mountID:Int,parent:String,expand:YKTransExpand) -> [YKDownloadItemData] {
        var result = [YKDownloadItemData]()
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "select * from Download where mountid=\(mountID) and parent='\(parent.gkReplaceToSQL)' and expand=\(expand.rawValue) and (status=\(YKTransStatus.Normal.rawValue) or status=\(YKTransStatus.Start.rawValue) or status=\(YKTransStatus.Stop.rawValue) or status=\(YKTransStatus.Error.rawValue))  order by id asc ;"
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    let item = downloadItemFromRs(rs)
                    result.append(item)
                }
                rs.close()
            }
        }
        return result
    }
    
    func getDownloadItemBy(id: Int) -> YKDownloadItemData? {
        var result: YKDownloadItemData?
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "select * from Download where id=\(id) ;"
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    let item = downloadItemFromRs(rs)
                    result = item
                }
                rs.close()
            }
        }
        return result
    }
    
    func getStopDownloads() -> [YKDownloadItemData] {
        var result = [YKDownloadItemData]()
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "select * from Download where status=\(YKTransStatus.Stop.rawValue)  order by id asc ;"
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    let item = downloadItemFromRs(rs)
                    result.append(item)
                }
                rs.close()
            }
        }
        return result
    }
    
    
    func updateDownloadFinish(taskID:Int) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql: String = "update Download set status=\(YKTransStatus.Finish.rawValue), offset=filesize  where id=\(taskID) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func updateDownloadsFinishBy(filehash:String) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql: String = "update Download set status=\(YKTransStatus.Finish.rawValue), offset=filesize,errcode=0,errcount=0 where filehash='\(filehash)' and convert=0 and (status=\(YKTransStatus.Normal.rawValue) || status=\(YKTransStatus.Start.rawValue) || status=\(YKTransStatus.Error.rawValue) || status=\(YKTransStatus.Stop.rawValue) ) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func updateDownloadError(taskID:Int,offset: Int64,errcode:Int,errmsg:String) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "update Download set status=\(YKTransStatus.Error.rawValue), offset=\(offset),errcode=\(errcode), errmsg='\(errmsg)' where id=\(taskID) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func updateDownloadFilesize(taskID:Int,filesize: Int64) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "update Download set filesize=\(filesize) where id=\(taskID) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func updateDownloadStatus(taskID:Int,status: YKTransStatus,offset: Int64?) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql: String
            if offset != nil {
                sql = "update Download set status=\(status.rawValue), offset=\(offset!) where id=\(taskID) ;"
            } else {
                sql = "update Download set status=\(status.rawValue) where id=\(taskID) ;"
            }
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func updateDownloadStartActlast(taskID:Int) {
        let now = Int64(Date().timeIntervalSince1970)
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql: String = "update Download set status=\(YKTransStatus.Start.rawValue), actlast=\(now) where id=\(taskID) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func updateDownloadStart(taskID:Int) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql: String = "update Download set status=\(YKTransStatus.Start.rawValue), offset=0, errcode=0, errmsg='' where id=\(taskID) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func updateDownloadsToStop() {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "update Download set status=\(YKTransStatus.Stop.rawValue) where status=\(YKTransStatus.Normal.rawValue) or status=\(YKTransStatus.Start.rawValue) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    
    func deleteDownload(taskID: Int) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            try? db.executeUpdate("delete from Download where id=\(taskID) ;", values: nil)
        }
    }
    
    func resetDownloads() {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            
            var sql = "update Download set status=\(YKTransStatus.Error.rawValue),errcode=1, errmsg='\(YKLocalizedString("下载被取消"))' where status=\(YKTransStatus.Stop.rawValue) or status=\(YKTransStatus.Start.rawValue)  or status=\(YKTransStatus.Normal.rawValue) ;"
            try? db.executeUpdate(sql, values: nil)
            
            sql = "delete from Download where status=\(YKTransStatus.Finish.rawValue) or status=\(YKTransStatus.Removed.rawValue) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    
    private func uploadItemFromRs(_ rs: FMResultSet) -> YKUploadItemData {
        
        let item = YKUploadItemData()
        item.nID = Int(rs.int(forColumn: "id"))
        item.mountid = Int(rs.int(forColumn: "mountid"))
        item.webpath = (rs.string(forColumn: "fullpath") ?? "")
        item.parent = (rs.string(forColumn: "parent") ?? "")
        item.dir = (Int(rs.int(forColumn: "dir")) > 0)
        item.filename = (rs.string(forColumn: "filename") ?? "")
        item.filehash = (rs.string(forColumn: "filehash") ?? "")
        item.uuidhash = (rs.string(forColumn: "uuidhash") ?? "")
        item.localpath = (rs.string(forColumn: "localpath") ?? "")
        item.filesize = rs.longLongInt(forColumn: "filesize")
        item.offset = rs.longLongInt(forColumn: "offset")
        item.status = (YKTransStatus(rawValue: Int(rs.int(forColumn: "status"))) ?? .Normal)
        item.expand = (YKTransExpand(rawValue: Int(rs.int(forColumn: "expand"))) ?? .None)
        item.overwrite = (rs.int(forColumn: "overwrite") > 0)
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
