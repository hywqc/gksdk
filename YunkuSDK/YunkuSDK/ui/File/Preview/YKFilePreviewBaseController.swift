//
//  YKFilePreviewController.swift
//  YunkuSDK
//
//  Created by wqc on 2017/9/1.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gkutility
import gknet



class YKFilePreviewBaseController: YKBaseViewController {
    
    class PreviewInfo {
        var mount_id = 0
        var webpath = ""
        var filename = ""
        var filehash = ""
        var uuidhash = ""
        var dir = false
        var filesize: Int64 = 0
        var hid = ""
        var convert = false
        var showWater = false
        var permission = YKPermissions()
    }
    
    var previewInfo: PreviewInfo!
    
    var downloadItem: YKDownloadItemData?
    
    var localpath = ""
    
    var fileIcon: UIImageView!
    var statusInfo: UILabel!
    var progressView: UIProgressView!
    var retryBtn: UIButton!
    var loadingContainer: UIView!
    
    init(info: PreviewInfo) {
        self.previewInfo = info
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("YKFilePreviewBaseController deinit")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var cancelBarButton: UIBarButtonItem {
        return UIBarButtonItem(title: YKString.kYKCancel, style: .plain, target: self, action: #selector(onCancel))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = []
        self.setNavTitle(previewInfo.filename)
        self.navigationItem.leftBarButtonItem = self.cancelBarButton
        self.setupViews()
        let icon = YKFileIcon(previewInfo.filename, previewInfo.dir)
        self.fileIcon.image = icon
        self.start()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if !self.loadingContainer.isHidden {
            self.layout()
        }
    }
    
    func layout() {
        
        let sz = self.view.frame.size
        
        self.loadingContainer.frame = CGRect(x: (sz.width - self.loadingContainer.frame.size.width)/2, y: (sz.height - self.loadingContainer.frame.size.height)/2, width: self.loadingContainer.frame.size.width, height: self.loadingContainer.frame.size.height)
    }
    
    func setupViews() {
        
        let iconSize: CGFloat = 50
        let infoH: CGFloat = 25
        let btnH: CGFloat = 44
        
        let totalH: CGFloat = (iconSize + 10 + infoH + btnH)
        let totalW: CGFloat = 300
        
        self.loadingContainer = UIView(frame: CGRect(x: 0, y: 0, width: totalW, height: totalH))
        self.view.addSubview(self.loadingContainer)
        
        let imageview = UIImageView(frame: CGRect(x: (totalW - iconSize)/2, y: 0, width: iconSize, height: iconSize))
        imageview.clipsToBounds = true
        imageview.contentMode = .scaleAspectFit
        self.loadingContainer.addSubview(imageview)
        self.fileIcon = imageview
        
        
        let label = UILabel(frame: CGRect(x: 0, y: imageview.frame.maxY + 10, width: totalW, height: infoH))
        label.textColor = YKColor.SubTitle
        label.textAlignment = .center
        label.font = YKFont.make(12)
        label.numberOfLines = 0
        label.text = YKLocalizedString("正在打开...")
        self.loadingContainer.addSubview(label)
        self.statusInfo = label
        
        let progress = UIProgressView(frame: CGRect(x: (totalW-230)/2, y: label.frame.maxY+5, width: 230, height: 5))
        self.loadingContainer.addSubview(progress)
        progress.setProgress(0, animated: false)
        self.progressView = progress
        
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: (totalW-100)/2, y: label.frame.maxY, width: 100, height: btnH)
        button.setTitle(YKString.kYKRetry, for: .normal)
        button.titleLabel?.font = YKFont.make(14)
        button.setTitleColor(YKColor.Title, for: .normal)
        button.isHidden = true
        self.loadingContainer.addSubview(button)
        self.retryBtn = button
        button.addTarget(self, action: #selector(onBtnRetry), for: .touchUpInside)
        
    }
    
    func start() {
        let convert = YKCommon.needConvertPreview(filename: self.previewInfo.filename)
        let type: YKCacheManager.CacheType = (convert ? .Convert : .Original)
        
        if let cache = YKCacheManager.shareManager.checkCache(key: self.previewInfo.filehash, type: type) {
            self.localpath = cache
            self.openFile()
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(onDownloadNotify(notification:)), name: NSNotification.Name(YKNotification_DownloadFile), object: nil)
            
            let localpath = YKCacheManager.shareManager.cachePath(key: self.previewInfo.filehash, type: type)
            self.localpath = localpath
            DispatchQueue.global().async {
                self.downloadItem = YKTransfer.shanreInstance.downloadManager.addTask(mountid: self.previewInfo.mount_id, webpath: self.previewInfo.webpath, filehash: self.previewInfo.filehash, dir: self.previewInfo.dir, filesize: self.previewInfo.filesize, localpath: localpath, convert: convert, hid: self.previewInfo.hid, expand: .Open)
            }
        }
        
    }
    
    func onCancel() {
        if self.downloadItem != nil {
            YKTransfer.shanreInstance.downloadManager.deleteTask(id: self.downloadItem!.nID)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func onBtnRetry() {
        
    }
    
    func onDownloadNotify(notification:Notification) {
        
        var notifyItem: YKDownloadItemData!
        if let json = notification.object as? String {
            if let jsonDic = gkutility.json2dic(obj: json) {
                notifyItem = YKDownloadItemData(byNotify: jsonDic)
            }
        }
        
        if notifyItem == nil { return }
        

        if notifyItem.filehash != self.previewInfo.filehash || notifyItem.convert != self.previewInfo.convert {
            return
        }
        
        switch notifyItem.status {
        case .Start:
            var p: Float = 0
            if self.previewInfo.filesize > 0 {
                p  = Float(notifyItem.offset)/Float(self.previewInfo.filesize)
            }
            self.statusInfo.text = YKLocalizedString("正在打开: \(gkutility.formatSize(size: notifyItem.offset))/\(gkutility.formatSize(size: notifyItem.filesize))")
            self.progressView.isHidden = false
            self.progressView.setProgress(p, animated: true)
        case .Error:
            self.statusInfo.text = YKLocalizedString("打开失败: ") + notifyItem.errmsg
            self.progressView.isHidden = true
        case .Finish:
            self.progressView.setProgress(1, animated: true)
            self.loadingContainer.isHidden = true
            self.openFile()
        default:
            break
        }
    }
    
    
    func openFile() {
        if !gkutility.fileExist(path: self.localpath) { return }
    }
}
