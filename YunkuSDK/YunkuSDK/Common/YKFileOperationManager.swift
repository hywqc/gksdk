//
//  YKFileOperationManager.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/22.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gknet

final class YKFileOperationManager {
    
    static let shareManager = YKFileOperationManager()
    
    private init() {
        
    }

    
    class func addFileFolder() {
        
    }
    
    class func addFilePhoto() {
        
    }
    
    class func addFileCamera() {
        
    }
    
    func showTextEdit(fromVC:UIViewController,originContent:String? = nil ,editFile: GKFileDataItem? = nil,checkSameNameBlock:((String)->Bool)? = nil, cancelBlock: ((UIViewController?)->Void)? = nil, completion: @escaping ((String,Data,UIViewController?)->Void)) {
        
        let controller = YKTextViewController(completionBlock: completion, cancelBlock: cancelBlock, checkSameNameBlock: checkSameNameBlock, originContent: originContent, editFile: editFile)
        let nav = UINavigationController(rootViewController: controller)
        fromVC.present(nav, animated: true, completion: nil)
    }
    
    class func addFileAudio() {
        
    }
    
    class func addFileScan() {
        
    }
    
}
