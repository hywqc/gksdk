//
//  YKFileOperationManager.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/22.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gknet

final class YKFileOperationManager {
    
    static let shareManager = YKFileOperationManager()
    
    private init() {
        
    }

    
    class func addFileFolder() {
        
    }
    
    class func addFilePhoto() {
        
    }
    
    class func addFileCamera() {
        
    }
    
    func showTextEdit(fromVC:UIViewController,originContent:String? = nil ,editFile: GKFileDataItem? = nil,checkSameNameBlock:((String)->Bool)? = nil, cancelBlock: ((UIViewController?)->Void)? = nil, completion: @escaping ((String,Data,UIViewController?)->Void)) {
        
        let controller = YKTextViewController(completionBlock: completion, cancelBlock: cancelBlock, checkSameNameBlock: checkSameNameBlock, originContent: originContent, editFile: editFile)
        let nav = UINavigationController(rootViewController: controller)
        fromVC.present(nav, animated: true, completion: nil)
    }
    
    class func addFileAudio() {
        
    }
    
    class func addFileScan() {
        
    }
    
    func deleteFiles(mountid:Int,files:[GKFileDataItem],fromVC:UIViewController?, completion:((Void)->Void)? ) {
        
        if files.isEmpty { return }
        
        var patharr = [String]()
        for f in files {
            patharr.append(f.fullpath)
        }
        
        var alertMsg = ""
        if files.count == 1 {
            alertMsg = YKLocalizedString("是否确定删除'") + "\(files[0].filename)'?"
        } else {
            alertMsg = YKLocalizedString("是否确定删除所选文件?")
        }
        YKAlert.showAlert(message: alertMsg, okTitle: YKLocalizedString("删除"), destructive:true, okBlock: { () in
            
            YKAlert.showHUD(view: fromVC?.view, message: YKLocalizedString("正在删除"))
            DispatchQueue.global().async {
                let ret = GKHttpEngine.default.deleteFiles(sourceMountID: mountid, sourcePathList: patharr)
                DispatchQueue.main.async {
                    if ret.statuscode == 200 {
                        YKAlert.hideHUDSuccess(view: fromVC?.view, str: YKLocalizedString("删除成功"), animate: true)
                        completion?()
                    } else {
                        YKAlert.hideHUD(view: fromVC?.view, animate: false)
                        YKAlert.showAlert(message: ret.errmsg, title: YKLocalizedString("删除失败"), vc: fromVC)
                    }
                }
            }
            
        }, cancelBlock: nil, vc: fromVC)
    }
    
    func renameFile(file:GKFileDataItem,fromVC:UIViewController?,checkSameName:((String)->Bool)?, completion:((String)->Void)?) {
        
        let oldName = file.filename
        let alert = UIAlertController(title: YKLocalizedString("请输入文件名称"), message: nil, preferredStyle: .alert)
        alert.addTextField { (textField: UITextField) in
            textField.text = oldName
        }
        
        let actOK = UIAlertAction(title: YKLocalizedString("确认"), style: .default) { (act:UIAlertAction) in
            
            var newname = oldName
            if let textfield = alert.textFields?.first {
                if let inputname = textfield.text {
                    if !inputname.isEmpty {
                        if let checkerror = YKCommon.verifyFilename(inputname) {
                            DispatchQueue.main.async {
                                YKAlert.showAlert(message: checkerror, vc: fromVC)
                            }
                            return
                        }
                        newname = inputname.gkTrimSpace
                    }
                }
            }
            if newname != oldName {
                
                let mountid = file.mount_id
                let fpath = file.fullpath
                
                if checkSameName != nil {
                    if checkSameName!(newname) {
                        
                        DispatchQueue.main.async {
                            YKAlert.showAlert(message: YKLocalizedString("已存在同名文件"), vc: fromVC)
                        }
                        return
                    }
                }
                
                DispatchQueue.global().async {
                    let ret = GKHttpEngine.default.renameFile(mountID: mountid, fullpath: fpath, newName: newname)
                    DispatchQueue.main.async {
                        if ret.statuscode == 200 {
                            completion?(newname)
                        } else {
                            YKAlert.showAlert(message: ret.errmsg, vc: fromVC)
                        }
                    }
                }
            }
            
        }
        
        let actCancel = UIAlertAction(title: YKLocalizedString("取消"), style: .cancel, handler: nil)
        
        alert.addAction(actOK)
        alert.addAction(actCancel)
        
        fromVC?.present(alert, animated: true, completion: nil)
        
    }
    
    
}
