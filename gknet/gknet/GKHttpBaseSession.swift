//
//  GKHttpBaseSession.swift
//  gknet
//
//  Created by wqc on 2017/7/25.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gkutility

public typealias GKRequestID = Int64
public typealias GKRequestCallback = (GKRequestBaseRet)->Void
public typealias GKRequestLogger = (GKRequestBaseRet)->Void

fileprivate let kGET = "GET"
fileprivate let kPOST = "POST"
fileprivate let kPUT = "PUT"

class TaskCallback {
    weak var session: GKHttpBaseSession?
    var taskid: GKRequestID = 0
    var responseData: GKRequestBaseRet
    let completion: GKRequestCallback?
    let sync: Bool
    private var semaphore: DispatchSemaphore?
    
    required init(session: GKHttpBaseSession, reqType: GKRequestBaseRet.Type?, sync: Bool, completion: GKRequestCallback? ) {
        self.session = session
        self.sync = sync
        self.completion = completion
        let theType = reqType ?? GKRequestBaseRet.self
        self.responseData = GKRequestBaseRet.create(theType)
        if sync {
            self.semaphore = DispatchSemaphore.init(value: 0)
        }
    }
    
    func wait() {
        let _ = self.semaphore?.wait(timeout: .distantFuture)
    }
    
    func resume() {
        let _ = self.semaphore?.signal()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if let localError = error {
            responseData.statuscode = 2
            let ne = error as NSError?
            if ne != nil {
                responseData.statuscode = ne!.code
            }
            responseData.errcode = responseData.statuscode
            responseData.errmsg = localError.localizedDescription
        } else {
            
            if let res = responseData.response {
                responseData.statuscode = res.statusCode
                if res.statusCode != 200 {
                    responseData.parseError()
                }
            } else {
                responseData.statuscode = 1
                responseData.parseError()
            }
        }
        
        if responseData.statuscode != 200 || responseData.errcode != 0{
            responseData.url = (task.currentRequest?.url?.absoluteString) ?? ""
            self.session?.errorLog?(responseData)
        }
        
        if sync {
            self.resume()
        } else {
            self.responseData.parse()
            completion?(self.responseData)
        }
    }
    
}

public class GKHttpBaseSession : NSObject,URLSessionDelegate,URLSessionDataDelegate {
    
    private lazy var session: URLSession = {
        return URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: self.queue)
    }()
    private var queue: OperationQueue
    private let name: String?
    private var map: [String:Any]
    private let lock = gklock()
    private let timeout: Double
    
    var errorLog: GKRequestLogger? = nil
    
    public init(_ name: String? = nil, timeout: Double = 30.0) {
        self.name = name
        self.timeout = timeout
        self.queue = OperationQueue()
        self.map = [String:Any]()
        super.init()
    }
    
    func applyDefaultHeaders(req: URLRequest?) {
        if req == nil { return }
    }
    
    private func reqForMethod(url: String, method: String, headers: [String:String]?, params: [String:String]?, reqType: GKRequestBaseRet.Type?) -> AnyObject {
        
        var formaturl = url
        
        var query: String = ""
        if let p = params {
            query = p.gkQuery()
        }
        
        if !query.isEmpty {
            if method == kGET {
                formaturl = "\(url)?\(query)"
            }
        }
        
        let u = URL(string:formaturl)
        if u == nil {
            
            var ret = GKRequestBaseRet()
            if reqType != nil {
                ret = GKRequestBaseRet.create(reqType!)
            }
            ret.errmsg = "invalid url"
            ret.errcode = 1
            ret.statuscode = 1
            ret.url = url
            self.errorLog?(ret)
            return ret
        } else {
            var req = URLRequest(url: u!)
            req.httpMethod = method
            req.timeoutInterval = self.timeout
            req.cachePolicy = .reloadIgnoringLocalCacheData
            req.httpShouldHandleCookies = false
            
            if !query.isEmpty {
                if method == kPOST || method == kPUT {
                    req.httpBody = query.data(using: .utf8)
                }
            }
            
            self.applyDefaultHeaders(req: req)
            
            if let h = headers {
                for (k,v) in h {
                    req.allHTTPHeaderFields?.updateValue(v, forKey: k)
                }
            }
            
            return req as AnyObject;
        }
        
    }
    
    func taskWithRequest(req: URLRequest, reqType: GKRequestBaseRet.Type?, sync: Bool, completion: GKRequestCallback?) -> TaskCallback {
        
        let task = self.session.dataTask(with: req)
        let proxy = TaskCallback(session: self, reqType: reqType, sync: sync, completion: completion)
        proxy.taskid = GKRequestID(task.taskIdentifier)
        self.map["\(proxy.taskid)"] = proxy
        task.resume()
        return proxy
    }
    
    
    public func Fetch(method: String, url: String, headers: [String:String]?, param: [String:String]?, reqType: GKRequestBaseRet.Type?) -> GKRequestBaseRet {
        
        let ret = reqForMethod(url: url, method: method, headers: headers, params: param, reqType: reqType)
        if ret is GKRequestBaseRet {
            
            let reqret = ret as! GKRequestBaseRet
            return reqret
            
        } else {
            
            let req = ret as! URLRequest
            let proxy = taskWithRequest(req: req, reqType: reqType, sync: true, completion: nil)
            
            proxy.wait()
            
            proxy.responseData.parse()
            
            return proxy.responseData
        }
    }
    
    private func Fetch(method: String, url: String, headers: [String:String]?, param: [String:String]?, completion: GKRequestCallback?, reqType: GKRequestBaseRet.Type?) -> GKRequestID {
        
        let ret = reqForMethod(url: url, method: kGET, headers: headers, params: param, reqType: reqType)
        if ret is GKRequestBaseRet {
            let reqret = ret as! GKRequestBaseRet
            completion?(reqret)
            return 0
        } else {
            let req = ret as! URLRequest
            let proxy = taskWithRequest(req: req, reqType: reqType, sync: false, completion: completion)
            
            return proxy.taskid
        }
        
    }
    
    
    public func GET(url: String, headers: [String:String]?, param: [String:String]?, reqType: GKRequestBaseRet.Type?) -> GKRequestBaseRet {
        
        return Fetch(method: kGET, url: url, headers: headers, param: param, reqType: reqType)
    }
    
    public func GET(url: String, headers: [String:String]?, param: [String:String]?, completion: GKRequestCallback?, reqType: GKRequestBaseRet.Type?) -> GKRequestID {
        
        return Fetch(method: kGET, url: url, headers: headers, param: param, completion: completion, reqType: reqType)
        
    }
    
    public func POST(url: String, headers: [String:String]?, param: [String:String]?,reqType: GKRequestBaseRet.Type?) -> GKRequestBaseRet {
        
        return Fetch(method: kPOST, url: url, headers: headers, param: param, reqType: reqType)
    }
    
    public func POST(url: String, headers: [String:String]?, param: [String:String]?, completion: GKRequestCallback?, reqType: GKRequestBaseRet.Type?) -> GKRequestID {
        
        return Fetch(method: kPOST, url: url, headers: headers, param: param, completion: completion, reqType: reqType)
    }
    
    
    public func PUT(url: String, headers: [String:String]?, param: [String:String]?, reqType: GKRequestBaseRet.Type?) -> GKRequestBaseRet {
        
        return Fetch(method: kPUT, url: url, headers: headers, param: param, reqType: reqType)
    }
    
    public func PUT(url: String, headers: [String:String]?, param: [String:String]?, completion: GKRequestCallback?, reqType: GKRequestBaseRet.Type?) -> GKRequestID {
        
        return Fetch(method: kPUT, url: url, headers: headers, param: param, completion: completion, reqType: reqType)
    }
    
    
    public func cancelTask(_ taskID: GKRequestID) {
        if #available(iOS 9.0, *) {
            self.session.getAllTasks { (tasks: [URLSessionTask]) in
                for task in tasks {
                    if Int64(task.taskIdentifier) == taskID {
                        task.cancel()
                        break
                    }
                }
            }
        } else {
            self.session.getTasksWithCompletionHandler({ (dataTasks:[URLSessionDataTask], uploadTasks:[URLSessionUploadTask], downloadTasks: [URLSessionDownloadTask]) in
                for task in dataTasks {
                    if Int64(task.taskIdentifier) == taskID {
                        task.cancel()
                        break
                    }
                }
            })
        }
    }
    
    public func cancelAll() {
        if #available(iOS 9.0, *) {
            self.session.getAllTasks(completionHandler: { (tasks: [URLSessionTask]) in
                for task in tasks {
                    task.cancel()
                }
            })
        } else {
            self.session.getTasksWithCompletionHandler({ (dataTasks:[URLSessionDataTask], uploadTasks:[URLSessionUploadTask], downloadTasks: [URLSessionDownloadTask]) in
                for task in dataTasks {
                    task.cancel()
                }
            })
        }
    }
    
    
    //MARK: 
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if let proxy = self.map["\(task.taskIdentifier)"] as? TaskCallback {
            proxy.urlSession(session, task: task, didCompleteWithError: error)
        }
        self.map.removeValue(forKey: "\(task.taskIdentifier)")
    }
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        if let proxy = self.map["\(dataTask.taskIdentifier)"] as? TaskCallback {
            proxy.responseData.response = response as? HTTPURLResponse
        }
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        if let proxy = self.map["\(dataTask.taskIdentifier)"] as? TaskCallback {
            proxy.responseData.data?.append(data)
        }
    }
    
}
