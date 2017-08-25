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

class YKFileListViewController: YKBaseTableViewController,YKFileItemCellDelegate, YKFileUploadCellDelegate {
    
    var webpath = ""
    var mountID = 0
    var magicID = 0
    var requestID: GKRequestID = 0
    
    var addButton: UIButton?
    
    var files = [Any]()
    
    var displayConfig: YKFileDisplayConfig!
    
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
            }
            
        } else if displayConfig.selectMode == .Multi {
            onSelectChanged()
            NotificationCenter.default.addObserver(self, selector: #selector(onSelectChanged), name: NSNotification.Name(YKBaseDisplayConfig.SelectChangeNotification), object: nil)
        }
        self.setupNav()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onUploadNotify(notification:)), name: NSNotification.Name(YKNotification_UploadFile), object: nil)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.addButton?.frame = CGRect(x: self.view.frame.size.width - 30 - 64, y: self.view.frame.height - 70 - 64, width: 64, height: 64)
    }
    
    
    
    override func setupTableView() {
        //self.tableView.rowHeight = 64
        self.tableView.allowsMultipleSelection = (displayConfig.selectMode == .Multi)
    }
    
    
    var backBarButton: UIBarButtonItem {
        return UIBarButtonItem(image: YKImage("iconBack"), style: .plain, target: self, action: #selector(onBack))
    }
    
    var cancelSelectBarButton: UIBarButtonItem {
        return UIBarButtonItem(title: YKLocalizedString("取消"), style: .plain, target: self, action: #selector(onCancelSelect))
    }
    
    var moreBarButton: UIBarButtonItem {
        return UIBarButtonItem(image: YKImage("iconMore"), style: .plain, target: self, action: #selector(onBarMore(send:event:)))
    }
    
    func onTestUpload() {
        DispatchQueue.global().async {
            
            var items : [YKUploadManager.TaskAddItem] = []
            for _ in 0..<1 {
                var name = "test_"
                var content = ""
                
                var s = ""
                for _ in 0..<6 {
                    let a = arc4random() % 10
                    s.append("\(a)")
                }
                
                name.append(s)
                name.append(".txt")
                
                for _ in 0...10*1024 {
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
            self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: YKLocalizedString("upload"), style: .plain, target: self, action: #selector(onTestUpload)),UIBarButtonItem(title: YKLocalizedString("stop"), style: .plain, target: self, action: #selector(onTestStopUpload))]
            
            
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
    
    private func genFileWrap(_ file: GKFileDataItem) -> YKFileItemCellWrap {
        
        if displayConfig.selectMode == .None {
            switch displayConfig.op {
            case .Copy,.Move,.Save,.OpenShare:
                return YKFileItemCellWrap(file: file, showArrow: false, selectType: .None, downloadStatus: .None, progress: 0, errorInfo: "")
            default:
                return YKFileItemCellWrap(file: file, showArrow: true, selectType: .None, downloadStatus: .None, progress: 0, errorInfo: "")
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
                
                return YKFileItemCellWrap(file: file, showArrow: false, selectType: selType, downloadStatus: .None, progress: 0, errorInfo: "", showAccessoryBtn: showAccessoryBtn)
                
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
                
                return YKFileItemCellWrap(file: file, showArrow: false, selectType: selType, downloadStatus: .None, progress: 0, errorInfo: "",showAccessoryBtn: showAccessoryBtn)
            }
        }
    }
    
    func load() {
        
        if magicID > 0 {
            
        } else {
            
            let manager = YKMountCenter.shareInstance.mountManagerBy(mountID: mountID)
            if manager != nil {
                requestID = manager!.getFiles(fullpath: webpath, completion: { [weak self] (files:[GKFileDataItem], errmsg:String?) in
                    
                    if errmsg != nil {
                        
                    } else {
                        var result = [Any]()
                        for f in files {
                            let item = self?.genFileWrap(f)
                            if item != nil {
                                result.append(item!)
                            }
                        }
                        if self == nil {
                            return
                        }
                        if let uploads =  YKTransfer.shanreInstance.transDB?.getUploadItems() {
                            for item in uploads {
                                result.append(item)
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
            YKBottomSheetView.Item(title: YKLocalizedString("文件夹"), id: 1, image: "AddFolder"),
            YKBottomSheetView.Item(title: YKLocalizedString("相册"), id: 2, image: "AddPhoto"),
            YKBottomSheetView.Item(title: YKLocalizedString("拍照"), id: 3, image: "AddCamera"),
            YKBottomSheetView.Item(title: YKLocalizedString("文本"), id: 4, image: "AddTxt"),
            YKBottomSheetView.Item(title: YKLocalizedString("录音"), id: 5, image: "AddRecord"),
            YKBottomSheetView.Item(title: YKLocalizedString("扫描"), id: 6, image: "AddScan")
        ]
        YKBottomSheetView.show(items: items) { (id:Int, param: Any?) in
            switch id {
            case 4:
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
            default:
                break
            }
        }
    }
    
    func onUploadNotify(notification:Notification) {
        if let json = notification.object as? String {
            if let jsonDic = gkutility.json2dic(obj: json) {
                let taskid = gkSafeInt(dic: jsonDic, key: "id")
                let mountid = gkSafeInt(dic: jsonDic, key: "mount_id")
                let fullpath = gkSafeString(dic: jsonDic, key: "webpath")
                let status = gkSafeInt(dic: jsonDic, key: "status")
                let errcode = gkSafeInt(dic: jsonDic, key: "errcode")
                let errmsg = gkSafeString(dic: jsonDic, key: "errmsg")
                
                
                if displayConfig.op == .Fav {
                    
                } else {
                    var p = self.webpath
                    if p == "/" {
                        p = ""
                    }
                    if mountid != self.mountID || fullpath.gkParentPath != p {
                        return
                    }
                    
                    for i in 0..<files.count {
                        let item = files[i]
                        if item is YKUploadItemData {
                            let upitem = item as! YKUploadItemData
                            if upitem.nID == taskid {
                                upitem.status = (YKTransStatus(rawValue: status) ?? .Normal)
                                upitem.errcode = errcode
                                upitem.errmsg = errmsg
                                
                                if upitem.status == .Removed {
                                    
                                    files.remove(at: i)
                                    self.tableView.reloadData()
                                    
                                } else {
                                    if let cell = self.tableView.cellForRow(at: IndexPath(row: i, section: 0)) as? YKFileUploadCell {
                                        if cell.progressView != nil {
                                            let p: Float = Float((Double(upitem.offset)/Double(upitem.filesize)))
                                            cell.progressView.setProgress(p, animated: true)
                                            
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
                    
                    if status == YKTransStatus.Finish.rawValue || status == YKTransStatus.Error.rawValue || status == YKTransStatus.Removed.rawValue {
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
    
    func onBack() {
        if requestID > 0 { GKHttpEngine.default.cancelTask(requestID) }
        self.navigationController?.popViewController(animated: true)
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
    
    func barMultiSelect() {
        
    }
    
    func barSortFiles() {
        
    }
    
    func barLibSetting() {
        
    }
    
    func barGotoHome() {
        
    }
    
    
    
    //MARK: YKFileItemCellDelegate
    func didClickAccessortBtn(file: YKFileItemCellWrap) {
        self.showNextFileList(mountID: file.file.mount_id, fullpath: file.file.fullpath)
    }
    
    func didClickArrow(cell:YKFileItemCell, fileItem:YKFileItemCellWrap, show:Bool) -> Void {
        guard let indexpath = self.tableView.indexPathForRow(at: cell.center) else {
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
    
    //MARK: YKFileUploadCellDelegate
    
    func didClickCancelBtn(cell:YKFileUploadCell, uploadItem: YKUploadItemData?) {
        if uploadItem == nil { return }
        
        YKTransfer.shanreInstance.uploadManager.stopTask(id: uploadItem!.nID)
    }
    
    func didClickRetryBtn(cell:YKFileUploadCell, uploadItem: YKUploadItemData?) {
        if uploadItem == nil { return }
        let newitem = YKTransfer.shanreInstance.uploadManager.addTask(mountid: uploadItem!.mountid, webpath: uploadItem!.webpath, localpath: uploadItem!.localpath, overwrite: uploadItem!.overwrite, expand: uploadItem!.expand)
        uploadItem!.nID = newitem.nID
        uploadItem!.status = .Normal
        uploadItem!.offset = 0
        uploadItem!.errcode = 0
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
            
            if item.selectType == .Disable {
                cell?.selectionStyle = .none
            } else {
                cell?.selectedBackgroundView = UIImageView(image: YKImage("cellSelectBkg"))
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
                cell = YKFileOperationSheetCell(style: .default, reuseIdentifier: cellid)
                cell?.selectionStyle = .none
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
                tableView.deselectRow(at: indexPath, animated: true)
                if item.file.dir {
                    self.showNextFileList(mountID: item.file.mount_id, fullpath: item.file.fullpath)
                } else {
                    
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
}

