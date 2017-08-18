//
//  AlertUtility.swift
//  testsw
//
//  Created by wqc on 2017/8/9.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit

fileprivate let DefaultTitle = GKLocalizedString("提示")
fileprivate let DefaultOKTitle = GKLocalizedString("确定")
fileprivate let DefaultCancelTitle = GKLocalizedString("取消")

class AlertUtility {
    
    class func showAlert(message:String, title: String = DefaultTitle, okTitle: String = DefaultOKTitle, cancelTitle: String = DefaultCancelTitle, okBlock:((Void)->Void)? = nil, cancelBlock:((Void)->Void)? = nil, vc: UIViewController?) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let actOK = UIAlertAction(title: okTitle, style: .default) { (act:UIAlertAction) in
            okBlock?()
        }
        
        let actCancel = UIAlertAction(title: cancelTitle, style: .cancel) { (act:UIAlertAction) in
            cancelBlock?()
        }
        
        alert.addAction(actOK)
        alert.addAction(actCancel)
        
        vc?.present(alert, animated: true, completion: nil)
    }
    
}
