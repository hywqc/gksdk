//
//  YKBaseViewController.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/8.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation

class YKBaseViewController : UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        self.view.backgroundColor = YKColor.BKG
        
        let bar = UIBarButtonItem()
        bar.title = nil
        self.navigationItem.backBarButtonItem = bar
    }
    
    func setNavTitle(_ title: String) {
        self.navigationItem.title = title
    }

}
