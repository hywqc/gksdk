//
//  YKShareExtensionView.swift
//  YunkuSDK
//
//  Created by wqc on 2017/9/12.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import MobileCoreServices
import gkutility

class YKBaseExtensionViewController: YKBaseTableViewController {
    
    var loginView: UIView?
    var accountTextField: UITextField?
    var passwordTextField: UITextField?
    var loginButton: UIButton?
    private let BlueDisable = YKColor.Hex(0x00a0e9,0.3)
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if YKClient.shareInstance.checkFastLogin() {
            NotificationCenter.default.addObserver(self, selector: #selector(onForceLogout(notification:)), name: NSNotification.Name(YKNotification_ForceLogout), object: nil)
            YKClient.shareInstance.fastLogin(completion: { [weak self] (Int, String) in
                self?.loadData()
            })
        } else {
            self.setNavTitle("登录")
            self.tableView.isHidden = true
            self.showLoginViews()
        }
    }
    
    func loadData() {
        
    }
    
    func showLoginViews() {
        
        self.tableView.isHidden = true
        
        if self.loginView != nil {
            
            self.loginView?.isHidden = false
            return
        }
        
        let sz = self.view.frame.size
        
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: sz.width, height: sz.height))
        
        var rect = CGRect(x: (sz.width-74)/2, y: (gkutility.isPad() ? 220 : 100), width: 74, height: 74)
        let logo = UIImageView(frame: rect)
        logo.image =  YKImage("loginAvatar.png")
        logo.contentMode = .scaleAspectFit
        containerView.addSubview(logo)
        
        rect.origin.y = rect.maxY + 20
        rect.origin.x = 15
        rect.size = CGSize(width: sz.width-rect.origin.x*2, height: 48)
        var textField = UITextField(frame: rect)
        textField.backgroundColor = UIColor.white
        textField.textColor = YKColor.Title
        textField.font = YKFont.make(15)
        textField.leftViewMode = .always
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        textField.returnKeyType = .done
        textField.layer.cornerRadius = 8
        textField.placeholder = YKLocalizedString("请输入账号/邮箱")
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        containerView.addSubview(textField)
        self.accountTextField = textField
        
        rect.origin.y = rect.maxY + 12
        textField = UITextField(frame: rect)
        textField.backgroundColor = UIColor.white
        textField.textColor = YKColor.Title
        textField.font = YKFont.make(15)
        textField.leftViewMode = .always
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        textField.returnKeyType = .done
        textField.layer.cornerRadius = 8
        textField.placeholder = YKLocalizedString("请输入密码")
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.isSecureTextEntry = true
        containerView.addSubview(textField)
        self.passwordTextField = textField
        
        rect.origin.y = rect.maxY + 15
        rect.origin.x = (sz.width - 320)/2
        rect.size = CGSize(width: 320, height: 48)
        let button = UIButton(type: .custom)
        button.backgroundColor = BlueDisable
        button.setTitle(YKLocalizedString("登录"), for: .normal)
        button.titleLabel?.font = YKFont.make(17)
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 8.0
        button.frame = rect
        button.isEnabled = false
        button.addTarget(self, action: #selector(onBtnLogin(sender:)), for: .touchUpInside)
        containerView.addSubview(button)
        self.loginButton = button
        
        rect.origin.y = rect.maxY + 20
        rect.origin.x = (sz.width - 150)/2.0
        rect.size = CGSize(width: 150, height: 25)
        let label = UILabel(frame: rect)
        label.textColor = YKColor.RGBA(162, 162, 162)
        label.text = YKLocalizedString("忘记密码?")
        label.textAlignment = .center
        label.font = YKFont.make(14)
        label.isUserInteractionEnabled = true
        containerView.addSubview(label)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onForgetPassword(gesture:)))
        label.addGestureRecognizer(tapGesture)
        
        self.loginView = containerView
        
        self.view.addSubview(containerView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onTextFieldChanged(notification:)), name: NSNotification.Name.UITextFieldTextDidChange, object: nil)
    }
    
    func onForceLogout(notification:Notification) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(YKNotification_ForceLogout), object: nil)
        var msg = YKLocalizedString("授权已失效")
        if let s = notification.object as? String {
            msg = s
        }
        self.showLoginViews()
        YKAlert.showAlert(message: msg, vc: self)
    }
    
    @objc func onBtnLogin(sender: UIButton) {
        
        accountTextField!.resignFirstResponder()
        passwordTextField!.resignFirstResponder()
        
        var userName = accountTextField!.text ?? ""
        var password = passwordTextField!.text ?? ""
        
        if userName.isEmpty || password.isEmpty {
            YKAlert.showAlert(message: YKLocalizedString("账号或密码不能为空"), vc: self)
            return
        }
        
        userName = userName.gkTrimSpace
        password = password.gkMD5
        
        self.loginButton!.setTitle(YKLocalizedString("正在登录..."), for: .normal)
        
        YKClient.shareInstance.login(account: userName, password: password) { [weak self] (code:Int, msg:String) in
            self?.loginButton!.setTitle(YKLocalizedString("登录"), for: .normal)
            if code == YKErrorCode_OK {
                self?.loadData()
            } else {
                YKAlert.showAlert(message: msg, vc: self)
            }
        }
    }
    
    
    @objc func onForgetPassword(gesture: UIGestureRecognizer) {
        
    }
    
    
    func onTextFieldChanged(notification: Notification) {
        
        if let textField = notification.object as? UITextField {
            if textField === accountTextField! || textField === passwordTextField! {
                let u = accountTextField!.text ?? ""
                let p = passwordTextField!.text ?? ""
                
                if u.isEmpty || p.isEmpty {
                    self.loginButton!.isEnabled = false
                    self.loginButton!.backgroundColor = BlueDisable
                } else {
                    self.loginButton!.isEnabled = true
                    self.loginButton!.backgroundColor = YKColor.Blue
                }
            }
        }
    }
    
    
}
