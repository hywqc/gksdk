//
//  YKDownloadTask.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/22.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gkutility
import gknet
import SocketIO

class YKDownloadTask : Operation {
    
    var pItem: YKDownloadItemData!
    var bStop = false
    var bRemoved = false
    var bDelete = false
    
    var finshByOthers = false
    
    var resumePath = ""
    
    var convertSemaphore: DispatchSemaphore?
    var waitingConvert = false
    
    var downloadTask: URLSessionDownloadTask?
    
    var socketIO: SocketIOClient?
    
    var refreshTime: TimeInterval = 0
    
    private enum InitRet{
        case Null
        case OK
        case Error
    }
    
    init(downloadItem: YKDownloadItemData) {
        self.pItem = YKDownloadItemData()
        pItem.nID = downloadItem.nID
        pItem.mountid = downloadItem.mountid
        pItem.dir = downloadItem.dir
        pItem.webpath = downloadItem.webpath
        pItem.parent = downloadItem.parent
        pItem.filename = downloadItem.filename
        pItem.filehash = downloadItem.filehash
        pItem.uuidhash = downloadItem.uuidhash
        pItem.filesize = downloadItem.filesize
        pItem.localpath = downloadItem.localpath
        pItem.offset = downloadItem.offset
        pItem.status = downloadItem.status
        pItem.errcode = downloadItem.errcode
        pItem.errcount = downloadItem.errcount
        pItem.errmsg = downloadItem.errmsg
        pItem.expand = downloadItem.expand
        pItem.hid = downloadItem.hid
        pItem.net = downloadItem.net
        pItem.convert = downloadItem.convert
        
        if !pItem.convert {
            var p = YKLoginManager.shareInstance.getTransCacheFolder().gkAddLastSlash
            p.append("download_\(pItem.filehash).rsm")
            self.resumePath = p
        }
    }
    
    
    func stop() {
        bStop = true
        bDelete = false
        if waitingConvert {
            if self.convertSemaphore != nil {
                self.convertSemaphore!.signal()
            }
        }
        
        if pItem.convert {
            self.downloadTask?.cancel()
        } else {
            self.downloadTask?.cancel(byProducingResumeData: { (resumeData:Data?) in
                
            })
        }
        
    }
    
    func delete() {
        bStop = true
        bDelete = true
        if waitingConvert {
            if self.convertSemaphore != nil {
                self.convertSemaphore!.signal()
            }
        }
        
        self.downloadTask?.cancel()
    }
    
    override func main() {
        
        print("start download")
        
        self.pItem.status = .Start
        YKTransfer.shanreInstance.transDB?.updateDownloadStartActlast(taskID: self.pItem.nID)
        //YKEventNotify.notify(self.pItem, type: .downloadFile)
        
        let initRet = self.initDownload()
        
        if initRet != .OK {
            return
        }
        
        if bStop {
            self.stophandle(bDelete)
            return
        }
        
        if self.finshByOthers {
            self.finish()
            return
        }
        
        let retUrl = GKHttpEngine.default.getFileDownloadUrl(mountID: pItem.mountid, filehash: pItem.filehash)
        if retUrl.statuscode != 200 {
            self.failed(errcode: retUrl.errcode, errmsg: retUrl.errmsg)
            return
        }
        
        if self.finshByOthers {
            self.finish()
            return
        }
        
        if bStop {
            self.stophandle(bDelete)
            return
        }
        
        if retUrl.urls.isEmpty {
            self.failed(errcode: 1, errmsg: "the download url is empty")
            return
        }
        
        let fsize = retUrl.filesize
        var downloadurl = retUrl.urls[0]
        
        if fsize == 0 {
            self.finish()
            return
        }
        
        self.pItem.filesize = fsize
        YKTransfer.shanreInstance.transDB?.updateDownloadFilesize(taskID: pItem.nID, filesize: fsize)
        
        if pItem.convert {
            
            let convertRet = self.getUrlForConvert(url: downloadurl)
            
            if bStop {
                self.stophandle(bDelete)
                return
            }
            
            if self.finshByOthers {
                self.finish()
                return
            }
            
            if convertRet != nil {
                if let url = convertRet?.url {
                    downloadurl = url
                } else {
                    self.failed(errcode: convertRet!.status.errcode, errmsg: convertRet!.status.errmsg)
                    return
                }
            }
            
        }
        
        if self.finshByOthers {
            self.finish()
            return
        }
        self.downloadWithUrl(downloadurl)
        
    }
    
    private func getUrlForConvert(url:String) -> (status:(errcode:Int,errmsg:String),url:String?)? {
        
        let retServer = GKHttpEngine.default.getServerSite(type: "m-doc")
        
        if bStop {
            return nil
        }
        
        if retServer.statuscode != 200 {
            return ((retServer.errcode,retServer.errmsg),nil)
        }
        
        if retServer.servers.isEmpty {
            return ((1,"fail to get convert host"),nil)
        }
        
        let convertHost = retServer.servers[0]
        
        var convertParam = ["url":url,
                            "filehash":pItem.filehash,
                            "ext":pItem.filename.gkExt]
        convertParam["sign"] = convertParam.gkSign(key: convertHost.sign, urlencode: false)
        
        let convertUrl = convertHost.fullurl(usehttps: true, hostin: false,withpath: false)
        
        let bhttps = true
        
        var sioconfig: SocketIOClientConfiguration = [SocketIOClientOption.forceWebsockets(true),
                                                      SocketIOClientOption.connectParams(convertParam),
                                                      SocketIOClientOption.log(false),
                                                      SocketIOClientOption.secure(bhttps)]
        if !convertHost.path.isEmpty {
            var siopath = convertHost.path
            if !siopath.hasPrefix("/") {
                siopath = "/" + siopath
            }
            siopath += "/socket.io/"
            sioconfig.insert(SocketIOClientOption.path(siopath))
        }
        
        if bStop {
            return nil
        }
        
        var convertErrmsg: String? = nil
        var resultUrl: String? = nil
        
        if let siourl = URL(string: convertUrl) {
            let sio = SocketIOClient(socketURL: siourl, config: sioconfig)
            sio.on("progress", callback: { [weak self] (data:[Any], emitter:SocketAckEmitter) in
                if self == nil {
                    return
                }
                if data.isEmpty {
                    return
                }
                
                if let item = data.first as? [AnyHashable:Any] {
                    let progress = gkSafeInt(dic: item, key: "progress")
                    if progress >= 100 {
                        let returl = gkSafeString(dic: item, key: "url")
                        resultUrl = returl
                        self?.convertSemaphore?.signal()
                    }
                }
            })
            
            sio.on("err", callback: { [weak self] (data:[Any], emitter:SocketAckEmitter) in
                if self == nil {
                    return
                }
                if data.isEmpty {
                    return
                }
                
                if let item = data.first as? [AnyHashable:Any] {
                    let emsg = gkSafeString(dic: item, key: "error_msg")
                    if !emsg.isEmpty {
                        convertErrmsg = emsg
                    } else {
                        convertErrmsg = "fail to convert \(url)"
                    }
                }
                self?.convertSemaphore?.signal()
            })
            
            self.socketIO = sio
            
            
            self.convertSemaphore = DispatchSemaphore(value: 0)
            sio.connect()
            
            self.waitingConvert = true
            let waitRet = self.convertSemaphore!.wait(timeout: DispatchTime.now() + DispatchTimeInterval.seconds(60) )
            
            if waitRet == .timedOut {
                convertErrmsg = "convert timeout \(url)"
            }
            self.waitingConvert = false
            
            self.socketIO?.disconnect()
            self.socketIO = nil
            
            if convertErrmsg != nil {
                return ((1,convertErrmsg!),nil)
            }
            
            return ((200,""),resultUrl)
            
        } else {
            
            return ((1,"invalid convert url"),nil)
            
        }
        
    }
    
    private func downloadWithUrl(_ url:String) {
        
        self.downloadTask = YKTransfer.shanreInstance.downloadManager.getSessionDownloadTask(task: self, strurl: url)
        if self.downloadTask != nil {
            self.downloadTask!.resume()
        }
    }
    
    private func initDownload() -> InitRet {
        
        if pItem.dir {
            let _ = gkutility.createDir(path: pItem.localpath)
            self.finish()
            return .Null
        } else if pItem.filehash.isEmpty {
            self.failed(errcode: 1, errmsg: "invalid filehash")
            return .Error
        }
        
        
//        if let cachepath = YKCacheManager.shareManager.checkCache(key: pItem.filehash) {
//            try? fm.copyItem(atPath: cachepath, toPath: pItem.localpath)
//            if gkutility.fileExist(path: pItem.localpath) {
//                self.finish()
//                return .Null
//            } else {
//                self.failed(errcode: 1, errmsg: "copy cached failed")
//                return .Error
//            }
//        }
        
        return .OK
    }
    
    private func progress() {
        let now = Date().timeIntervalSince1970
        if now - refreshTime >= 1.0 {
            YKTransfer.shanreInstance.transDB?.updateDownloadStatus(taskID: pItem.nID, status: pItem.status, offset: pItem.offset)
            YKEventNotify.notify(pItem, type: .downloadFile)
            refreshTime = now
        }
    }
    
    private func finish() {
        pItem.errcode = 0
        pItem.errmsg = ""
        pItem.status = YKTransStatus.Finish
        gkutility.deleteFile(path: self.resumePath)
        self.downloadTask = nil
        YKTransfer.shanreInstance.transDB?.updateDownloadFinish(taskID: pItem.nID)
        YKEventNotify.notify(pItem, type: .downloadFile)
        print("download finish")
        
        YKTransfer.shanreInstance.downloadManager.finishByFilehash(pItem.filehash)
    }
    
    private func failed(errcode: Int, errmsg:String) {
        pItem.errcode = errcode
        pItem.errmsg = errmsg
        pItem.status = .Error
        YKTransfer.shanreInstance.transDB?.updateDownloadError(taskID: pItem.nID, offset: pItem.offset, errcode: errcode, errmsg: errmsg)
        YKEventNotify.notify(pItem, type: .downloadFile)
    }
    
    func stophandle(_ delete: Bool) {
        if delete {
            YKTransfer.shanreInstance.transDB?.deleteDownload(taskID: pItem.nID)
            pItem.status = .Removed
            gkutility.deleteFile(path: pItem.localpath)
            YKEventNotify.notify(pItem, type: .downloadFile)
        } else {
            YKTransfer.shanreInstance.transDB?.updateDownloadStatus(taskID: pItem.nID, status: .Stop, offset: pItem.offset)
            pItem.status = .Stop
            YKEventNotify.notify(pItem, type: .downloadFile)
        }
    }
    
    
    func didFinishDownloadingTo(error: Error?, location: URL?) {
        
        print("_2")
        if error == nil {
            if self.bStop {
                self.stophandle(bDelete)
                return
            }
            if location != nil {
                
                gkutility.deleteFile(path: pItem.localpath)
                do {
                    try FileManager.default.copyItem(at: location!, to: URL(fileURLWithPath: pItem.localpath))
                } catch {
                    
                    self.failed(errcode: 1, errmsg: "copy file error")
                    return
                }
                
                let cachepath = YKCacheManager.shareManager.cachePath(key: pItem.filehash, type: (pItem.convert ? .Convert : .Original))
                if cachepath != pItem.localpath {
                    YKCacheManager.shareManager.addToCache(pItem.localpath, key: pItem.filehash, type: (pItem.convert ? .Convert : .Original), replace: true)
                }
                
                if !pItem.convert {
                    let fhash = gkutility.getfilehash(path: pItem.localpath)
                    if fhash != pItem.filehash {
                        self.failed(errcode: 1, errmsg: "filehash not match")
                        return
                    }
                }
                
            }
            self.finish()
        } else {
            if self.finshByOthers {
                self.finish()
                return
            }
            if bStop {
                self.stophandle(bDelete)
                return
            }
            var ecode = 1
            let emsg = error!.localizedDescription
            if let ne = error as NSError? {
                ecode = ne.code
            }
            self.failed(errcode: ecode, errmsg: emsg)
        }
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if self.bStop { return }
        
        if self.finshByOthers {
            downloadTask.cancel()
            return
        }
        
        self.pItem.offset = totalBytesWritten
        self.progress()
    }
}
