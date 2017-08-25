//
//  YKUploadManager.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/22.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gkutility

class YKUploadManager {
    
    struct TaskAddItem {
        var mount_id = 0
        var webpath = ""
        var localpath = ""
        var override = false
        var expand: YKTransExpand = .None
    }
    
    var taskLock = gklock()
    var listLock = gklock()
    var tasks = [YKUploadTask]()
    let taskQueue = OperationQueue()
    var uploadItems = [YKUploadItemData]()
    var maxConcurrence = 3
    
    var blockForWWAN = false
    
    var bStop = false
    
    var thread: Thread?
    
    var semaphore = DispatchSemaphore(value: 0)
    
    
    func addTask(mountid:Int,webpath:String,localpath:String, overwrite:Bool = false,expand: YKTransExpand = .None) -> YKUploadItemData {

        let uploadItem = YKTransfer.shanreInstance.transDB!.addUpload(mountid: mountid, webpath: webpath, localpath: localpath, overwrite: overwrite, expand: expand)
        if uploadItem.nID >= 0 {
            let task = YKUploadTask(uploadItem: uploadItem)
            taskLock.lock()
            tasks.append(task)
            taskQueue.addOperation(task)
            taskLock.unlock()
        }
        return uploadItem
    }
    
    
    func addTasks(_ tasks:[TaskAddItem]) -> [YKUploadItemData] {
        
        var result = [YKUploadItemData]()
        taskLock.lock()
        for item in tasks {
            let uploadItem = YKTransfer.shanreInstance.transDB!.addUpload(mountid: item.mount_id, webpath: item.webpath, localpath: item.localpath, overwrite: item.override, expand: item.expand)
            if uploadItem.nID >= 0 {
                let task = YKUploadTask(uploadItem: uploadItem)
                self.tasks.append(task)
                taskQueue.addOperation(task)
                result.append(uploadItem)
            }
        }
        taskLock.unlock()
        return result
    }
    
    
    func start() {
        bStop = false
        uploadItems = [YKUploadItemData]()
        tasks = [YKUploadTask]()
        self.thread = Thread(target: self, selector: #selector(run), object: nil)
        self.thread?.start()
    }
    
    func exit() {
        bStop = true
        //self.deleteAll()
    }
    
    func stopTask(id:Int) {
        taskLock.lock()
        for task in tasks {
            if task.pItem.nID == id {
                task.stop()
                break
            }
        }
        taskLock.unlock()
    }
    
    func deleteTask(id:Int) {
        taskLock.lock()
        for i in 0..<tasks.count {
            let task = self.tasks[i]
            if task.pItem.nID == id {
                task.delete()
                self.tasks.remove(at: i)
                break
            }
        }
        taskLock.unlock()
    }
    
    func stopAll() {
        
        taskLock.lock()
        taskQueue.isSuspended = true
        for t in tasks {
            if t.pItem.status == .Start {
                t.stop()
            }
        }
        taskQueue.cancelAllOperations()
        taskLock.unlock()
    }
    
    func resumeAll() {
        taskLock.lock()
        taskQueue.isSuspended = false
        for t in tasks {
            if t.bStop {
                t.bStop = false
                taskQueue.addOperation(t)
            }
        }
        taskLock.unlock()
    }
    
//    func stopAll() {
//        listLock.lock()
//        uploadItems.removeAll()
//        listLock.unlock()
//        
//        taskLock.lock()
//        for task in tasks {
//            task.stop()
//        }
//        taskLock.unlock()
//    }
//    
//    func deleteAll() {
//        listLock.lock()
//        uploadItems.removeAll()
//        listLock.unlock()
//        
//        taskLock.lock()
//        for task in tasks {
//            task.delete()
//        }
//        taskLock.unlock()
//    }
    
    @objc func run() {
        
        while !bStop {
            
            autoreleasepool(invoking: { () -> Void in
                
                taskLock.lock()
                checkFinishOrError()
                var num = tasks.count
                taskLock.unlock()
                
                while num < maxConcurrence && !bStop && !blockForWWAN {
                    listLock.lock()
                    if uploadItems.isEmpty {
                        if let items = YKTransfer.shanreInstance.transDB?.getUploads() {
                            uploadItems = items
                        }
                    }
                    
                    if !uploadItems.isEmpty {
                        let item = uploadItems[0]
                        if checkIsUploading(uploaditem: item) {
                            uploadItems.remove(at: 0)
                            listLock.unlock()
                            break
                        }
                        
                        if item.nID > 0 && !item.localpath.isEmpty && !item.filehash.isEmpty {
                            let task = YKUploadTask(uploadItem: item)
                            YKTransfer.shanreInstance.transDB?.updateUploadStartActlast(taskID: item.nID)
                            uploadItems.remove(at: 0)
                            listLock.unlock()
                            taskLock.lock()
                            tasks.append(task)
                            taskQueue.addOperation(task)
                            num = tasks.count
                            taskLock.unlock()
                        } else {
                            uploadItems.remove(at: 0)
                            listLock.unlock()
                        }
                        
                    } else {
                        listLock.unlock()
                        break
                    }
                }
                
            })
            
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
    func signal() {
        self.semaphore.signal()
    }
    
    func checkFinishOrError() {
        
        for index in 0..<tasks.count {
            let task = tasks[index]
            if task.bRemoved {
                tasks.remove(at: index)
            }
        }
        
    }
    
    func checkIsUploading(uploaditem:YKUploadItemData) -> Bool {
        var bret = false
        taskLock.lock()
        for task in tasks {
            if task.pItem.filehash == uploaditem.filehash {
                bret = true
                break
            }
        }
        taskLock.unlock()
        return bret
    }

}
