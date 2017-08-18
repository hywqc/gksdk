//
//  GKNavigationController.swift
//  testsw
//
//  Created by wqc on 2017/8/8.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit

class GKNavigationController :  UINavigationController {
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
}

class GKMessageListNav: GKNavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        self.tabBarItem.title = GKLocalizedString("消息")
        self.tabBarItem.image = GKImage("messageTab")
        self.tabBarItem.selectedImage = GKImage("messageTabSelect")
    }
}

class GKMountListNav: GKNavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        self.tabBarItem.title = GKLocalizedString("文件")
        self.tabBarItem.image = GKImage("fileTab")
        self.tabBarItem.selectedImage = GKImage("fileTabSelect")
    }
}

class GKContactNav: GKNavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        self.tabBarItem.title = GKLocalizedString("通讯录")
        self.tabBarItem.image = GKImage("contactTab")
        self.tabBarItem.selectedImage = GKImage("contactTabSelect")
    }
}

class GKSettingNav: GKNavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        self.tabBarItem.title = GKLocalizedString("设置")
        self.tabBarItem.image = GKImage("settingTab")
        self.tabBarItem.selectedImage = GKImage("settingTabSelect")
    }
}
