//
//  YKAlert.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/24.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit

fileprivate let DefaultTitle = YKLocalizedString("提示")
fileprivate let DefaultOKTitle = YKLocalizedString("确定")
fileprivate let DefaultCancelTitle = YKLocalizedString("取消")

class YKAlert {
    
    class func showAlert(message:String, title: String, okTitle: String, destructive:Bool , cancelTitle: String, okBlock:((Void)->Void)?, cancelBlock:((Void)->Void)?, vc: UIViewController?) {
        
        let alert = UIAlertController(title: (title.isEmpty ? DefaultTitle : title), message: message, preferredStyle: .alert)
        
        let actOK = UIAlertAction(title: (okTitle.isEmpty ? DefaultOKTitle : okTitle), style: (destructive ? .destructive : .default)) { (act:UIAlertAction) in
            okBlock?()
        }
        
        let actCancel = UIAlertAction(title: (cancelTitle.isEmpty ? DefaultCancelTitle : cancelTitle), style: .cancel) { (act:UIAlertAction) in
            cancelBlock?()
        }
        
        alert.addAction(actOK)
        alert.addAction(actCancel)
        
        vc?.present(alert, animated: true, completion: nil)
    }
    
    class func showAlert(message:String, okTitle: String ,destructive:Bool, okBlock:((Void)->Void)?, cancelBlock:((Void)->Void)?, vc: UIViewController?) {
        self.showAlert(message: message, title: DefaultTitle, okTitle: okTitle, destructive: destructive, cancelTitle: DefaultCancelTitle, okBlock: okBlock, cancelBlock: cancelBlock, vc: vc)
    }
    
    class func showAlert(message:String, title: String, okTitle: String , cancelTitle: String, okBlock:((Void)->Void)?, cancelBlock:((Void)->Void)?, vc: UIViewController?) {
        self.showAlert(message: message, title: title, okTitle: okTitle, destructive: false, cancelTitle: cancelTitle, okBlock: okBlock, cancelBlock: cancelBlock, vc: vc)
    }
    
    class func showAlert(message:String, okTitle: String, okBlock:((Void)->Void)?, cancelBlock:((Void)->Void)?, vc: UIViewController?) {
        self.showAlert(message: message, title: DefaultTitle, okTitle: okTitle, destructive: false, cancelTitle: DefaultCancelTitle, okBlock: okBlock, cancelBlock: cancelBlock, vc: vc)
    }
    
    class func showAlert(message:String, vc: UIViewController?) {
        
        let alert = UIAlertController(title: DefaultTitle, message: message, preferredStyle: .alert)
        
        let actOK = UIAlertAction(title: DefaultOKTitle, style: .default) { (act:UIAlertAction) in
            
        }
        
        alert.addAction(actOK)
        
        vc?.present(alert, animated: true, completion: nil)
    }
    
    class func showAlert(message:String, title: String, vc: UIViewController?) {
        self.showAlert(message: message, title: title, okTitle: DefaultOKTitle, destructive: false, cancelTitle: DefaultCancelTitle, okBlock: nil, cancelBlock: nil, vc: vc)
    }
    
    
    class func showHUD(view: UIView?, message: String) {
        if view == nil { return }
        let hud = MBProgressHUD.showAdded(to: view!, animated: true)
        hud.label.text = message
    }
    
    class func hideHUDSuccess(view: UIView?,str:String,animate:Bool) {
        if view == nil { return }
        var hud: MBProgressHUD?
        for v  in view!.subviews {
            if v is MBProgressHUD {
                hud = v as? MBProgressHUD
                break
            }
        }
        if hud != nil {
            hud!.mode = .customView
            hud!.customView = UIImageView(image: YKImage("toastStatusOK"))
            hud!.label.text = str
            hud!.hide(animated: true, afterDelay: 1)
        }
    }
    
    class func hideHUD(view: UIView?,animate:Bool) {
        if view == nil { return }
        MBProgressHUD.hide(for: view!, animated: animate)
    }
    
}
