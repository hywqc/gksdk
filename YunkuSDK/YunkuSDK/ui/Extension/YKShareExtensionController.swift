//
//  YKShareExtensionController.swift
//  YunkuSDK
//
//  Created by wqc on 2017/9/13.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gkutility
import gknet
import MobileCoreServices


class YKShareExtensionController: YKBaseExtensionViewController,YKFileUploadCellDelegate {
    
    var shareFiles: Array<(String,String)> = []
    var shareTitle = ""
    var shareExtensionContext: NSExtensionContext!
    
    var uploadFiles = [YKUploadItemData]()
    var completeSelectPath = false
    
    
    init(title: String?, extensionContext: NSExtensionContext) {
        self.shareTitle = title ?? "够快云库"
        self.shareExtensionContext = extensionContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNavTitle(self.shareTitle)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: YKString.kYKCancel, style: .plain, target: self, action: #selector(onCancelShare))
    }
    
    func onCancelShare() {
        if completeSelectPath {
            
            YKAlert.showAlert(message: YKLocalizedString("是否取消上传?"),title:"", okTitle:YKLocalizedString("取消"),cancelTitle:YKLocalizedString("继续"), okBlock: { (Void) in
                YKTransfer.shanreInstance.uploadManager.deleteAll()
                self.shareExtensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }, cancelBlock: { (Void) in
                
            }, vc: self)
            
        } else {
            
            let filepaths = self.shareFiles
            DispatchQueue.global().async {
                for pair in filepaths {
                    gkutility.deleteFile(path: pair.0)
                }
            }
            
            let err = NSError(domain: "shareError", code: NSURLErrorCancelled, userInfo: nil)
            self.dismiss(animated: true) {
                self.shareExtensionContext.cancelRequest(withError: err)
            }
            
        }
        
        
    }
    
    override func setupTableView() {
        self.tableView.rowHeight = 48
        self.tableView.separatorStyle = .singleLine
        self.tableView.separatorColor = YKColor.Separator
        self.setTableFootHeight(64)
        self.tableView.backgroundColor = YKColor.BKG
    }
    
    override func loadData() {
        
        let cachepath = YKLoginManager.shareInstance.getTransCacheFolder().gkAddLastSlash
        
        let formatter = DateFormatter()
        formatter.dateFormat = "_YYYY_MM_dd_HH_mm_ss_SSS"
        
        for index in 0..<self.shareExtensionContext.inputItems.count {
            let input = self.shareExtensionContext.inputItems[index]
            if let extensionItem = input as? NSExtensionItem {
                for j in 0..<extensionItem.attachments!.count {
                    let p = extensionItem.attachments![j]
                    if let provider = p as? NSItemProvider {
                        if provider.hasItemConformingToTypeIdentifier(kUTTypeData as String) {
                            provider.loadItem(forTypeIdentifier: (kUTTypeData as String), options: nil, completionHandler: { (item:NSSecureCoding?, error:Error!) in
                                if let url = item as? URL {
                                    let ext = url.path.gkExt
                                    let fname = YKLocalizedString("文件") + formatter.string(from: Date()) + ".\(ext)"
                                    let targetpath = cachepath + fname
                                    gkutility.deleteFile(path: targetpath)
                                    
                                    try? FileManager.default.copyItem(atPath: url.path, toPath: targetpath)
                                    if gkutility.fileExist(path: targetpath) {
                                        self.shareFiles.append((targetpath,fname))
                                        DispatchQueue.main.async {
                                            self.tableView.reloadData()
                                        }
                                    }
                                } else if let img = item as? UIImage {
                                    if let imgdata = UIImageJPEGRepresentation(img, 1) {
                                        let fname = YKLocalizedString("图片") + formatter.string(from: Date()) + ".jpg"
                                        let targetpath = cachepath + fname
                                        gkutility.deleteFile(path: targetpath)
                                        try? imgdata.write(to: URL(fileURLWithPath: targetpath))
                                        if gkutility.fileExist(path: targetpath) {
                                            self.shareFiles.append((targetpath,fname))
                                            DispatchQueue.main.async {
                                                self.tableView.reloadData()
                                            }
                                        }
                                        
                                    }
                                }
                            })
                        }
                    }
                }
            }
        }
    }
    
    func onUploadNotify(notification:Notification) {
        if let json = notification.object as? String {
            if let jsonDic = gkutility.json2dic(obj: json) {
                
                let notifyUpload = YKUploadItemData(byNotify: jsonDic)
                
                for i in 0..<self.uploadFiles.count {
                    let upitem = uploadFiles[i]
                    if upitem.nID == notifyUpload.nID {
                        
                        upitem.status = notifyUpload.status
                        upitem.errcode = notifyUpload.errcode
                        upitem.errmsg = notifyUpload.errmsg
                        upitem.filesize = notifyUpload.filesize
                        upitem.filehash = notifyUpload.filehash
                        upitem.offset = notifyUpload.offset
                        
                        if upitem.status == .Removed {
                            
                            self.uploadFiles.remove(at: i)
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
                
                if notifyUpload.status == YKTransStatus.Finish || notifyUpload.status == YKTransStatus.Error || notifyUpload.status == YKTransStatus.Removed {
                    var remain = 0
                    for upitem in self.uploadFiles  {
                        if upitem.status == .Start || upitem.status == .Normal {
                            remain += 1
                        }
                    }
                    if remain == 0 {
                        DispatchQueue.main.async {
                            self.shareExtensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                        }
                    }
                }
            }
        }
    }
    
    //MARK: UITableViewDelegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if completeSelectPath {
            return 1
        } else {
            return 2
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if completeSelectPath {
            return self.uploadFiles.count
        } else {
            if 0 == section {
                return 1
            } else {
                return self.shareFiles.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if completeSelectPath {
            return 44
        } else {
            if 0 == section {
                return 20
            } else {
                return 44
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if completeSelectPath {
            let v = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 44))
            v.backgroundColor = YKColor.BKG
            
            
            let l = UILabel(frame: CGRect(x: 10, y: 0, width: v.frame.size.width, height: 44))
            l.font = YKFont.make(12)
            l.textColor = YKColor.SubTitle
            l.textAlignment = .left
            v.addSubview(l)
            l.text = YKLocalizedString("正在上传...")
            return v
        } else {
            if 0 == section {
                let v = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 44))
                v.backgroundColor = YKColor.BKG
                return v
            } else {
                let v = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 44))
                v.backgroundColor = YKColor.BKG
                
                
                let l = UILabel(frame: CGRect(x: 10, y: (v.frame.size.height-20), width: v.frame.size.width, height: 20))
                l.font = YKFont.make(12)
                l.textColor = YKColor.SubTitle
                l.textAlignment = .left
                v.addSubview(l)
                l.text = YKLocalizedString("文件(点击可编辑)")
                
                return v
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if completeSelectPath {
            
            let uploaditem = self.uploadFiles[indexPath.row]
            
            var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "uploadcell")
            if cell == nil {
                cell = YKFileUploadCell(style: .default, reuseIdentifier: "uploadcell",delegate:self)
                cell?.selectionStyle = .none
            }
            
            let uploadcell = cell as! YKFileUploadCell
            uploadcell.bindData(item: uploaditem)
            
            return uploadcell
            
        } else {
            if 0 == indexPath.section {
                var cell = tableView.dequeueReusableCell(withIdentifier: "cell1")
                if cell == nil {
                    cell = UITableViewCell(style: .default, reuseIdentifier: "cell1")
                    cell?.contentView.backgroundColor = UIColor.white
                    cell?.accessoryType = .disclosureIndicator
                }
                
                cell?.textLabel?.text = YKLocalizedString("选择目标路径")
                
                return cell!
            } else {
                
                
                
                var cell = tableView.dequeueReusableCell(withIdentifier: "cell2")
                if cell == nil {
                    cell = UITableViewCell(style: .default, reuseIdentifier: "cell2")
                    cell?.contentView.backgroundColor = UIColor.white
                    
                    cell?.accessoryType = .none
                    cell?.selectionStyle = .none
                    
                    let iconView = UIImageView(frame: CGRect(x: 15, y: (tableView.rowHeight-36)/2, width: 36, height: 36))
                    iconView.clipsToBounds = true
                    iconView.contentMode = .scaleAspectFill
                    iconView.tag = 1
                    cell?.contentView.addSubview(iconView)
                    
                    let field = UITextField(frame: CGRect(x: iconView.frame.maxX+10, y: 0, width: tableView.frame.size.width - (iconView.frame.maxX+10+10), height: tableView.rowHeight))
                    field.textColor = YKColor.Title
                    field.font = YKFont.make(14)
                    field.backgroundColor = UIColor.white
                    field.autoresizingMask = [.flexibleHeight,.flexibleWidth]
                    field.autocorrectionType = .no
                    field.autocapitalizationType = .none
                    field.spellCheckingType = .no
                    field.keyboardType = .default
                    field.returnKeyType = .next
                    field.textAlignment = .left
                    field.isUserInteractionEnabled = true
                    field.tag = 2
                    cell?.contentView.addSubview(field)
                }
                
                let pair = self.shareFiles[indexPath.row]
                let icon = cell?.contentView.viewWithTag(1) as? UIImageView
                icon?.image = UIImage(contentsOfFile: pair.0)
                let namefield = cell?.contentView.viewWithTag(2) as? UITextField
                namefield?.text = pair.1
                
                if icon?.image == nil {
                    icon?.image = YKFileIcon(pair.1, false)
                }
                
                return cell!
                
            }
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if self.completeSelectPath {
            return
        }
        
        if self.shareFiles.isEmpty {
            YKAlert.showAlert(message: YKLocalizedString("没有可用项"), vc: self)
            return
        }
        
        if  0 == indexPath.section {
            tableView.deselectRow(at: indexPath, animated: true)
            
            var filepaths:[String:String] = [:]

            for tuple in self.shareFiles {
                filepaths[tuple.0] = tuple.1
            }
            
            let vc = YKSelectFileComponent.getShareExtensionSelect(localFiles: filepaths, cancelBlock: { (vc:UIViewController?) in
                self.dismiss(animated: true) {
                    let err = NSError(domain: "shareError", code: NSURLErrorCancelled, userInfo: nil)
                    self.shareExtensionContext.cancelRequest(withError: err)
                }
            }, completion: { (files:[GKFileDataItem], targetParent:String, vc:UIViewController?) in
                self.navigationController?.popToViewController(self, animated: true)
                self.navigationController?.isToolbarHidden = true
                NotificationCenter.default.addObserver(self, selector: #selector(self.onUploadNotify(notification:)), name: NSNotification.Name(YKNotification_UploadFile), object: nil)
                DispatchQueue.main.async {
                    var uploads = [YKUploadItemData]()
                    for (k,_) in filepaths {
                        if let upitem = YKTransfer.shanreInstance.transDB?.getUploadItemBy(localPath: k) {
                            uploads.append(upitem)
                        }
                    }
                    self.uploadFiles = uploads
                    self.completeSelectPath = true
                    self.tableView.reloadData()
                }
                
            })
            self.navigationController?.pushViewController(vc, animated: true)
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
}
