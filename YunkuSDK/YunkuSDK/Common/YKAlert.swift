//
//  YKAlert.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/24.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation

fileprivate let DefaultTitle = YKLocalizedString("提示")
fileprivate let DefaultOKTitle = YKLocalizedString("确定")
fileprivate let DefaultCancelTitle = YKLocalizedString("取消")

class YKAlert {
    
    class func showAlert(message:String, title: String? = nil, okTitle: String? = nil, cancelTitle: String? = nil, okBlock:((Void)->Void)? = nil, cancelBlock:((Void)->Void)? = nil, vc: UIViewController?) {
        
        let alert = UIAlertController(title: (title ?? DefaultTitle), message: message, preferredStyle: .alert)
        
        let actOK = UIAlertAction(title: (okTitle ?? DefaultOKTitle), style: .default) { (act:UIAlertAction) in
            okBlock?()
        }
        
        let actCancel = UIAlertAction(title: (cancelTitle ?? DefaultCancelTitle), style: .cancel) { (act:UIAlertAction) in
            cancelBlock?()
        }
        
        alert.addAction(actOK)
        alert.addAction(actCancel)
        
        vc?.present(alert, animated: true, completion: nil)
    }
    
}
