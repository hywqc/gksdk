//
//  MainViewController.swift
//  testsw
//
//  Created by wqc on 2017/8/9.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit
import YunkuSDK

class MainViewController: UITabBarController {
    
    
    init(config: [AnyHashable:Any]?) {
        
        super.init(nibName: nil, bundle: nil)
        
        let messagevc = YKClient.shareInstance.getMessageViewController()
        let nav1 = GKMessageListNav(rootViewController: messagevc)
        
        let filevc = YKClient.shareInstance.getMountListViewController()
        let nav2 = GKMountListNav(rootViewController: filevc)
        
        let contactvc = YKClient.shareInstance.getContactViewController()
        let nav3 = GKContactNav(rootViewController: contactvc)
        
        let settingvc = YKClient.shareInstance.getSettingViewController()
        let nav4 = GKMessageListNav(rootViewController: settingvc)
        
        self.viewControllers = [nav1,nav2,nav3,nav4]
        
        self.selectedIndex = 1
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    class func show() {
        
        let mainvc = MainViewController(config: nil)
        let window = XAPPDELEGATE.window
        window?.rootViewController = mainvc
        window?.makeKeyAndVisible()
    }
}
