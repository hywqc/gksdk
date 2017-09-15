//
//  GKShareViewController.swift
//  testsw
//
//  Created by wqc on 2017/9/12.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit
import YunkuSDK

@objc(GKShareViewController)
class GKShareViewController : UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let pathUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        print("share app path: \(pathUrl)")
        YKClient.shareInstance.config(host:"yk3.gokuai.com",client_id: "qDFdSoMJtm6Yb2gAmaigmisc", client_secret: "5QdJ0zqAP1ICDCUGrcxtyloKKQ", https: true, groupID: "group.com.gokuai.wqc.extension", extensionType: YKClient.ExtensionType.Share)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let vc = YKClient.shareInstance.getShareExtensionViewController(title: "够快云库", extensionContext: self.extensionContext!)
        let nav = UINavigationController(rootViewController: vc)
        self.present(nav, animated: true, completion: nil)
    }

}
