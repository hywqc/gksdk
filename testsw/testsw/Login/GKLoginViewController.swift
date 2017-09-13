//
//  GKLoginViewController.swift
//  testsw
//
//  Created by wqc on 2017/8/1.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit
import gkutility
import gknet
import YunkuSDK

class GKLoginViewController : GKBaseViewController {
    
    var loginButton: UIButton!
    var accountTextField: UITextField!
    var passwordTextField: UITextField!
    
    
    var peddingAccounts = [GKRequestAccountInfo]()
    
    private let BlueDisable = GKColor.Hex(0x00a0e9,0.3)
    
    var test = ""
    
    override func viewDidLoad() {
        
        self.view.backgroundColor = GKColor.BKG
        self.title = GKLocalizedString("登录")
        
        NotificationCenter.default.addObserver(self, selector: #selector(onTextFieldChanged(notification:)), name: NSNotification.Name.UITextFieldTextDidChange, object: nil)
        
        peddingAccounts = YKClient.shareInstance.getPeddingLoginRecord()
        
        self.setupViews()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func onBack(sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func onBtnLogin(sender: UIButton) {
        
        accountTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        var userName = accountTextField.text ?? ""
        var password = passwordTextField.text ?? ""
        
        if userName.isEmpty || password.isEmpty {
            AlertUtility.showAlert(message: GKLocalizedString("账号或密码不能为空"), vc: self)
            return
        }
        
        userName = userName.gkTrimSpace
        password = password.gkMD5
        
        self.loginButton.setTitle(GKLocalizedString("正在登录..."), for: .normal)
        
        YKClient.shareInstance.login(account: userName, password: password) { [weak self] (code:Int, msg:String) in
            self?.loginButton.setTitle(GKLocalizedString("登录"), for: .normal)
            if code == YKErrorCode_OK {
                MainViewController.show()
            } else {
                AlertUtility.showAlert(message: msg, vc: self)
            }
        }
    }
    
    @objc func onForgetPassword(gesture: UIGestureRecognizer) {
        
    }
    
    func onTextFieldChanged(notification: Notification) {
        
        if let textField = notification.object as? UITextField {
            if textField === accountTextField || textField === passwordTextField {
                let u = accountTextField.text ?? ""
                let p = passwordTextField.text ?? ""
                
                if u.isEmpty || p.isEmpty {
                    self.loginButton.isEnabled = false
                    self.loginButton.backgroundColor = BlueDisable
                } else {
                    self.loginButton.isEnabled = true
                    self.loginButton.backgroundColor = GKColor.Blue
                }
            }
        }
    }
    
    func setupViews() {
        
        let sz = self.view.frame.size
        
        let titleLabel = UILabel(frame: CGRect(x: (sz.width-100)/2, y: 20, width: 100, height: 44))
        titleLabel.textColor = GKColor.Title
        titleLabel.text = self.title
        titleLabel.textAlignment = .center
        titleLabel.font = GKFont(18)
        self.view.addSubview(titleLabel)
        
        var button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 20, width: 44, height: 44)
        button.setImage(UIImage(named: "back"),for: .normal)
        button.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(onBack(sender:)), for: .touchUpInside)
        self.view.addSubview(button)
        
        
        let onePixel = 1.0/UIScreen.main.scale
        let line = UIView(frame: CGRect(x: 0, y: 64, width: sz.width, height: onePixel))
        line.isOpaque = true
        line.backgroundColor = GKColor.Separator
        self.view.addSubview(line)
        
        
        var rect = CGRect(x: (sz.width-74)/2, y: (gkutility.isPad() ? 220 : 150), width: 74, height: 74)
        let logo = UIImageView(frame: rect)
        logo.image =  UIImage(named: "loginAvatar.png")
        logo.contentMode = .scaleAspectFit
        self.view.addSubview(logo)
        
        rect.origin.y = rect.maxY + 20
        rect.origin.x = 15
        rect.size = CGSize(width: sz.width-rect.origin.x*2, height: 48)
        var textField = UITextField(frame: rect)
        textField.backgroundColor = UIColor.white
        textField.textColor = GKColor.Title
        textField.font = GKFont(15)
        textField.leftViewMode = .always
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        textField.returnKeyType = .done
        textField.layer.cornerRadius = 8
        textField.placeholder = GKLocalizedString("请输入账号/邮箱")
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        self.view.addSubview(textField)
        self.accountTextField = textField
        
        if !peddingAccounts.isEmpty {
            textField.text = peddingAccounts[0].member_email
        }
        
        rect.origin.y = rect.maxY + 12
        textField = UITextField(frame: rect)
        textField.backgroundColor = UIColor.white
        textField.textColor = GKColor.Title
        textField.font = GKFont(15)
        textField.leftViewMode = .always
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        textField.returnKeyType = .done
        textField.layer.cornerRadius = 8
        textField.placeholder = GKLocalizedString("请输入密码")
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.isSecureTextEntry = true
        self.view.addSubview(textField)
        self.passwordTextField = textField
        
        rect.origin.y = rect.maxY + 15
        rect.origin.x = (sz.width - 320)/2
        rect.size = CGSize(width: 320, height: 48)
        button = UIButton(type: .custom)
        button.backgroundColor = BlueDisable
        button.setTitle(GKLocalizedString("登录"), for: .normal)
        button.titleLabel?.font = GKFont(17)
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 8.0
        button.frame = rect
        button.isEnabled = false
        button.addTarget(self, action: #selector(onBtnLogin(sender:)), for: .touchUpInside)
        self.view.addSubview(button)
        self.loginButton = button
        
        rect.origin.y = rect.maxY + 20
        rect.origin.x = (sz.width - 150)/2.0
        rect.size = CGSize(width: 150, height: 25)
        let label = UILabel(frame: rect)
        label.textColor = GKColor.RGBA(162, 162, 162)
        label.text = GKLocalizedString("忘记密码?")
        label.textAlignment = .center
        label.font = GKFont(14)
        label.isUserInteractionEnabled = true
        self.view.addSubview(label)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onForgetPassword(gesture:)))
        label.addGestureRecognizer(tapGesture)
    }
    
}
