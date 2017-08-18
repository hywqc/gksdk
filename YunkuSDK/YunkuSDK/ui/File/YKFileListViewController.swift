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

class YKFileListViewController: YKBaseTableViewController,YKFileItemCellDelegate {
    
    var webpath = ""
    var mountID = 0
    var magicID = 0
    var requestID: GKRequestID = 0
    
    var files = [YKFileItemCellWrap]()
    
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
        if displayConfig.selectMode == .Multi {
            onSelectChanged()
            NotificationCenter.default.addObserver(self, selector: #selector(onSelectChanged), name: NSNotification.Name(YKBaseDisplayConfig.SelectChangeNotification), object: nil)
        }
        self.setupNav()
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
    
    private func setupNav() {
        
        if webpath == "/" {
            let mountitem = YKMountCenter.shareInstance.mountItemBy(mountID: mountID)
            self.navigationItem.title = mountitem?.org_name
        } else {
        self.navigationItem.title = webpath.gkFileName
        }
    
        if displayConfig.selectMode == .None {
            
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
                        var result = [YKFileItemCellWrap]()
                        for f in files {
                            let item = self?.genFileWrap(f)
                            if item != nil {
                                result.append(item!)
                            }
                        }
                        if self == nil {
                            return
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
    
    func onBack() {
        if requestID > 0 { GKHttpEngine.default.cancelTask(requestID) }
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: YKFileItemCellDelegate
    func didClickAccessortBtn(file: YKFileItemCellWrap) {
        self.showNextFileList(mountID: file.file.mount_id, fullpath: file.file.fullpath)
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
        return file.rowHeight
    }
    
    //MARK: UITableViewDataSource
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let item = self.files[indexPath.row]
        
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
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        if displayConfig.selectMode != .None {
            let item = self.files[indexPath.row]
            if item.selectType == .Disable || item.selectType == .DiableSelected {
                return nil
            }
        }
        
        return indexPath
    }
    
    func showNextFileList(mountID: Int, fullpath:String) {
        let controller = YKFileListViewController(mountID: mountID, fullpath: fullpath, config: displayConfig)
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.files[indexPath.row]
        
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
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        if displayConfig.selectMode != .None {
            let item = self.files[indexPath.row]
            if item.selectType == .Disable || item.selectType == .DiableSelected {
                return nil
            }
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if displayConfig.selectMode != .Multi {
            return
        }
        
        let item = self.files[indexPath.row]
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

