//
//  GKLoginHomeController.swift
//  testsw
//
//  Created by wqc on 2017/8/8.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit
import gkutility

class GKLoginHomeController : GKBaseViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = GKColor.BKG
        
        self.setupViews()
    }
    
    func setupViews() {
        
        let sz = self.view.frame.size
        
        var rect = CGRect(x: (sz.width-120)/2, y: (gkutility.isPad() ? 150 : 100), width: 120, height: 160)
        let logo = UIImageView(frame: rect)
        logo.image = UIImage(named: "loginLogo.png")
        logo.contentMode = .scaleAspectFit
        self.view.addSubview(logo)
        
        rect.origin.y = rect.maxY + 10
        rect.origin.x = 15
        rect.size = CGSize(width: sz.width-rect.origin.x*2, height: 40)
        let titleLabel = UILabel(frame: rect)
        titleLabel.textColor = UIColor.darkGray
        titleLabel.text = "够快云库"
        titleLabel.textAlignment = .center
        titleLabel.font = GKFont(25)
        self.view.addSubview(titleLabel)
        
        rect.origin.y = rect.maxY + 40
        rect.origin.x = (sz.width - 320)/2
        rect.size = CGSize(width: 320, height: 48)
        var button = UIButton(type: .custom)
        button.backgroundColor = GKColor.Blue
        button.setTitle(GKLocalizedString("登录"), for: .normal)
        button.titleLabel?.font = GKFont(17)
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 8.0
        button.frame = rect
        self.view.addSubview(button)
        
        button.addTarget(self, action: #selector(onLoginButton(sender:)), for: .touchUpInside)
        
        rect.origin.y = rect.maxY + 12
        button = UIButton(type: .custom)
        button.backgroundColor = UIColor.white
        button.setTitle(GKLocalizedString("创建新的企业"), for: .normal)
        button.titleLabel?.font = GKFont(17)
        button.setTitleColor(GKColor.Hex(0x333333), for: .normal)
        button.layer.cornerRadius = 8.0
        button.frame = rect
        self.view.addSubview(button)
        
        button.addTarget(self, action: #selector(onRegisterButton(sender:)), for: .touchUpInside)
    }
    
    @objc func onLoginButton(sender:UIButton) {
        
        let vc = GKLoginViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func onRegisterButton(sender:UIButton) {
        
    }
}
