//
//  YKFileListViewController.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/9.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit
import gknet
import gkutility


class YKFileListViewController: YKBaseTableViewController,YKFileItemCellDelegate, YKFileUploadCellDelegate, YKFileOperationSheetCellDelegate {
    
    var webpath = ""
    var mountID = 0
    var magicID = 0
    var requestID: GKRequestID = 0
    
    var addButton: UIButton?
    
    var files = [Any]()
    
    var displayConfig: YKFileDisplayConfig!
    
    var inMultiSelect = false
    
    var showArrow: Bool {
        if displayConfig.selectMode == .None {
            if  displayConfig.op == .Normal || displayConfig.op == .Fav {
                return true
            }
        }
        return false
    }
    
    
    init(mountID: Int, fullpath: String, config: YKFileDisplayConfig? = nil) {
        self.mountID = mountID
        self.webpath = fullpath
        if config == nil {
            displayConfig = YKFileDisplayConfig()
        } else {
            displayConfig = config!
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = .all
        self.automaticallyAdjustsScrollViewInsets = true
        self.hidesBottomBarWhenPushed = true
        self.load()
        if displayConfig.selectMode == .None {
          
            if displayConfig.op == .Normal {
                let btn = UIButton(type: .custom)
                btn.setImage(YKImage("addFileBtn"), for: .normal)
                btn.addTarget(self, action: #selector(onBtnAddFile), for: .touchUpInside)
                self.view.addSubview(btn)
                self.addButton = btn
                
                NotificationCenter.default.addObserver(self, selector: #selector(onDownloadNotify(notification:)), name: NSNotification.Name(YKNotification_DownloadFile), object: nil)
            }
            
        } else if displayConfig.selectMode == .Multi {
            onSelectChanged()
            NotificationCenter.default.addObserver(self, selector: #selector(onSelectChanged), name: NSNotification.Name(YKBaseDisplayConfig.SelectChangeNotification), object: nil)
        }
        self.setupNav()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onUploadNotify(notification:)), name: NSNotification.Name(YKNotification_UploadFile), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.addButton?.frame = CGRect(x: self.view.frame.size.width - 30 - 64, y: self.view.frame.height - 20 - 64, width: 64, height: 64)
    }
    
    
    
    override func setupTableView() {
        //self.tableView.rowHeight = 64
        self.tableView.allowsMultipleSelection = (displayConfig.selectMode == .Multi)
        self.setTableFootHeight(85)
    }
    
    
    var backBarButton: UIBarButtonItem {
        return UIBarButtonItem(image: YKImage("iconBack"), style: .plain, target: self, action: #selector(onBack))
    }
    
    var cancelSelectBarButton: UIBarButtonItem {
        return UIBarButtonItem(title: YKLocalizedString("取消"), style: .plain, target: self, action: #selector(onCancelSelect))
    }
    
    var cancelOperationBarButton: UIBarButtonItem {
        return UIBarButtonItem(title: YKLocalizedString("取消"), style: .plain, target: self, action: #selector(onCancelOperation))
    }
    
    var moreBarButton: UIBarButtonItem {
        return UIBarButtonItem(image: YKImage("iconMore"), style: .plain, target: self, action: #selector(onBarMore(send:event:)))
    }
    
    var multiToolBarItemSelectAll: UIBarButtonItem {
        return UIBarButtonItem(title: YKLocalizedString("全选"), style: .plain, target: self, action: #selector(onMultiSelectAll))
    }
    
    var multiToolBarItemSelectNone: UIBarButtonItem {
        return UIBarButtonItem(title: YKLocalizedString("全不选"), style: .plain, target: self, action: #selector(onMultiSelectNone))
    }
    
    var multiToolBarItemDelete: UIBarButtonItem {
        return UIBarButtonItem(title: YKLocalizedString("删除"), style: .plain, target: self, action: #selector(onMultiSelectDelete))
    }
    
    var multiToolBarItemCopy: UIBarButtonItem {
        return UIBarButtonItem(title: YKLocalizedString("复制"), style: .plain, target: self, action: #selector(onMultiSelectCopy))
    }
    
    var multiToolBarItemMove: UIBarButtonItem {
        return UIBarButtonItem(title: YKLocalizedString("移动"), style: .plain, target: self, action: #selector(onMultiSelectMove))
    }
    
    var multiToolBarItemCache: UIBarButtonItem {
        return UIBarButtonItem(title: YKLocalizedString("缓存"), style: .plain, target: self, action: #selector(onMultiSelectCache))
    }
    
    var quitMultiSelectBarButton: UIBarButtonItem {
        return UIBarButtonItem(title: YKLocalizedString("退出"), style: .plain, target: self, action: #selector(onQuitMultiSelect))
    }
    
    var pastToolBarItem: UIBarButtonItem {
        return UIBarButtonItem(title: YKLocalizedString("粘贴"), style: .plain, target: self, action: #selector(onPastFile))
    }
    
    var movehereToolBarItem: UIBarButtonItem {
        return UIBarButtonItem(title: YKLocalizedString("移动"), style: .plain, target: self, action: #selector(onPastFile))
    }
    
    var outSaveToolBarItem: UIBarButtonItem {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 44))
        v.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        var btn = UIButton(type: .custom)
        btn.setTitle(YKLocalizedString("新建文件夹"), for: .normal)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.titleLabel?.font = YKFont.make(12)
        btn.sizeToFit()
        btn.frame = CGRect(x: 10, y: 0, width: btn.frame.size.width, height: 44)
        v.addSubview(btn)
        btn.addTarget(self, action: #selector(add_folder), for: .touchUpInside)
        
        btn = UIButton(type: .custom)
        btn.setTitle(YKLocalizedString("保存"), for: .normal)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.frame = CGRect(x: (self.view.frame.size.width-150)/2, y: 0, width: 150, height: 44)
        v.addSubview(btn)
        btn.addTarget(self, action: #selector(onSaveOutFile), for: .touchUpInside)
        return UIBarButtonItem(customView: v)
    }
    
    func onTestUpload() {
        DispatchQueue.global().async {
            
            var items : [YKUploadManager.TaskAddItem] = []
            for _ in 0..<100 {
                var name = "test_"
                var content = ""
                
                var s = ""
                for _ in 0..<6 {
                    let a = arc4random() % 10
                    s.append("\(a)")
                }
                
                name.append(s)
                name.append(".txt")
                
                for _ in 0...100*1024 {
                    content.append("\(arc4random()%10)")
                }
                
                let path = gkutility.checkFileNameInDir(name, dir: YKLoginManager.shareInstance.getTransCacheFolder())
                
                do {
                    try content.write(toFile: path, atomically: true, encoding: .utf8)
                } catch  {
                    YKAlert.showAlert(message: YKLocalizedString("创建文件失败"), vc: self)
                    return
                }
                let web_path: String
                if self.webpath == "/" {
                    web_path = name
                } else {
                    web_path = self.webpath.gkAddLastSlash + name
                }
                
                let task = YKUploadManager.TaskAddItem(mount_id: self.mountID, webpath: web_path, localpath: path, override: true, expand: .None)
                items.append(task)
            }
            
            let ret = YKTransfer.shanreInstance.uploadManager.addTasks(items)
            DispatchQueue.main.async {
                for item in ret {
                    self.files.append(item)
                }
                self.tableView.reloadData()
            }
        }
    }
    
    func onTestStopUpload() {
        YKNetMonitor.shareInstance.status = .WWAN
        //YKTransfer.shanreInstance.downloadManager.stopAll()
        //self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: YKLocalizedString("upload"), style: .plain, target: self, action: #selector(onTestUpload)),UIBarButtonItem(title: YKLocalizedString("resume"), style: .plain, target: self, action: #selector(onTestResumeUpload))]

        
    }
    
    func onTestResumeUpload()  {
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: YKLocalizedString("upload"), style: .plain, target: self, action: #selector(onTestUpload)),UIBarButtonItem(title: YKLocalizedString("stop"), style: .plain, target: self, action: #selector(onTestStopUpload))]
        YKTransfer.shanreInstance.downloadManager.resumeAll()
    }
    
    private func setupNav() {
        
        if webpath == "/" {
            let mountitem = YKMountCenter.shareInstance.mountItemBy(mountID: mountID)
            self.navigationItem.title = mountitem?.org_name
        } else {
            self.navigationItem.title = webpath.gkFileName
        }
    
        if displayConfig.selectMode == .None {
            self.navigationItem.leftBarButtonItems = [backBarButton]
            //self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: YKLocalizedString("upload"), style: .plain, target: self, action: #selector(onTestUpload)),UIBarButtonItem(title: YKLocalizedString("stop"), style: .plain, target: self, action: #selector(onTestStopUpload))]
            
            switch displayConfig.op {
            case .Normal:
                self.navigationItem.rightBarButtonItem = self.moreBarButton
            case .Copy,.Move,.Save:
                self.navigationItem.rightBarButtonItem = self.cancelOperationBarButton
                self.navigationController?.isToolbarHidden = false
                self.navigationController?.toolbar.barTintColor = YKColor.Blue
                self.navigationController?.toolbar.tintColor = UIColor.white
                let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
                if displayConfig.op == .Copy {
                    self.toolbarItems = [flexibleSpace,self.pastToolBarItem,flexibleSpace]
                } else if displayConfig.op == .Move {
                    self.toolbarItems = [flexibleSpace,self.movehereToolBarItem,flexibleSpace]
                } else if displayConfig.op == .Save {
                    self.toolbarItems = [flexibleSpace,self.outSaveToolBarItem,flexibleSpace]
                }
                
            default:
                break
            }
            
        } else {
            
            var rootpath = "/"
            if let root = displayConfig.rootPath {
                rootpath = root.path
            } else {
                rootpath = ""
            }
            
            if displayConfig.selectMode == .Single {
                
                if webpath == rootpath {
                    self.navigationItem.leftBarButtonItems = nil
                } else {
                    self.navigationItem.leftBarButtonItems = [backBarButton]
                    
                }
                self.navigationItem.rightBarButtonItem = cancelSelectBarButton
                
            } else if displayConfig.selectMode == .Multi {
                if webpath == rootpath {
                    self.navigationItem.leftBarButtonItems = [cancelSelectBarButton]
                } else {
                    self.navigationItem.leftBarButtonItems = [backBarButton,cancelSelectBarButton]
                    
                }
                self.onSelectChanged()
            }
        }
    }
    
    private func genFileWrap(_ file: GKFileDataItem, downloads: [YKDownloadItemData]) -> YKFileItemCellWrap {
        
        if displayConfig.selectMode == .None {
            switch displayConfig.op {
            case .Copy,.Move,.Save,.OpenShare:
                return YKFileItemCellWrap(file: file, showArrow: false, selectType: .None)
            default:
                var ditem: YKDownloadItemData?
                for d in downloads {
                    if d.webpath == file.fullpath {
                        ditem = d
                        break
                    }
                }
                return YKFileItemCellWrap(file: file, showArrow: true, selectType: .None, showAccessoryBtn: false, downloadItem: ditem)
                
            }
            
        } else {
            if displayConfig.selectMode == .Single {
                var selType: YKSelectIconType = .None
                var showAccessoryBtn = false
                if displayConfig.selectType == .File {
                    if file.dir {
                        selType = .None
                    } else {
                        if displayConfig.checkFileIsExclude(file: file) {
                            selType = .Disable
                        }
                    }
                } else if displayConfig.selectType == .Dir {
                    if  file.dir {
                        showAccessoryBtn = true
                        if displayConfig.checkFileIsExclude(file: file) {
                            selType = .Disable
                            showAccessoryBtn = false
                        }
                    } else {
                        selType = .Disable
                    }
                } else if displayConfig.selectType == .FileDir {
                    if  file.dir {
                        showAccessoryBtn = true
                        if displayConfig.checkFileIsExclude(file: file) {
                            selType = .Disable
                            showAccessoryBtn = false
                        }
                    } else {
                        if displayConfig.checkFileIsExclude(file: file) {
                            selType = .Disable
                        }
                    }
                }
                
                return YKFileItemCellWrap(file: file, showArrow: false, selectType: selType, showAccessoryBtn: showAccessoryBtn)
                
            } else  { //多选
                var selType: YKSelectIconType = .None
                var showAccessoryBtn = false
                if displayConfig.selectType == .File {
                    if file.dir {
                        selType = .None
                    } else {
                        if displayConfig.checkFileIsExclude(file: file) {
                            selType = .Disable
                        } else {
                            if displayConfig.checkHasSelected(file: file) {
                                selType = .Selected
                            } else {
                                selType = .UnSelected
                            }
                        }
                    }
                } else if displayConfig.selectType == .Dir {
                    if file.dir {
                        showAccessoryBtn = true
                        if displayConfig.checkFileIsExclude(file: file) {
                            selType = .Disable
                        } else {
                            if displayConfig.checkHasSelected(file: file) {
                                selType = .Selected
                            } else {
                                selType = .UnSelected
                            }
                        }
                    } else {
                        selType = .Disable
                    }
                } else if displayConfig.selectType == .FileDir {
                    if file.dir {
                        showAccessoryBtn = true
                    }
                    
                    if displayConfig.checkFileIsExclude(file: file) {
                        selType = .Disable
                    } else {
                        if displayConfig.checkHasSelected(file: file) {
                            selType = .Selected
                        } else {
                            selType = .UnSelected
                        }
                    }
                }
                
                return YKFileItemCellWrap(file: file, showArrow: false, selectType: selType,showAccessoryBtn: showAccessoryBtn)
            }
        }
    }
    
    func load() {
        
        if magicID > 0 {
            
        } else {
            
            let mountid = self.mountID
            let parentpath = self.webpath
            let manager = YKMountCenter.shareInstance.mountManagerBy(mountID: mountID)
            if manager != nil {
                requestID = manager!.getFiles(fullpath: webpath, type: .Both, updateDB: (YKClient.shareInstance.extensionType == .None ? true : false), completion: { [weak self] (files:[GKFileDataItem], errmsg:String?) in
                    
                    if errmsg != nil {
                        
                    } else {
                        
                        var downloads:[YKDownloadItemData]?
                        if YKClient.shareInstance.extensionType == .None {
                            downloads = YKTransfer.shanreInstance.transDB?.getDownloadItems(mountID: mountid, parent: (parentpath == "/" ? "" : parentpath), expand: .Cache)
                        }
                        
                        var result = [Any]()
                        for f in files {
                            let item = self?.genFileWrap(f,downloads: downloads ?? [])
                            if item != nil {
                                result.append(item!)
                            }
                        }
                        if self == nil {
                            return
                        }
                        if YKClient.shareInstance.extensionType == .None {
                            if let uploads =  YKTransfer.shanreInstance.transDB?.getUploadItems(mountID: mountid, parent: (parentpath == "/" ? "" : parentpath)) {
                                for item in uploads {
                                    result.append(item)
                                }
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self?.files = result
                            self?.tableView.reloadData()
                        }
                    }
                })
            }
        }
    }
    
    func onBtnAddFile() {
        
        let items: Array<YKBottomSheetView.Item> = [
            YKBottomSheetView.Item(title: YKLocalizedString("文件夹"), id: 1, image: "fileadd/folder"),
            YKBottomSheetView.Item(title: YKLocalizedString("相册"), id: 2, image: "fileadd/photo"),
            YKBottomSheetView.Item(title: YKLocalizedString("拍照"), id: 3, image: "fileadd/camera"),
            YKBottomSheetView.Item(title: YKLocalizedString("文本"), id: 4, image: "fileadd/txt"),
            YKBottomSheetView.Item(title: YKLocalizedString("录音"), id: 5, image: "fileadd/record"),
            YKBottomSheetView.Item(title: YKLocalizedString("扫描"), id: 6, image: "fileadd/scan")
        ]
        YKBottomSheetView.show(items: items) { (id:Int, param: Any?) in
            switch id {
            case 1:
                self.add_folder()
            case 2:
                self.add_photos()
            case 4:
                self.add_text()
            default:
                break
            }
        }
    }
    
    func add_text() {
        YKFileOperationManager.shareManager.showTextEdit(fromVC: self, originContent: nil, editFile: nil, checkSameNameBlock: { (filename:String) -> Bool in
            return false
        }, cancelBlock: nil, completion: { (filename:String, data:Data, vc:UIViewController?) in
            
            let path = gkutility.checkFileNameInDir(filename, dir: YKLoginManager.shareInstance.getTransCacheFolder())
            
            do {
                try data.write(to: URL(fileURLWithPath: path))
            } catch  {
                YKAlert.showAlert(message: YKLocalizedString("创建文件失败"), vc: self)
                return
            }
            let web_path: String
            if self.webpath == "/" {
                web_path = filename
            } else {
                web_path = self.webpath.gkAddLastSlash + filename
            }
            
            let uploaditem = YKTransfer.shanreInstance.uploadManager.addTask(mountid: self.mountID, webpath: web_path, localpath: path)
            self.files.append(uploaditem)
            self.tableView.reloadData()
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    func add_folder() {
        
        let alert = UIAlertController(title: YKLocalizedString("请输入文件名称"), message: nil, preferredStyle: .alert)
        alert.addTextField { (textField: UITextField) in
            textField.placeholder = YKLocalizedString("请输入文件夹名称")
        }
        
        let actOK = UIAlertAction(title: YKLocalizedString("确认"), style: .default) { (act:UIAlertAction) in
            
            var dirname = ""
            if let textfield = alert.textFields?.first {
                if let inputname = textfield.text {
                    if !inputname.isEmpty {
                        if let checkerror = YKCommon.verifyFilename(inputname) {
                            DispatchQueue.main.async {
                                YKAlert.showAlert(message: checkerror, vc: self)
                            }
                            return
                        }
                        dirname = inputname.gkTrimSpace
                    }
                }
            }
            if !dirname.isEmpty {
                DispatchQueue.global().async {
                    var path = ""
                    if self.webpath == "/" {
                        path = dirname
                    } else {
                        path = self.webpath.gkAddLastSlash + dirname
                    }
                    let ret = GKHttpEngine.default.createFolder(mountid: self.mountID, webpath: path, create_dateline: nil, last_dateline: nil)
                    if ret.statuscode == 200 {
                        self.load()
                    } else {
                        
                    }
                }
            }
        }
        
        let actCancel = UIAlertAction(title: YKLocalizedString("取消"), style: .cancel, handler: nil)
        
        alert.addAction(actOK)
        alert.addAction(actCancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func add_photos() {
        let controller = YKAlbumsController()
        let nav = UINavigationController(rootViewController: controller)
        self.present(nav, animated: true, completion: nil)
    }
    
    func onUploadNotify(notification:Notification) {
        if let json = notification.object as? String {
            if let jsonDic = gkutility.json2dic(obj: json) {
                
                let notifyUpload = YKUploadItemData(byNotify: jsonDic)
                
                if displayConfig.op == .Fav {
                    
                } else {
                    var p = self.webpath
                    if p == "/" {
                        p = ""
                    }
                    if notifyUpload.mountid != self.mountID || notifyUpload.webpath.gkParentPath != p {
                        return
                    }
                    
                    for i in 0..<files.count {
                        let item = files[i]
                        if item is YKUploadItemData {
                            let upitem = item as! YKUploadItemData
                            if upitem.nID == notifyUpload.nID {
                                
                                upitem.status = notifyUpload.status
                                upitem.errcode = notifyUpload.errcode
                                upitem.errmsg = notifyUpload.errmsg
                                upitem.filesize = notifyUpload.filesize
                                upitem.filehash = notifyUpload.filehash
                                upitem.offset = notifyUpload.offset
                                
                                if upitem.status == .Removed {
                                    
                                    files.remove(at: i)
                                    self.tableView.reloadData()
                                    
                                } else if upitem.status == .Stop || upitem.status == .Start {
                                  self.tableView.reloadData()
                                } else {
                                    if let cell = self.tableView.cellForRow(at: IndexPath(row: i, section: 0)) as? YKFileUploadCell {
                                        if cell.progressView != nil {
                                            let p: Float = Float((Double(upitem.offset)/Double(upitem.filesize)))
                                            cell.setprogress(p)
                                            
                                            if upitem.status == .Finish || upitem.status == .Error {
                                                self.tableView.reloadData()
                                            }
                                        }
                                    }
                                }
                                
                                break
                            }
                        }
                    }
                    
                    if notifyUpload.status == YKTransStatus.Finish || notifyUpload.status == YKTransStatus.Error || notifyUpload.status == YKTransStatus.Removed {
                        var remain = 0
                        for item in self.files  {
                            if item is YKUploadItemData {
                                let upitem =  item as! YKUploadItemData
                                if upitem.status == .Start || upitem.status == .Normal {
                                    remain += 1
                                }
                            }
                        }
                        if remain == 0 {
                            self.load()
                        }
                    }
                }
            }
        }
    }
    
    
    func onDownloadNotify(notification:Notification) {
        
        var notifyItem: YKDownloadItemData!
        if let json = notification.object as? String {
            if let jsonDic = gkutility.json2dic(obj: json) {
                notifyItem = YKDownloadItemData(byNotify: jsonDic)
            }
        }
        
        if notifyItem == nil { return }
        
        if displayConfig.op == .Fav {
            
        } else {
            var p = self.webpath
            if p == "/" {
                p = ""
            }
            if notifyItem.mountid != self.mountID || notifyItem.webpath.gkParentPath != p || !notifyItem.convert{
                return
            }
            
            var thefile: YKFileItemCellWrap?
            var row = -1
            for i in 0..<files.count {
                let item = files[i]
                if item is YKFileItemCellWrap {
                    let file = item as! YKFileItemCellWrap
                    if file.file.fullpath == notifyItem.webpath {
                        
                        row = i
                        thefile = file

                        break
                    }
                }
            }
            
            if thefile == nil { return }
            
            if notifyItem.status == .Removed || notifyItem.status == .Finish {
                thefile!.downloadItem = nil
                thefile!.showArrow = true
                self.tableView.reloadData()
                return
            }
            
            thefile!.downloadItem = notifyItem
            
            switch notifyItem.status {
            case .Start:
                let loc = IndexPath(row: row, section: 0)
                if let _ = self.tableView.cellForRow(at: loc) as? YKFileItemCell {
                    self.tableView.reloadRows(at: [loc], with: .none)
                }
            default:
                self.tableView.reloadData()
                break
            }
            
        }
    }
    
    func onBack() {
        if requestID > 0 { GKHttpEngine.default.cancelTask(requestID) }
        self.navigationController?.popViewController(animated: true)
    }
    
    func onSaveOutFile() {
        var tasks: Array<YKUploadManager.TaskAddItem> = []
        for item in self.displayConfig.saveLocalFileInfo {
            let localpath = item.key
            var filename = item.value
            if filename.isEmpty {
                filename = localpath.gkFileName
            }
            let webpath = self.webpath.gkAddLastSlash + filename
            let t = YKUploadManager.TaskAddItem(mount_id: self.mountID, webpath: webpath, localpath: localpath, override: false, expand: .None)
            tasks.append(t)
        }
        let _ = YKTransfer.shanreInstance.uploadManager.addTasks(tasks)
        self.displayConfig.operationCompletion?([],"",self)
    }
    
    func onPastFile() {
        
        let sources = displayConfig.sourceFiles
        if sources.isEmpty {
            return
        }
        var patharr = [String]()
        var sourceParent = ""
        for item in sources {
            if sourceParent.isEmpty {
                sourceParent = item.fullpath.gkParentPath
                if sourceParent.isEmpty {
                    sourceParent = "/"
                }
            }
            if item.dir {
                patharr.append(item.fullpath.gkAddLastSlash)
            } else {
                patharr.append(item.fullpath)
            }
        }
        
        if sourceParent == self.webpath {
            YKAlert.showAlert(message: YKLocalizedString("源路径与目标路径一致"), vc: self)
            return
        }
        
        let sourcemountid = self.displayConfig.fromMountID
        let targetmountid = self.mountID
        let targetwebpath = self.webpath
        
        if displayConfig.op == .Copy {
            
            YKAlert.showHUD(view: self.view, message: YKLocalizedString("正在复制"))
            DispatchQueue.global().async { [weak self] () -> Void in
                
                let ret = GKHttpEngine.default.copyFiles(sourceMountID: sourcemountid, sourcePathList: patharr, targetMountID: targetmountid, targetPath: targetwebpath)
                if self == nil { return }
                DispatchQueue.main.async {
                    if ret.statuscode == 200 {
                        YKAlert.hideHUDSuccess(view: self?.view, str: YKLocalizedString("复制成功"), animate: true)
                        self?.displayConfig.operationCompletion?(sources,targetwebpath,self)
                        
                    } else {
                        YKAlert.hideHUD(view: self?.view, animate: false)
                        YKAlert.showAlert(message: ret.errmsg, title: YKLocalizedString("复制失败"), vc: self)
                    }
                }
            }
        } else if displayConfig.op == .Move {
            
            YKAlert.showHUD(view: self.view, message: YKLocalizedString("正在移动"))
            DispatchQueue.global().async { [weak self] () -> Void in
                
                let ret = GKHttpEngine.default.moveFiles(sourceMountID: sourcemountid, sourcePathList: patharr, targetMountID: targetmountid, targetPath: targetwebpath)
                if self == nil { return }
                DispatchQueue.main.async {
                    if ret.statuscode == 200 {
                        YKAlert.hideHUDSuccess(view: self?.view, str: YKLocalizedString("移动成功"), animate: true)
                        self?.displayConfig.operationCompletion?(sources,targetwebpath,self)
                    } else {
                        YKAlert.hideHUD(view: self?.view, animate: false)
                        YKAlert.showAlert(message: ret.errmsg, title: YKLocalizedString("移动失败"), vc: self)
                    }
                }
            }
            
        }
    }
    
    func onMultiSelectAll() {
        for i in 0..<self.tableView.numberOfRows(inSection: 0) {
            let index = IndexPath(row: i, section: 0)
            self.tableView.selectRow(at: index, animated: false, scrollPosition: .none)
        }
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.toolbarItems = [self.multiToolBarItemSelectNone,flexibleSpace,self.multiToolBarItemDelete,flexibleSpace,self.multiToolBarItemCopy,flexibleSpace,self.multiToolBarItemMove,flexibleSpace,self.multiToolBarItemCache]
    }
    
    func onMultiSelectNone() {
        for i in 0..<self.tableView.numberOfRows(inSection: 0) {
            let index = IndexPath(row: i, section: 0)
            self.tableView.deselectRow(at: index, animated: false)
        }
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.toolbarItems = [self.multiToolBarItemSelectAll,flexibleSpace,self.multiToolBarItemDelete,flexibleSpace,self.multiToolBarItemCopy,flexibleSpace,self.multiToolBarItemMove,flexibleSpace,self.multiToolBarItemCache]
    }
    
    func onMultiSelectDelete() {
        var files = [YKFileItemCellWrap]()
        if let selects = self.tableView.indexPathsForSelectedRows {
            for index in selects {
                if let item = self.files[index.row] as? YKFileItemCellWrap {
                    files.append(item)
                }
            }
        }
        
        if !files.isEmpty {
            self.file_delete(files: files)
        }
    }
    
    func onMultiSelectCopy() {
        
        var files = [YKFileItemCellWrap]()
        if let selects = self.tableView.indexPathsForSelectedRows {
            for index in selects {
                if let item = self.files[index.row] as? YKFileItemCellWrap {
                    files.append(item)
                }
            }
        }
        
        if !files.isEmpty {
            self.file_copy(files: files)
        }
    }
    
    func onMultiSelectMove() {
        var files = [YKFileItemCellWrap]()
        if let selects = self.tableView.indexPathsForSelectedRows {
            for index in selects {
                if let item = self.files[index.row] as? YKFileItemCellWrap {
                    files.append(item)
                }
            }
        }
        
        if !files.isEmpty {
            self.file_move(files: files)
        }
    }
    
    func onMultiSelectCache() {
        
    }
    
    func onSelectChanged() {
        let barstr = displayConfig.getSelectBarStr()
        let newbar = UIBarButtonItem(title: barstr, style: .plain, target: self, action: #selector(onConfirmSelect))
        newbar.isEnabled = !displayConfig.selectedData.isEmpty
        self.navigationItem.rightBarButtonItem = newbar
    }
    
    func onConfirmSelect() {
        displayConfig.selectFinishBlock?(displayConfig.selectedData,self)
    }
    
    func onCancelSelect() {
        displayConfig.selectCancelBlock?(self)
    }
    
    func onCancelOperation() {
        self.displayConfig.operationCancelBlock?(self)
    }
    
    func onBarMore(send:Any,event:UIEvent) {
        
        let items = [
            YKPopView.Item(text: YKLocalizedString("多选"), textColor: nil, image: nil, id: 1),
            YKPopView.Item(text: YKLocalizedString("排序"), textColor: nil, image: nil, id: 2),
            YKPopView.Item(text: YKLocalizedString("库设置"), textColor: nil, image: nil, id: 3),
            YKPopView.Item(text: YKLocalizedString("首页"), textColor: nil, image: nil, id: 4)]
        YKPopView .showItems(items, completion: { (id:Int) in
            
            switch id {
            case 1:
                self.barMultiSelect()
            case 2:
                self.barSortFiles()
            case 3:
                self.barLibSetting()
            case 4:
                self.barGotoHome()
            default:
                break
            }
            
        }, event: event)
    }
    
    func onQuitMultiSelect() {
        if !inMultiSelect { return }
        for item in self.files {
            if let file = item as? YKFileItemCellWrap {
                file.showArrow = true
            }
        }
        self.inMultiSelect = false
        self.addButton?.isHidden = false
        self.tableView.allowsMultipleSelection = false
        self.tableView.setEditing(false, animated: true)
        self.toolbarItems = nil
        self.navigationItem.rightBarButtonItem = self.moreBarButton
        self.tableView.reloadData()
        self.navigationController?.isToolbarHidden = true
    }
    
    func barMultiSelect() {
        
        self.foldAllCell(reload: true)
        
        DispatchQueue.main.async {
            for item in self.files {
                if let file = item as? YKFileItemCellWrap {
                    file.showArrow = false
                }
            }
            self.addButton?.isHidden = true
            self.tableView.allowsMultipleSelection = true
            self.tableView.setEditing(true, animated: true)
            self.inMultiSelect = true
            self.tableView.reloadData()
            self.navigationItem.rightBarButtonItem = self.quitMultiSelectBarButton
            
            self.navigationController?.isToolbarHidden = false
            self.navigationController?.toolbar.barTintColor = YKColor.Blue
            self.navigationController?.toolbar.tintColor = UIColor.white
            self.navigationController?.toolbar.isTranslucent = true
            
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            self.setToolbarItems([self.multiToolBarItemSelectAll,flexibleSpace,self.multiToolBarItemDelete,flexibleSpace,self.multiToolBarItemCopy,flexibleSpace,self.multiToolBarItemMove,flexibleSpace,self.multiToolBarItemCache], animated: true)
        }
        
    }
    
    func barSortFiles() {
        
    }
    
    func barLibSetting() {
        
    }
    
    func barGotoHome() {
        
    }
    
    
    func foldAllCell(reload: Bool) {
        
        var index = -1
        for i in 0..<self.files.count {
            let item = self.files[i]
            if item is String {
                if let file = self.files[i-1] as? YKFileItemCellWrap {
                    file.fold = true
                }
                index = i
                break
            }
        }
        
        if index >= 0 {
            self.files.remove(at: index)
            let indexpath = IndexPath(row: index, section: 0)
            self.tableView.deleteRows(at: [indexpath], with: .none)
            if reload {
                self.tableView.reloadData()
            }
        }
    }
    
    //MARK: YKFileOperationSheetCellDelegate
    func fileOperationShare(item: YKFileItemCellWrap?) {
        if item == nil { return }
        
        let fileItem = item!
        let mount = YKMountCenter.shareInstance.mountItemBy(mountID: fileItem.file.mount_id)
        var arr: Array<YKBottomSheetView.Item>!
        
        var entid = 0
        if mount != nil {
            entid = mount!.ent_id
        }
        
        arr = [
            YKBottomSheetView.Item(title: "发送给同事", id: 1, image: "fileshare/fellow"),
            YKBottomSheetView.Item(title: "外链", id: 2, image: "fileshare/link"),
        ]
        
        YKBottomSheetView.show(items: arr, title: nil, message: nil, cancelTitle: YKLocalizedString("取消"), param: fileItem, parentView: self.view, completion: { (id:Int, param: Any?) in
            
            let f = param as? YKFileItemCellWrap
            if f == nil { return }
            
            DispatchQueue.main.async {
                switch id {
                case 1:
                    break
                case 2:
                    let controller = YKFileLinkConfigController(file: fileItem.file, permission: nil)
                    self.navigationController?.pushViewController(controller, animated: true)
                    break
                default:
                    break
                    
                }
            }
            
        })
    }
    
    func fileOperationRemark(item: YKFileItemCellWrap?) {
        
    }
    
    func fileOperationDelete(item: YKFileItemCellWrap?) {
        if item == nil  { return }
        self.file_delete(files: [item!])
    }
    
    func fileOperationProperty(item: YKFileItemCellWrap?) {
        
    }
    
    func fileOperationMore(item: YKFileItemCellWrap?) {
        if item == nil { return }
        
        let fileItem = item!
        let mount = YKMountCenter.shareInstance.mountItemBy(mountID: fileItem.file.mount_id)
        var arr: Array<YKBottomSheetView.Item>!
        
        var entid = 0
        if mount != nil {
            entid = mount!.ent_id
        }
        
        if entid == 0 {
            arr = [
                YKBottomSheetView.Item(title: YKString.kYKCopy, id: YKMoreOperationType.Copy.rawValue, image: "fileoperation/copy"),
                YKBottomSheetView.Item(title: YKString.kYKMove, id: YKMoreOperationType.Move.rawValue, image: "fileoperation/move"),
                YKBottomSheetView.Item(title: YKString.kYKRename, id: YKMoreOperationType.Rename.rawValue, image: "fileoperation/rename"),
                YKBottomSheetView.Item(title: YKString.kYKDelete, id: YKMoreOperationType.Delete.rawValue, image: "fileoperation/delete"),
                YKBottomSheetView.Item(title: YKString.kYKProperty, id: YKMoreOperationType.Property.rawValue, image: "fileoperation/property"),
                YKBottomSheetView.Item(title: YKString.kYKHistory, id: YKMoreOperationType.History.rawValue, image: "fileoperation/history")
            ]
        } else {
            arr = [
                YKBottomSheetView.Item(title: YKString.kYKCopy, id: YKMoreOperationType.Copy.rawValue, image: "fileoperation/copy"),
                YKBottomSheetView.Item(title: YKString.kYKMove, id: YKMoreOperationType.Move.rawValue, image: "fileoperation/move"),
                YKBottomSheetView.Item(title: YKString.kYKRename, id: YKMoreOperationType.Rename.rawValue, image: "fileoperation/rename"),
                YKBottomSheetView.Item(title: YKString.kYKDelete, id: YKMoreOperationType.Delete.rawValue, image: "fileoperation/delete"),
                YKBottomSheetView.Item(title: YKString.kYKProperty, id: YKMoreOperationType.Property.rawValue, image: "fileoperation/property"),
                YKBottomSheetView.Item(title: YKString.kYKHistory, id: YKMoreOperationType.History.rawValue, image: "fileoperation/history"),
                YKBottomSheetView.Item(title: YKString.kYKPermission, id: YKMoreOperationType.Permission.rawValue, image: "fileoperation/permission")
            ]
            
            if !fileItem.file.dir {
                arr.append(YKBottomSheetView.Item(title: YKString.kYKCache, id: YKMoreOperationType.Cache.rawValue, image: "fileoperation/cache"))
                arr.append(YKBottomSheetView.Item(title: (fileItem.file.lock > 0 ? YKString.kYKUnLock : YKString.kYKLock), id: YKMoreOperationType.Lock.rawValue, image: "fileoperation/lock"))
            }
        }
        
        
        YKBottomSheetView.show(items: arr, title: nil, message: nil, cancelTitle: YKLocalizedString("取消"), param: fileItem, parentView: self.view, completion: { (id:Int, param: Any?) in
            
            let f = param as? YKFileItemCellWrap
            if f == nil { return }
            
            let type = YKMoreOperationType(rawValue: id)
            if type == nil { return }
            
            DispatchQueue.main.async {
                switch type! {
                case .Copy:
                    self.file_copy(files: [f!])
                case .Move:
                    self.file_move(files: [f!])
                case .Rename:
                    self.file_rename(file: f!)
                case .Cache:
                    self.file_cahce(files: [f!])
                case .Delete:
                    self.file_delete(files: [f!])
                case .Lock:
                    self.file_lock(file: f!)
                default:
                    break
                    
                }
            }
            
        })
    }
    
    
    func file_cahce(files: [YKFileItemCellWrap]) {
        var totalSize: Int64 = 0
        for f in files {
            totalSize += f.file.filesize
        }
        
        if gkutility.diskFreeSpace() <= totalSize {
            YKAlert.showAlert(message: YKLocalizedString("系统空间不足,缓存需要\(gkutility.formatSize(size: totalSize))"), vc: self)
            return
        }
        
        if YKNetMonitor.shareInstance.status == .WWAN {
            if totalSize >= YKAlertSizeWWAN {
                let msg = YKLocalizedString("当前处于移动网络, 继续下载将产生\(gkutility.formatSize(size: totalSize))的流量, 是否继续?")
                YKAlert.showAlert(message: msg, okTitle: YKLocalizedString("继续"), okBlock: { () in

                    self.doCaches(files: files)
                    
                }, cancelBlock: { () in
                    
                }, vc: self)
            } else {
                self.doCaches(files: files)
            }
        } else {
            self.doCaches(files: files)
        }
    }
    
    func file_delete(files: [YKFileItemCellWrap]) {
        var items = [GKFileDataItem]()
        for f in files {
            items.append(f.file)
        }
        YKFileOperationManager.shareManager.deleteFiles(mountid: self.mountID, files: items, fromVC: self) { () in
            self.onQuitMultiSelect()
            self.load()
        }
    }
    
    func file_lock(file: YKFileItemCellWrap) {
        if file.file.lock == 1 {
            YKAlert.showAlert(message: YKLocalizedString("只能解锁自己锁定的文件"), vc: self)
            return
        }
        
        let successmsg: String
        let successlock = (file.file.lock == 0 ? 2 : 0)
        if file.file.lock > 0{
            successmsg = YKLocalizedString("解锁成功")
        } else {
            successmsg = YKLocalizedString("文件已锁定")
        }
        
        YKAlert.showHUD(view: self.view, message: "")
        DispatchQueue.global().async { [weak self] (Void)->Void in
            let ret = GKHttpEngine.default.lockFile(mount_id: file.file.mount_id, fullpath: file.file.fullpath, lock: (file.file.lock == 0))
            if self == nil {
                return
            }
            DispatchQueue.main.async {
                if ret.statuscode == 200 {
                    file.file.lock = successlock
                    YKAlert.hideHUDSuccess(view: self?.view, str: successmsg, animate: true)
                    self?.tableView.reloadData()
                } else {
                    YKAlert.hideHUD(view: self?.view, animate: false)
                    YKAlert.showAlert(message: ret.errmsg, vc: self)
                }
            }
            
        }
        
    }
    
    func file_copy(files: [YKFileItemCellWrap]) {
        
        var source = [GKFileDataItem]()
        for item in files {
            source.append(item.file)
        }
        
        YKSelectFileComponent.showCopySelect(mountid: self.mountID, files: source, fromVC: self, cancelBlock: { (vc:UIViewController?) in
            self.dismiss(animated: true, completion: nil)
        }) { (files:[GKFileDataItem], targetParent:String, vc:UIViewController?) in
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func file_move(files: [YKFileItemCellWrap]) {
        
        var source = [GKFileDataItem]()
        for item in files {
            source.append(item.file)
        }
        
        YKSelectFileComponent.showMoveSelect(mountid: mountID, files: source, fromVC: self, cancelBlock: { (vc:UIViewController?) in
            self.dismiss(animated: true, completion: nil)
        }) { (files:[GKFileDataItem], targetParent:String, vc:UIViewController?) in
            self.dismiss(animated: true, completion: nil)
            self.onQuitMultiSelect()
            self.load()
        }
    }
    
    func file_rename(file: YKFileItemCellWrap) {
        
        YKFileOperationManager.shareManager.renameFile(file: file.file, fromVC: self, checkSameName: { (newname:String) -> Bool in
            for item in self.files {
                if let f = item as? YKFileItemCellWrap {
                    if f.file.filename == newname {
                        return true
                    }
                }
            }
            return false
            
        }) { (newname:String) in
            file.file.filename = newname
            file.calc()
            self.tableView.reloadData()
        }
        
    }
    
    func doCaches(files:[YKFileItemCellWrap]) {
        YKTransfer.shanreInstance.downloadManager.addTasks(files: files, expand: .Cache)
        self.tableView.reloadData()
    }
    
    //MARK: YKFileItemCellDelegate
    func didClickAccessortBtn(file: YKFileItemCellWrap) {
        self.showNextFileList(mountID: file.file.mount_id, fullpath: file.file.fullpath)
    }
    
    func didClickArrow(cell:YKFileItemCell, fileItem:YKFileItemCellWrap, show:Bool) -> Void {
        guard let indexpath = self.tableView.indexPath(for: cell) else {
            return
        }
        
        guard let _ = (self.files[indexpath.row] as? YKFileItemCellWrap) else {
            return
        }
        
        let selrow = indexpath.row
        if show {
            var presheet = false
            for index in 0..<files.count  {
                if files[index] is String {
                    if index < selrow {
                        presheet = true
                    }
                    
                    let f = files[index-1]
                    
                    let c = self.tableView.cellForRow(at: IndexPath(row: index-1, section: 0))
                    if c is YKFileItemCell {
                        (c as! YKFileItemCell).setFold(true)
                    }
                    
                    files.remove(at: index)
                    self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .none)
                    
                    if f is YKFileItemCellWrap {
                        (f as! YKFileItemCellWrap).fold = true
                    }
                    
                    break
                }
            }
            
            let sheetid = "sheetcell"
            let sheetrow = (presheet ? selrow : selrow+1)
            files.insert(sheetid, at: sheetrow)
            let f = files[sheetrow-1]
            if f is YKFileItemCellWrap {
                (f as! YKFileItemCellWrap).fold = false
            }
            
            let insertpath = IndexPath(row: sheetrow, section: 0)
            if sheetrow >= files.count-1 {
                self.tableView.insertRows(at: [insertpath], with: .top)
            } else {
                self.tableView.insertRows(at: [insertpath], with: .none)
            }
            
            self.tableView.scrollRectToVisible(self.tableView.rectForRow(at: insertpath), animated: true)
            
        } else {
            
            guard let _ = (files[selrow+1] as? String) else {
                return
            }
            
            files.remove(at: selrow+1)
            let f = files[selrow]
            if f is YKFileItemCellWrap {
                (f as! YKFileItemCellWrap).fold = true
            }
            if indexpath.row == files.count-1 {
                self.tableView.deleteRows(at: [IndexPath(row: selrow+1, section: 0)], with: .top)
            } else {
                self.tableView.deleteRows(at: [IndexPath(row: selrow+1, section: 0)], with: .none)
            }
        }
    }
    
    
    func didClickCancelDownload(cell:YKFileItemCell, fileItem:YKFileItemCellWrap) -> Void {
        if fileItem.downloadItem != nil {
            YKTransfer.shanreInstance.downloadManager.deleteTask(id: fileItem.downloadItem!.nID)
        }
    }
    
    func didClickRetryDownload(cell:YKFileItemCell, fileItem:YKFileItemCellWrap) -> Void {
        if fileItem.downloadItem != nil {
            YKTransfer.shanreInstance.downloadManager.resumeTask(id: fileItem.downloadItem!.nID)
            fileItem.downloadItem!.status = .Normal
            fileItem.calc()
            self.tableView.reloadData()
        }
    }
    
    func didClickSuspendDownload(cell:YKFileItemCell, fileItem:YKFileItemCellWrap) -> Void {
        if fileItem.downloadItem != nil {
            YKTransfer.shanreInstance.downloadManager.stopTask(id: fileItem.downloadItem!.nID)
        }
    }
    
    //MARK: YKFileUploadCellDelegate
    
    func didClickCancelBtn(cell:YKFileUploadCell, uploadItem: YKUploadItemData?) {
        if uploadItem == nil { return }
        
        YKTransfer.shanreInstance.uploadManager.deleteTask(id: uploadItem!.nID)
    }
    
    func didClickStopBtn(cell:YKFileUploadCell, uploadItem: YKUploadItemData?) {
        YKTransfer.shanreInstance.uploadManager.stopTask(id: uploadItem!.nID)
    }
    
    func didClickRetryBtn(cell:YKFileUploadCell, uploadItem: YKUploadItemData?) {
        if uploadItem == nil { return }
        uploadItem!.status = .Start
        YKTransfer.shanreInstance.uploadManager.resumeTask(id: uploadItem!.nID)
        self.tableView.reloadData()
    }
    
    func didClickErrorBtn(cell:YKFileUploadCell, uploadItem: YKUploadItemData?) {
        if uploadItem == nil { return }
        YKAlert.showAlert(message: uploadItem!.errmsg, vc: self)
    }
    
    //MARK: UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let file = files[indexPath.row]
        if file is YKFileItemCellWrap {
            return (file as! YKFileItemCellWrap).rowHeight
        } else if file is String {
            return 48
        } else if file is YKUploadItemData {
            return 54
        }
        return 44
    }
    
    //MARK: UITableViewDataSource
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellitem = files[indexPath.row]
        if cellitem is YKFileItemCellWrap {
            let item = cellitem as! YKFileItemCellWrap
            
            var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: item.cellid)
            if cell == nil {
                cell = YKFileItemCell(style: .default, reuseIdentifier: item.cellid,delegate:self)
            }
            
            if item.selectType == .Disable  {
                cell?.selectionStyle = .none
            } else {
                if inMultiSelect {
                    cell?.selectedBackgroundView = nil
                } else {
                    cell?.selectedBackgroundView = UIImageView(image: YKImage("cellSelectBkg"))
                }
                
            }
            
            
            let filecell = cell as! YKFileItemCell
            filecell.bindData(file: item)
            
            if displayConfig.selectMode == .Multi {
                if item.selectType == .Selected {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            }
            
            return cell!
        } else if cellitem is String {
            
            let cellid = cellitem as! String
            var cell = tableView.dequeueReusableCell(withIdentifier: cellid)
            if cell == nil {
                
                cell = YKFileOperationSheetCell(style: .default, reuseIdentifier: cellid, delegate: self)
                cell?.selectionStyle = .none
            }
            
            if cell is YKFileOperationSheetCell {
                let f = self.files[indexPath.row-1]
                if f is YKFileItemCellWrap {
                   (cell as! YKFileOperationSheetCell).bindFileItem(f as! YKFileItemCellWrap)
                }
                
            }
            return cell!
            
        } else if cellitem is YKUploadItemData {
            
            let uploaditem = cellitem as! YKUploadItemData
            
            var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "uploadcell")
            if cell == nil {
                cell = YKFileUploadCell(style: .default, reuseIdentifier: "uploadcell",delegate:self)
                cell?.selectionStyle = .none
            }
            
            let uploadcell = cell as! YKFileUploadCell
            uploadcell.bindData(item: uploaditem)
            
            return uploadcell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if displayConfig.selectMode != .None {
            if let item = self.files[indexPath.row] as? YKFileItemCellWrap {
                if item.selectType == .Disable || item.selectType == .DiableSelected {
                    return nil
                }
            }
            
        }
        
        return indexPath
    }
    
    func showNextFileList(mountID: Int, fullpath:String) {
        let controller = YKFileListViewController(mountID: mountID, fullpath: fullpath, config: displayConfig)
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let item = self.files[indexPath.row] as? YKFileItemCellWrap {
            if displayConfig.selectMode == .None {
                if inMultiSelect {
                    return
                }
                tableView.deselectRow(at: indexPath, animated: true)
                if item.file.dir {
                    self.showNextFileList(mountID: item.file.mount_id, fullpath: item.file.fullpath)
                } else {
                    switch displayConfig.op {
                    case .Normal,.Fav:
                        
                        var images = [GKFileDataItem]()
                        for item in self.files {
                            if let f = item as? YKFileItemCellWrap {
                                if YKCommon.isSupportImage(f.file.filename) {
                                    images.append(f.file)
                                }
                            }
                        }
                        
                        var selected = 0
                        for i in 0..<images.count {
                            let f = images[i]
                            if f.filename == item.file.filename {
                                selected = i
                                break
                            }
                        }
                        
                        if !images.isEmpty {
                            let controller = YKImagesPreviewController(files: images,selected:selected)
                            let nav = UINavigationController(rootViewController: controller)
                            self.present(nav, animated: true, completion: nil)
                        }
                        
//                        let previewInfo = YKFilePreviewBaseController.PreviewInfo()
//                        previewInfo.mount_id = item.file.mount_id
//                        previewInfo.webpath = item.file.fullpath
//                        previewInfo.filehash = item.file.filehash
//                        previewInfo.dir = item.file.dir
//                        previewInfo.filename = item.file.filename
//                        previewInfo.filesize = item.file.filesize
//                        previewInfo.uuidhash = item.file.uuidhash
//                        let controller = YKQuickLookPreviewController(info: previewInfo)
//                        let nav = UINavigationController(rootViewController: controller)
//                        self.present(nav, animated: true, completion: nil)
                    default:
                        break
                    }
                }
            } else {
                if displayConfig.selectMode == .Single {
                    if displayConfig.selectType == .File {
                        if item.file.dir {
                            self.showNextFileList(mountID: item.file.mount_id, fullpath: item.file.fullpath)
                        } else {
                            displayConfig.selectFinishBlock?([item.file],self)
                        }
                    } else if displayConfig.selectType == .Dir {
                        if item.file.dir {
                            displayConfig.selectFinishBlock?([item.file],self)
                        }
                    } else if displayConfig.selectType == .FileDir {
                        displayConfig.selectFinishBlock?([item.file],self)
                    }
                } else { //多选
                    if displayConfig.selectType == .File {
                        if item.file.dir {
                            self.showNextFileList(mountID: item.file.mount_id, fullpath: item.file.fullpath)
                        } else {
                            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                            displayConfig.changeSelectData(item: item.file, add: true, vc: self)
                            return
                        }
                    } else if displayConfig.selectType == .Dir {
                        if item.file.dir {
                            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                            displayConfig.changeSelectData(item: item.file, add: true, vc: self)
                            return
                        }
                    } else if displayConfig.selectType == .FileDir {
                        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                        displayConfig.changeSelectData(item: item.file, add: true, vc: self)
                        return
                    }
                }
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        if displayConfig.selectMode != .None {
            if let item = (self.files[indexPath.row] as? YKFileItemCellWrap) {
                if item.selectType == .Disable || item.selectType == .DiableSelected {
                    return nil
                }
            }
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if displayConfig.selectMode != .Multi {
            return
        }
        
        if let item = (self.files[indexPath.row] as? YKFileItemCellWrap) {
            if displayConfig.selectType == .File {
                if !item.file.dir {
                    tableView.deselectRow(at: indexPath, animated: true)
                    displayConfig.changeSelectData(item: item.file, add: false, vc: self)
                }
            } else if displayConfig.selectType == .Dir {
                if item.file.dir {
                    tableView.deselectRow(at: indexPath, animated: true)
                    displayConfig.changeSelectData(item: item.file, add: false, vc: self)
                }
            } else if displayConfig.selectType == .FileDir {
                tableView.deselectRow(at: indexPath, animated: true)
                displayConfig.changeSelectData(item: item.file, add: false, vc: self)
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return unsafeBitCast(3, to: UITableViewCellEditingStyle.self)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let item  = self.files[indexPath.row]
        if !(item is YKFileItemCellWrap) {
            return false
        }
        return true
    }
}

