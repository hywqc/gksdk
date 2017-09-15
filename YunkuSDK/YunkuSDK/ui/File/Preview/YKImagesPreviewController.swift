//
//  YKImagesPreviewController.swift
//  YunkuSDK
//
//  Created by wqc on 2017/9/1.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gknet
import gkutility


class YKImageFecther : NSObject, URLSessionDelegate,URLSessionDataDelegate {
    
    static let shanreInstance = YKImageFecther()
    
    lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        let s = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
        return s
    }()
    
    class Task {
        var url = ""
        var downID = 0
        var progressBlock: ((Int64,Int64)->Void)?
        var completionBlock: ((UIImage?,Error?)->Void)?
        var progressTime: TimeInterval = 0
        var cachePath = ""
        var response: HTTPURLResponse?
        var data = Data()
        var filesize: Int64 = 0
    }
    
    var tasks = [Task]()
    let lock = gklock()
    
    func addTask(_ task: Task) {
        if let url = URL(string: task.url) {
            self.lock.lock()
            self.tasks.append(task)
            var req = URLRequest(url: url)
            req.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            req.httpShouldHandleCookies = false
            let downtask = self.session.dataTask(with: req)
            task.downID = downtask.taskIdentifier
            self.lock.unlock()
            downtask.resume()
        }
    }
    
    func getTask(downID: Int) -> Task? {
        self.lock.lock()
        for t in self.tasks {
            if t.downID == downID {
                self.lock.unlock()
                return t
            }
        }
        self.lock.unlock()
        return nil
    }
    
    func deleteTask(downID: Int) {
        self.lock.lock()
        for i in 0..<self.tasks.count {
            let t = self.tasks[i]
            if t.downID == downID {
                self.tasks.remove(at: i)
                self.lock.unlock()
                return
            }
        }
        self.lock.unlock()
    }
    
    func stopAll() {
        self.session.getTasksWithCompletionHandler { (_ :[URLSessionDataTask], _ :[URLSessionUploadTask], downTask: [URLSessionDownloadTask]) in
            for t in downTask {
                t.cancel()
            }
        }
        self.lock.lock()
        self.tasks.removeAll()
        self.lock.unlock()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if let ptask = self.getTask(downID: task.taskIdentifier) {
            var img: UIImage?
            if error == nil {
                img = UIImage(data: ptask.data)
                if img != nil {
                    do {
                        gkutility.deleteFile(path: ptask.cachePath)
                        try ptask.data.write(to: URL(fileURLWithPath: ptask.cachePath))
                    } catch  {
                        
                    }
                    
                }
            }
            ptask.completionBlock?(img,error)
            self.deleteTask(downID: task.taskIdentifier)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        if let ptask = self.getTask(downID: dataTask.taskIdentifier) {
            if let res = response as? HTTPURLResponse {
                ptask.response = res
                if res.statusCode != 200 {
                    completionHandler(.cancel)
                    return
                }
                
                let fields = res.allHeaderFields
                if let strlen = fields["Content-Length"] as? String {
                    if let len = Int64(strlen) {
                        ptask.filesize = len
                    }
                }
            }
        }
        
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let ptask = self.getTask(downID: dataTask.taskIdentifier) {
            ptask.data.append(data)
            let now = Date().timeIntervalSince1970
            if now - ptask.progressTime > 0.3 {
                ptask.progressBlock!(Int64(ptask.data.count),ptask.filesize)
                ptask.progressTime = now
            }
        }
    }
    
}

class YKImagePreView : UIView {
    
    var fileItem: GKFileDataItem!
    
    var imageView: UIImageView!
    var progressView: YKRoundProgressView!
    
    var errorInfo: UILabel!
    var retryBtn: UIButton!
    
    var isLoading = false
    
    var task: YKImageFecther.Task?
    
    init(frame: CGRect, file:GKFileDataItem) {
        self.fileItem = file
        super.init(frame: frame)
        self.backgroundColor = UIColor.black
        
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        imageView.isHidden = true
        self.addSubview(imageView)
        
        progressView = YKRoundProgressView(frame: CGRect(x: (self.bounds.size.width-44)/2, y: (self.bounds.size.height-44)/2, width: 44, height: 44))
        self.addSubview(progressView)
        
        let label = UILabel(frame: CGRect.zero)
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.font = YKFont.make(13)
        label.isHidden = true
        self.addSubview(label)
        self.errorInfo = label
        
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 35)
        button.setTitle(YKString.kYKRetry, for: .normal)
        button.titleLabel?.font = YKFont.make(13)
        button.setTitleColor(UIColor.white, for: .normal)
        button.isHidden = true
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.cornerRadius = 3
        
        self.addSubview(button)
        self.retryBtn = button
        button.addTarget(self, action: #selector(onBtnRetry), for: .touchUpInside)
    }
    
    func onBtnRetry() {
        self.isLoading = false
        self.progressView.progress = 0
        self.progressView.isHidden = false
        self.errorInfo.isHidden = true
        self.retryBtn.isHidden = true
        self.start()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.progressView.frame = CGRect(x: (self.bounds.size.width-self.progressView.frame.size.width)/2, y: (self.bounds.size.height-self.progressView.frame.size.height)/2, width: self.progressView.frame.size.width, height: self.progressView.frame.size.height)
        self.errorInfo.frame = CGRect(x: 20, y: (self.bounds.size.height-70)/2, width: self.bounds.size.width-40, height: 20)
        self.retryBtn.frame = CGRect(x: (self.bounds.size.width-100)/2, y: self.errorInfo.frame.maxY+10, width: 100, height: 35)
    }
    
    func start() {
        let webhost = YKClient.shareInstance.serverInfo.fullWebURL(path: "")
        let fullurl = fileItem.thumb(webhost: webhost, big: true)
        let cache = YKCacheManager.shareManager.cachePath(key: fileItem.filehash, type: .Original)
        if gkutility.fileExist(path: cache) {
            if let img = UIImage(contentsOfFile: cache) {
                self.imageView.image = img
                self.progressView.isHidden = true
                self.imageView.isHidden = false
                self.isLoading = false
                return
            }
        }
        self.load(url: fullurl,original: false)
    }
    
    func load(url:String,original:Bool) {
        if isLoading { return }
        isLoading = true
        
        let mountid = fileItem.mount_id
        let file_hash = fileItem.filehash
        
        let cache = YKCacheManager.shareManager.cachePath(key: file_hash, type: .Original)
        let task = YKImageFecther.Task()
        task.cachePath = cache
        task.url = url
        task.progressBlock = { [weak self] (receivedSize: Int64, expectedSize:Int64) in
            DispatchQueue.main.async {
                self?.progressView.progress = Float(receivedSize)/Float(expectedSize)
            }
        }
        
        task.completionBlock = { [weak self] (image:UIImage?,error:Error?) in
            DispatchQueue.main.async {
                self?.isLoading = false
                if error == nil && image != nil {
                    self?.imageView.image = image
                    self?.progressView.isHidden = true
                    self?.imageView.isHidden = false
                } else {
                    if original {
                        self?.showError()
                    } else {
                        DispatchQueue.global().async {
                            let ret = GKHttpEngine.default.getFileDownloadUrl(mountID: mountid, filehash: file_hash)
                            if ret.statuscode == 200 && !ret.urls.isEmpty {
                                self?.load(url: ret.urls[0], original: true)
                            } else {
                                DispatchQueue.main.async {
                                   self?.showError()
                                }
                            }
                        }
                    }
                    
                }
            }
        }
        
        self.task = task
        YKImageFecther.shanreInstance.addTask(task)
    }
    
    func showError() {
        var errmsg = YKLocalizedString("加载失败")
        if let t = self.task {
            if t.response != nil {
                if t.response!.statusCode == 404 {
                    errmsg = YKLocalizedString("资源不存在")
                }
            }
            if !t.data.isEmpty {
                if let dic = (t.data).gkDic {
                    let s = gkSafeString(dic: dic, key: "error_msg")
                    if !s.isEmpty {
                        errmsg = s
                    }
                }
            }
        }
        self.progressView.isHidden = true
        self.errorInfo.text = errmsg
        self.errorInfo.isHidden = false
        self.retryBtn.isHidden = false
    }
}

class YKImagesPreviewController: YKBaseViewController, UIScrollViewDelegate {
    
    var scrollView: UIScrollView!
    var imageViews = [YKImagePreView]()
    var files = [GKFileDataItem]()
    
    var currentIndex = 0
    
    init(files:[GKFileDataItem],selected:Int) {
        self.files = files
        self.currentIndex = selected
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = []
        self.setupViews()
        self.navigationItem.leftBarButtonItem = self.cancelBarButton
        self.gotoImage(index: currentIndex)
        self.scrollView.setContentOffset(CGPoint(x:CGFloat(currentIndex)*self.scrollView.frame.width,y:0), animated: false)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.layout()
    }
    
    var cancelBarButton: UIBarButtonItem {
        return UIBarButtonItem(title: YKString.kYKCancel, style: .plain, target: self, action: #selector(onCancel))
    }
    
    func setupViews() {
        
        scrollView = UIScrollView(frame: self.view.bounds)
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.autoresizesSubviews = false
        scrollView.scrollsToTop = false
        scrollView.delegate = self
        self.view.addSubview(scrollView)
        
        for item in files {
            let v = YKImagePreView(frame: self.scrollView.bounds, file: item)
            self.imageViews.append(v)
            self.scrollView.addSubview(v)
        }
        
        scrollView.contentSize = CGSize(width:CGFloat(files.count)*self.scrollView.frame.size.width,height:self.scrollView.frame.size.height)
    }
    
    func layout() {
        self.scrollView.frame = self.view.bounds
        scrollView.contentSize = CGSize(width:CGFloat(files.count)*self.view.frame.size.width,height:self.view.frame.size.height)
        for i in 0..<self.files.count {
            let rc = CGRect(x: self.scrollView.frame.size.width*CGFloat(i), y: 0, width: self.scrollView.frame.size.width, height: self.scrollView.frame.size.height)
            let v = self.imageViews[i]
            v.frame = rc
        }
    }
    
    func gotoImage(index:Int) {
        let v = self.imageViews[index]
        let f = self.files[index]
        if self.files.count > 1 {
            let s = "\(currentIndex+1)/\(self.files.count)"
            self.setNavTitle(s)
        } else {
            self.setNavTitle(f.filename)
        }
        v.start()
    }
    
    func onCancel() {
        YKImageFecther.shanreInstance.stopAll()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x > 0 {
            var index = Int(scrollView.contentOffset.x) / Int(scrollView.frame.size.width)
            if index  == currentIndex { return }
            
            index = min(index, self.files.count-1)
            index = max(index, 0)
            
            currentIndex = index
            
            self.gotoImage(index: index)
        }
    }
}
