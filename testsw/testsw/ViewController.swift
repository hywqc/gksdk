//
//  ViewController.swift
//  testsw
//
//  Created by wqc on 2017/7/24.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit
import gknet
import gkutility
import YunkuSDK


class Base {
    
    required init() {
        
    }
    
    class func born(_ type: Base.Type) ->  Base {
        return type.init()
    }
    
    func foo() {
        print("base foo");
    }
}

class Sub : Base {
    
    override func foo() {
        print("sub foo");
    }
    
}

class Another : Base {
    override func foo() {
        print("another foo");
    }
}

class ViewController: UIViewController {
    
    var titlename = "/ 123 /"
    var bLoginFinish = false
    var loginRet: String = ""
    
    var fetchID: GKRequestID = 0
    
    var completions: [()->Void] = []
    
    func testclosure1(completion: @escaping ()->Void) {
        self.completions.append(completion)
    }
    
    func testclosure2(completion:()->Void) {
        completion()
    }
    
    func startLogin(json: String,completion: @escaping (String)->Void) {
        DispatchQueue.global().async { 
           //
            let ret = ""
            DispatchQueue.main.async {
                self.bLoginFinish = true
                completion(ret)
            }
        }
    }
    
    func say() {
        print("ViewController")
    }
    
    func fun1(def: Bool = false, n: Int) {
        
    }
    
    func testreturn() -> (code:Int,msg:String) {
        return (0,"ok")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let btnlogin = UIButton(type: .custom)
        btnlogin.frame = CGRect(x: 15, y: 100, width: 100, height: 30)
        btnlogin.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btnlogin.setTitle("test", for: .normal)
        btnlogin.setTitleColor(UIColor.black, for: .normal)
        btnlogin.addTarget(self, action: #selector(onLoginBtn(sender:)), for: .touchUpInside)
        self.view.addSubview(btnlogin)
        
        
        let btnCancel = UIButton(type: .custom)
        btnCancel.frame = CGRect(x: 15, y: 150, width: 100, height: 30)
        btnCancel.setTitle("cancel", for: .normal)
        btnCancel.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btnCancel.setTitleColor(UIColor.black, for: .normal)
        btnCancel.addTarget(self, action: #selector(onCancelBtn(sender:)), for: .touchUpInside)
        self.view.addSubview(btnCancel)
        
    }
    
    func onLoginBtn(sender: UIButton) {
        
        YKClient.shareInstance.login(account: "hywqc", password: "Wqc@19870206".gkMD5) { (code:Int, msg:String) in
            if code == YKErrorCode_OK {
                print("login success")
            } else {
                print("login failed: {\(code):\(msg)}")
            }
        }
        
    }
    
    func onCancelBtn(sender: UIButton) {
        GKHttpEngine.default.cancelAll()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

