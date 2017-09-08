//
//  YKDownloadManager.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/22.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gkutility
import gknet

class YKDownloadManager : NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    
    var downloadsMap = [String:YKDownloadTask]()
    let lock = gklock()
    
    var taskLock = gklock()
    var tasks = [YKDownloadTask]()
    let taskQueue = OperationQueue()
    var maxConcurrence = 5
    
    var bHandNetChange = false
    
    lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.gokuai.download.session")
        return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }()
    
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(onNetChange(notification:)), name: NSNotification.Name(YKNetChangeNotificationName), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func addTask(file:GKFileDataItem, expand: YKTransExpand = .None) -> YKDownloadItemData {
        
        let convert = YKCommon.needConvertPreview(filename: file.filename)
        let localpath = YKCacheManager.shareManager.cachePath(key: file.filehash, type: (convert ? .Convert : .Original))
        return self.addTask(mountid: file.mount_id, webpath: file.fullpath, filehash: file.filehash, dir: file.dir, filesize: file.filesize, localpath: localpath, convert: convert, hid: nil, expand: expand)
    }
    
    func addTasks(files:[YKFileItemCellWrap],expand: YKTransExpand = .None) {
        
        self.checkFinished()
        
        taskLock.lock()
        for filewarp in files {
            if let file = filewarp.file {
                let convert = YKCommon.needConvertPreview(filename: file.filename)
                let localpath = YKCacheManager.shareManager.cachePath(key: file.filehash, type: (convert ? .Convert : .Original))
                let downloadItem = YKTransfer.shanreInstance.transDB!.addDownload(mountid: file.mount_id, webpath: file.fullpath, filehash: file.filehash, dir: file.dir, filesize:file.filesize, localpath: localpath, convert: convert, hid: nil, net: nil, expand: expand)
                
                if downloadItem.nID >= 0 {
                    let task = YKDownloadTask(downloadItem: downloadItem)
                    tasks.append(task)
                    taskQueue.addOperation(task)
                    filewarp.downloadItem = downloadItem
                }
            }
        }
        taskLock.unlock()
    }
    
    func addTask(mountid:Int,webpath:String,filehash:String,dir:Bool,filesize:Int64,localpath:String, convert:Bool, hid:String? = nil, expand: YKTransExpand = .None) -> YKDownloadItemData {
        
        self.checkFinished()
        
        let downloadItem = YKTransfer.shanreInstance.transDB!.addDownload(mountid: mountid, webpath: webpath, filehash: filehash, dir: dir, filesize:filesize, localpath: localpath, convert: convert, hid: hid, net: nil, expand: expand)
        if downloadItem.nID >= 0 {
            let task = YKDownloadTask(downloadItem: downloadItem)
            taskLock.lock()
            tasks.append(task)
            taskQueue.addOperation(task)
            taskLock.unlock()
        }
        return downloadItem
    }
    
    func onNetChange(notification: Notification) {
        
        if self.tasks.isEmpty {
            return
        }
        
        if bHandNetChange {
            return
        }
        
        if let o = notification.object as? (old:YKNetMonitor.Status,new:YKNetMonitor.Status) {
            if o.new == .WWAN {
                bHandNetChange = true
                
                var totalSize: Int64 = 0
                for t in self.tasks {
                    totalSize += t.pItem.filesize
                }
                if totalSize > YKAlertSizeWWAN {
                    self.stopAll()
                    
                    let rootvc = UIApplication.shared.keyWindow?.rootViewController
                    let msg = YKLocalizedString("当前处于移动网络, 继续下载将产生\(gkutility.formatSize(size: totalSize))的流量, 是否继续")
                    YKAlert.showAlert(message: msg, okTitle: YKLocalizedString("继续"), okBlock: { () in
                        self.resumeAll()
                        self.bHandNetChange = false
                    }, cancelBlock: { () in
                        self.bHandNetChange = false
                    }, vc: rootvc)
                } else {
                    bHandNetChange = false
                }
            }
        }
        
    }
    
    func stopTask(id:Int) {
        taskLock.lock()
        for i in 0..<self.tasks.count {
            let task = self.tasks[i]
            if task.pItem.nID == id {
                task.cancel()
                if task.pItem.status == .Start {
                    task.stop()
                } else if task.pItem.status == .Normal {
                    task.stophandle(false)
                }
                self.tasks.remove(at: i)
                break
            }
        }
        taskLock.unlock()
    }
    
    
    func resumeTask(id:Int) {
        taskLock.lock()
        if let ditem = YKTransfer.shanreInstance.transDB?.getDownloadItemBy(id: id) {
            YKTransfer.shanreInstance.transDB?.updateDownloadStatus(taskID: id, status: .Normal, offset: nil)
            let task = YKDownloadTask(downloadItem: ditem)
            self.tasks.append(task)
            taskQueue.addOperation(task)
        }
        taskLock.unlock()
    }
    
    func deleteTask(id:Int) {
        taskLock.lock()
        var bhave = false
        for i in 0..<tasks.count {
            let task = self.tasks[i]
            if task.pItem.nID == id {
                bhave = true
                task.cancel()
                if task.pItem.status == .Start {
                    task.delete()
                } else {
                    task.stophandle(true)
                }
                self.tasks.remove(at: i)
                break
            }
        }
        taskLock.unlock()
        
        if !bhave {
            if let ditem = YKTransfer.shanreInstance.transDB?.getDownloadItemBy(id: id) {
                YKTransfer.shanreInstance.transDB?.deleteDownload(taskID: ditem.nID)
                ditem.status = .Removed
                YKEventNotify.notify(ditem, type: .downloadFile)
            }
        }
    }
    
    func stopAll() {
        
        taskLock.lock()
        taskQueue.cancelAllOperations()
        YKTransfer.shanreInstance.transDB?.updateDownloadsToStop()
        for t in tasks {
            if t.pItem.status == .Start {
                t.stop()
            }
        }
        self.tasks.removeAll()
        taskLock.unlock()
    }
    
    func resumeAll() {
        
        if let stoptasks = YKTransfer.shanreInstance.transDB?.getStopDownloads() {
            taskLock.lock()
            for item in stoptasks {
                let task = YKDownloadTask(downloadItem: item)
                self.tasks.append(task)
                taskQueue.addOperation(task)
            }
            taskLock.unlock()
        }
    }
    
    
    func deleteAll() {
        
        taskLock.lock()
        taskQueue.cancelAllOperations()
        for t in tasks {
            if t.pItem.status == .Finish {
                continue
            }
            if t.pItem.status == .Start {
                t.delete()
            } else {
                t.stophandle(true)
            }
        }
        self.tasks.removeAll()
        taskLock.unlock()
        
    }
    
    
    func finishByFilehash(_ filehash: String) {
        if !tasks.isEmpty {
            self.taskLock.lock()
            var removes = [Int]()
            for index in 0..<tasks.count {
                let task = tasks[index]
                if task.pItem.filehash == filehash && !task.pItem.convert {
                    task.finshByOthers = true
                    task.cancel()
                    removes.append(index)
                }
            }
            if !removes.isEmpty {
                self.tasks.gkRemove(at: removes)
            }
            self.taskLock.unlock()
        }
    }
    
    func checkIsDownloading(filehash: String, convert: Bool) -> Bool {
        var ret = false
        self.taskLock.lock()
        for t in self.tasks {
            if t.pItem.filehash == filehash && t.pItem.convert == convert {
                ret = true
                break
            }
        }
        self.taskLock.unlock()
        return ret
    }
    
    func checkFinished() {
        
        if !tasks.isEmpty {
            self.taskLock.lock()
            var removes = [Int]()
            for index in 0..<tasks.count {
                let task = tasks[index]
                if task.pItem.status == .Finish {
                    removes.append(index)
                }
            }
            if !removes.isEmpty {
                self.tasks.gkRemove(at: removes)
            }
            self.taskLock.unlock()
        }
    }
    
    func getSessionDownloadTask(task: YKDownloadTask, strurl: String) -> URLSessionDownloadTask? {
        
        guard let url = URL(string: strurl) else {
            return nil
        }
        
        let resumePath = task.resumePath
        var resumeData: Data? = nil
        if gkutility.fileExist(path: resumePath) {
            let lastModify = gkutility.fileModifyTime(path: resumePath)
            if Date().timeIntervalSince1970 - lastModify < 60*9 {
                resumeData = try? Data(contentsOf: URL(fileURLWithPath: resumePath))
            }
        }
        
        if resumeData == nil || resumeData!.isEmpty {
            gkutility.deleteFile(path: resumePath)
            resumeData = nil
        }
        
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        req.httpMethod = "GET"
        req.httpShouldHandleCookies = false
        
        let dtask: URLSessionDownloadTask
        
        if resumeData != nil && !resumeData!.isEmpty {
            dtask = self.session.downloadTask(withResumeData: resumeData!)
        } else {
            dtask = self.session.downloadTask(with: req)
        }
        
        self.lock.lock()
        self.downloadsMap["\(dtask.taskIdentifier)"] = task
        self.lock.unlock()
        
        return dtask
        
    }
    
    //MARK: URLSessionDelegate
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("_1")
        self.lock.lock()
        let ptask = self.downloadsMap["\(task.taskIdentifier)"]
        if ptask != nil {
            let resumePath = ptask!.resumePath
            if error != nil {
                ptask!.didFinishDownloadingTo(error: error, location: nil)
                
                if let e = error as NSError? {
                    if let resumedata = e.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                        if !resumedata.isEmpty && !resumePath.isEmpty {
                            try? resumedata.write(to: URL(fileURLWithPath: resumePath))
                        }
                    }
                }
            } else {
                if !resumePath.isEmpty {
                    gkutility.deleteFile(path: resumePath)
                }
            }
            self.downloadsMap.removeValue(forKey: "\(task.taskIdentifier)")
            self.lock.unlock()
        } else {
            self.lock.unlock()
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        self.lock.lock()
        let ptask = self.downloadsMap["\(downloadTask.taskIdentifier)"]
        self.lock.unlock()
        if ptask != nil {
            ptask!.didFinishDownloadingTo(error: nil, location: location)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
        print("resume: \(fileOffset) - \(expectedTotalBytes)")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        self.lock.lock()
        let ptask = self.downloadsMap["\(downloadTask.taskIdentifier)"]
        self.lock.unlock()
        if ptask != nil {
            ptask!.urlSession(session, downloadTask: downloadTask, didWriteData: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        }
    }
}
