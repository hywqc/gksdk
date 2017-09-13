//
//  YKUploadTask.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/22.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gknet
import gkutility

let kYKEmptyFilehash = "da39a3ee5e6b4b0d3255bfef95601890afd80709"

class YKUploadTask : Operation {
    
    var pItem: YKUploadItemData!
    var bStop = false
    var bRemoved = false
    var bDelete = false
    
    var createFileRet: GKRequestRetCreateFile?
    
    var uploadsession = ""
    
    init(uploadItem: YKUploadItemData) {
        self.pItem = YKUploadItemData()
        pItem.nID = uploadItem.nID
        pItem.mountid = uploadItem.mountid
        pItem.dir = uploadItem.dir
        pItem.webpath = uploadItem.webpath
        pItem.parent = uploadItem.parent
        pItem.filename = uploadItem.filename
        pItem.filehash = uploadItem.filehash
        pItem.uuidhash = uploadItem.uuidhash
        pItem.filesize = uploadItem.filesize
        pItem.overwrite = uploadItem.overwrite
        pItem.localpath = uploadItem.localpath
        pItem.offset = uploadItem.offset
        pItem.status = uploadItem.status
        pItem.errcode = uploadItem.errcode
        pItem.errcount = uploadItem.errcount
        pItem.errmsg = uploadItem.errmsg
        pItem.expand = uploadItem.expand
    }
    
    var refreshTime: TimeInterval = 0
    
    func stop() {
        bStop = true
        bDelete = false
    }
    
    func delete() {
        bStop = true
        bDelete = true
    }
    
    override func main() {
        
        defer {
            bRemoved = true
        }
        
        pItem.status = .Start
        YKEventNotify.notify(self.pItem, type: .uploadFile)
        
        let fm = FileManager.default
        if pItem.localpath.isEmpty || !fm.fileExists(atPath: pItem.localpath) {
            self.failed(errcode: 1, errmsg: YKLocalizedString("file not exist or has been deleted"))
            return
        }
        
        if pItem.webpath.isEmpty || pItem.filename.isEmpty {
            self.failed(errcode: 1, errmsg: YKLocalizedString("invalid file name"))
            return
        }
        
        YKTransfer.shanreInstance.transDB?.updateUploadStartActlast(taskID: pItem.nID)
        
        if bStop {
            stophandle(bDelete)
            return
        }
        
        if pItem.dir {
            let ret = GKHttpEngine.default.createFolder(mountid: pItem.mountid, webpath: pItem.webpath, create_dateline: nil, last_dateline: nil)
            if ret.statuscode == 200 {
                self.finish()
            } else {
                self.failed(errcode: ret.errcode, errmsg: ret.errmsg)
            }
            return
        }
        
        let filesize = Int64(gkutility.fileSizeByPath(pItem.localpath))
        if filesize == 0 {
            let ret = GKHttpEngine.default.createFile(mountid: pItem.mountid, webpath: pItem.webpath, filehash: kYKEmptyFilehash, filesize: 0, overwrite: true)
            if ret.statuscode == 200 {
                self.finish()
            } else {
                self.failed(errcode: ret.errcode, errmsg: ret.errmsg)
            }
            return
        }
        
        if bStop {
            stophandle(bDelete)
            return
        }
        
        var filename = pItem.filename
        filename = filename.gkUrlEncode
        let file_hash = gkutility.getfilehash(path: pItem.localpath)
        
        if file_hash.isEmpty {
            self.failed(errcode: 1, errmsg: "filehash error")
            return
        }
        
        if bStop {
            stophandle(bDelete)
            return
        }
        
        YKTransfer.shanreInstance.transDB?.updateUploadFilehash(taskID: pItem.nID, filehash: file_hash, filesize: filesize)
        
        self.pItem.filesize = filesize
        self.pItem.filehash = file_hash
        
        if !self.upload_create() || createFileRet == nil {
            return
        }
        
        
        self.pItem.uuidhash = createFileRet!.uuidhash
        YKTransfer.shanreInstance.transDB?.updateUploadUuidhash(taskID: pItem.nID, uuidhash: pItem.uuidhash, filesize: nil)
        
        if createFileRet?.state == 1 {
            self.finish()
            return
        }
        
        if bStop {
            stophandle(bDelete)
            return
        }
        
        var hostarr = [GKHostItem]()
        for item in createFileRet!.cache_uploads {
            hostarr.append(item)
        }
        for item in createFileRet!.uploads {
            hostarr.append(item)
        }
        
        if hostarr.isEmpty {
            self.failed(errcode: 1, errmsg: "no upload host")
            return
        }
        
        var hostindex = 0
        var lasterrcode = 0
        var lasterrmsg = ""
        let partsize: Int = 1024 //1024*50
        
        var uploadurl = self.getServerTarget()
        while true {
            
            if uploadurl.isEmpty {
                if hostindex >= hostarr.count {
                    self.failed(errcode: lasterrcode, errmsg: lasterrmsg)
                    break;
                } else {
                    uploadurl = hostarr[hostindex].fullurl(usehttps: true, hostin: false)
                }
            }
            
            
            let host = uploadurl
            self.saveServerTargte(strUrl: host)
            
            if bStop {
                stophandle(bDelete)
                return
            }
            

            let uploadinitRet = self.upload_init(host: host)
            
            if uploadinitRet.errcode == 202 {
                self.finish()
                return
            }
            
            if uploadinitRet.errcode != 200 {
                lasterrcode = uploadinitRet.errcode
                lasterrmsg = uploadinitRet.errmsg
                hostindex += 1
                self.deleteServerTarget()
                uploadurl = ""
                continue
            }
            
            if bStop {
                stophandle(bDelete)
                return
            }
            
            
            let filehandle = FileHandle(forReadingAtPath: pItem.localpath)
            
            if filehandle == nil {
                self.failed(errcode: 1, errmsg: "can not read file")
                return
            }
            
            var index = 0
            
            filehandle!.seek(toFileOffset: 0)
            
            var trycount409 = 0
            
            var errorhappen = false
            
            while filehandle!.offsetInFile < UInt64(filesize) && !bStop {
                
                autoreleasepool(invoking: { () -> Void in
                    
                    let data = filehandle!.readData(ofLength: partsize)
                    let crc = "\(data.gkcrc32)"
                    
                    let start: Int64 = Int64(index * partsize)
                    let end: Int64 = (start + Int64(data.count) - 1)
                    
                    let ret = GKHttpEngine.default.uploadFilePart(host: host, session: self.uploadsession, start: start, end: end, data: data, crc: crc)
                    
                    if self.bStop {
                        return
                    }
                    
                    if ret.statuscode != 200  {
                        
                        errorhappen = true
                        if ret.errcode == 40900 && trycount409 < 3 {
                            trycount409 += 1
                            if let d = ret.data {
                                if let jsondic = d.gkDic {
                                    let expect = gkSafeLongLong(dic: jsondic, key: "expect")
                                    if expect > 0 {
                                        filehandle!.seek(toFileOffset: UInt64(expect))
                                        index = Int(expect/Int64(partsize))
                                        errorhappen = false
                                        return
                                    }
                                }
                            }
                        }
                        
                        lasterrcode = ret.errcode
                        lasterrmsg = ret.errmsg
                        return
                    }
                    
                    self.pItem.offset = Int64(index * partsize) + Int64(data.count)
                    
                    self.progress()
                    
                    index += 1
                    
                    Thread.sleep(forTimeInterval: 0.5)
                })
                
                if errorhappen {
                    break
                }
                
                if bStop {
                    break
                }
            }
            
            if bStop {
                stophandle(bDelete)
                return
            }
            
            if errorhappen {
                filehandle!.closeFile()
                hostindex +=  1
                self.deleteServerTarget()
                uploadurl = ""
                continue
            }
            
            filehandle!.closeFile()
            
            if !self.upload_finish(host: host) {
                return
            }
            
            if bStop {
                stophandle(bDelete)
                return
            }
            
            self.finish()
            
            break
        }
        
    }
    
    private func getServerTargetPath() -> String {
        let svrname = "upload_\(self.pItem.filehash)_\(self.pItem.uuidhash).gksvr"
        return YKLoginManager.shareInstance.getTransCacheFolder().gkAddLastSlash + svrname
    }
    
    private func getServerTarget() -> String {
        let path = self.getServerTargetPath()
        if !gkutility.fileExist(path: path) { return "" }
        if let s = try? String(contentsOfFile: path) {
            return s
        }
        return ""
    }
    
    private func deleteServerTarget() {
        let path = self.getServerTargetPath()
        if gkutility.fileExist(path: path) {
            gkutility.deleteFile(path: path)
        }
    }
    
    private func saveServerTargte(strUrl: String) {
        let path = self.getServerTargetPath()
        let data = strUrl.data(using: .utf8)
        let _ = gkutility.createFile(path: path, data: data)
    }
    
    private func upload_create() -> Bool {
        let ret = GKHttpEngine.default.createFile(mountid: pItem.mountid, webpath: pItem.webpath, filehash: pItem.filehash, filesize: pItem.filesize, overwrite: pItem.overwrite)
        
        if ret.statuscode != 200 {
            self.failed(errcode: ret.errcode, errmsg: ret.errmsg)
            return false
        }
        
        self.createFileRet = ret
        return true
    }
    
    private func upload_init(host:String) -> (errcode:Int, errmsg:String){
        
        let ret = GKHttpEngine.default.uploadFileInit(host: host, mountid: pItem.mountid, filename: self.pItem.filename.gkUrlEncode, uuidhash: self.pItem.uuidhash, filehash: self.pItem.filehash, filesize: self.pItem.filesize)
        
        if ret.statuscode == 202 {
            return (ret.statuscode,"")
        }
        
        if ret.statuscode != 200 {
            return (ret.statuscode,ret.errmsg)
        }
        
        if let data = ret.data {
            if let dic = data.gkDic {
                if let s = dic["session"] as? String {
                    self.uploadsession = s
                }
            }
        }
        
        if self.uploadsession.isEmpty {
            return (1,"fail to get upload session")
        }
        
        return (ret.statuscode,"")
    }
    
    private func upload_finish(host:String) -> Bool {
        
        let ret = GKHttpEngine.default.uploadFileFinish(host: host, session: uploadsession, filesize: pItem.filesize)
        if ret.statuscode != 200 {
            self.failed(errcode: ret.errcode, errmsg: ret.errmsg)
            return false
        }
        return true
    }
    
    private func failed(errcode: Int, errmsg:String) {
        pItem.errcode = errcode
        pItem.errmsg = errmsg
        pItem.status = .Error
        YKTransfer.shanreInstance.transDB?.updateUploadError(taskID: pItem.nID, offset: pItem.offset, errcode: errcode, errmsg: errmsg)
        YKEventNotify.notify(pItem, type: .uploadFile)
    }
    
    private func finish() {
        self.deleteServerTarget()
        pItem.errcode = 0
        pItem.errmsg = ""
        pItem.status = YKTransStatus.Finish
        YKTransfer.shanreInstance.transDB?.updateUploadFinish(taskID: pItem.nID)
        YKEventNotify.notify(pItem, type: .uploadFile)
        gkutility.deleteFile(path: pItem.localpath)
    }
    
    private func progress() {
        
        let now = Date().timeIntervalSince1970
        if now - refreshTime >= 1.0 {
            YKTransfer.shanreInstance.transDB?.updateUploadStatus(taskID: pItem.nID, status: pItem.status, offset: pItem.offset)
            YKEventNotify.notify(pItem, type: .uploadFile)
            refreshTime = now
        }
    }
    
    func stophandle(_ delete: Bool) {
        if delete {
            YKTransfer.shanreInstance.transDB?.deleteUpload(taskID: pItem.nID)
            pItem.status = .Removed
            gkutility.deleteFile(path: pItem.localpath)
            self.deleteServerTarget()
            YKEventNotify.notify(pItem, type: .uploadFile)
        } else {
            YKTransfer.shanreInstance.transDB?.updateUploadStatus(taskID: pItem.nID, status: .Stop, offset: pItem.offset)
            pItem.status = .Stop
            YKEventNotify.notify(pItem, type: .uploadFile)
        }
    }
    
}
