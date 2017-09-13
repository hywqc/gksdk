//
//  YKTextViewController.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/24.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit
import gkutility
import gknet

class YKTextViewController : YKBaseViewController, UITextViewDelegate {
    
    var textView: UITextView!
    
    var checkSameNameBlock: ((String)->Bool)?
    var completionBlock:(String,Data,UIViewController?) -> Void
    var cancelBlock: ((UIViewController?)->Void)?
    var originContent: String?
    var editFile: GKFileDataItem?
    
    init(completionBlock:@escaping (String,Data,UIViewController?) -> Void,cancelBlock: ((UIViewController?)->Void)? = nil,checkSameNameBlock:((String)->Bool)? = nil, originContent:String? = nil, editFile: GKFileDataItem? = nil) {
        self.completionBlock = completionBlock
        self.cancelBlock = cancelBlock
        self.checkSameNameBlock = checkSameNameBlock
        self.originContent = originContent
        self.editFile = editFile
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = [.left,.right]
        self.automaticallyAdjustsScrollViewInsets = false
        if editFile != nil {
            self.setNavTitle(editFile!.filename)
        } else {
            self.setNavTitle(YKLocalizedString("创建文本"))
        }
        self.navigationItem.leftBarButtonItem = self.cancelBarButton
        self.navigationItem.rightBarButtonItem = self.okBarButton
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        self.setupViews()
        
        if originContent != nil {
            self.textView.text = originContent!
        }
    }
    
    var cancelBarButton: UIBarButtonItem {
        return UIBarButtonItem(title: YKLocalizedString("取消"), style: .plain, target: self, action: #selector(onCancel))
    }
    
    
    var okBarButton: UIBarButtonItem {
        return UIBarButtonItem(title: YKLocalizedString("保存"), style: .plain, target: self, action: #selector(onComplete))
    }
    
    func setupViews() {
        let textview = UITextView(frame: self.view.bounds)
        textview.textColor = YKColor.Title
        textview.font = YKFont.make(14)
        textview.backgroundColor = UIColor.white
        textview.autoresizingMask = [.flexibleHeight,.flexibleWidth]
        textview.autocorrectionType = .no
        textview.autocapitalizationType = .none
        textview.spellCheckingType = .no
        textview.isScrollEnabled = true
        textview.keyboardType = .default
        textview.returnKeyType = .next
        textview.isUserInteractionEnabled = true
        textview.isEditable = true
        textview.delegate = self
        self.view.addSubview(textview)
        self.textView = textview
    }
    
    func onCancel() {
        var notsave = false
        if originContent != nil {
            if originContent! != self.textView.text {
                notsave = true
            }
        } else {
            notsave = !self.textView.text.isEmpty
        }
        if notsave {
            YKAlert.showAlert(message: YKLocalizedString("文件未保存,是否退出编辑?"), okTitle: YKLocalizedString("退出"), okBlock: { () in
                self.dismiss(animated: true, completion: nil)
            }, cancelBlock: nil, vc: self)
        } else {
            if (cancelBlock != nil) {
                cancelBlock!(self)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func onComplete() {
        
        if editFile == nil {
            
            let defname = "note\(gkutility.genFileNameSuffixByDate()).txt"
            
            let alert = UIAlertController(title: YKLocalizedString("请输入文件名称(不含后缀名)"), message: nil, preferredStyle: .alert)
            alert.addTextField { (textField: UITextField) in
                textField.placeholder = defname
            }
            
            let actOK = UIAlertAction(title: YKLocalizedString("确认"), style: .default) { (act:UIAlertAction) in
                
                var filename = defname
                if let textfield = alert.textFields?.first {
                    if let inputname = textfield.text {
                        if !inputname.isEmpty {
                            if let checkerror = YKCommon.verifyFilename(inputname) {
                                DispatchQueue.main.async {
                                    YKAlert.showAlert(message: checkerror, vc: self)
                                }
                                return
                            }
                            filename = "\(inputname.gkTrimSpace).txt"
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.doSave(filename: filename)
                }
            }
            
            let actCancel = UIAlertAction(title: YKLocalizedString("取消"), style: .cancel, handler: nil)
            
            alert.addAction(actOK)
            alert.addAction(actCancel)
            
            self.present(alert, animated: true, completion: nil)
        } else {
            self.doSave(filename: editFile!.filename)
        }
    }
    
    func doSave(filename:String) {
        
        if  editFile == nil {
            var samename = false
            if checkSameNameBlock != nil {
                samename = checkSameNameBlock!(filename)
            }
            if samename {
                YKAlert.showAlert(message: YKLocalizedString("已存在同名文件,是否覆盖?"), okTitle: YKLocalizedString("覆盖"), okBlock: { () in
                    DispatchQueue.main.async {
                        self.save(filename)
                    }
                }, cancelBlock: nil, vc: self)
            } else {
                self.save(filename)
            }
        } else {
            self.save(filename)
        }
    }
    
    func save(_ filename:String) {
        
        var content = "" //self.textView.text
        
        for i in 0...10*1024 {
            content.append("\(i%11)")
        }
        content.append("7")
        
        if let d  = content.data(using: .utf8) {
            completionBlock(filename,d,self)
        }
    }
    
    //MARK: UITextViewDelegate
    func textViewDidChange(_ textView: UITextView) {
        if originContent != nil {
            self.navigationItem.rightBarButtonItem?.isEnabled = (originContent! != textView.text)
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = !textView.text.isEmpty
        }
    }
}
