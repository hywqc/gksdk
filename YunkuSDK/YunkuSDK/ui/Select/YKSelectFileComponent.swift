//
//  YKSelectFileComponent.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/16.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit
import gknet

final class YKSelectFileComponent {
    
    class func showSingleMountSelect(title: String?, cancleBlock:((UIViewController?)->Void)?, completion:@escaping ((GKMountDataItem,UIViewController?)->Void), fromVC: UIViewController, showBlock: ((UIViewController)->Void)? = nil ) {
        
        let config = YKFileDisplayConfig()
        config.selectMode = .Single
        config.selectType = .Mount
        if title != nil { config.selectTitle = title! }
        config.selectCancelBlock = cancleBlock
        config.selectFinishBlock = { (result: [Any],vc: UIViewController?) -> Void in
            var item = GKMountDataItem()
            if result.count > 0  {
                if let m = result[0] as? GKMountDataItem {
                    item = m
                }
            }
            completion(item, vc)
        }
        config.allowSearch = true
        
        let controller = YKMountListViewController(datasource: YKMountsDataTableSourceSingleSelect(), config: config)
        if showBlock != nil {
            showBlock!(controller)
        } else {
            let nav = UINavigationController(rootViewController: controller)
            fromVC.present(nav, animated: true, completion: nil)
        }
    }
    
    class func showMultiMountSelect(title: String?, cancleBlock:((UIViewController?)->Void)?, completion:@escaping (([GKMountDataItem],UIViewController?)->Void), fromVC: UIViewController, showBlock: ((UIViewController)->Void)? = nil ) {
        
        let config = YKFileDisplayConfig()
        config.selectMode = .Multi
        config.selectType = .Mount
        if title != nil { config.selectTitle = title! }
        config.selectCancelBlock = cancleBlock
        config.selectFinishBlock = { (result: [Any],vc: UIViewController?) -> Void in
            completion(result as! [GKMountDataItem], vc)
        }
        
        
        let controller = YKMountListViewController(datasource: YKMountsDataTableSourceMultiSelect(), config: config)
        if showBlock != nil {
            showBlock!(controller)
        } else {
            let nav = UINavigationController(rootViewController: controller)
            fromVC.present(nav, animated: true, completion: nil)
        }
    }
    
    
    
    class func showSingleSelect(filetype: Int, mountid: Int?, fullpath: String?, title: String?,cancleBlock:((UIViewController?)->Void)?, completion:@escaping ((GKFileDataItem,UIViewController?)->Void), fromVC: UIViewController) {
        
        let config = YKFileDisplayConfig()
        config.selectMode = .Single
        switch filetype {
        case 0:
            config.selectType = .FileDir
        case 1:
            config.selectType = .File
        default:
            config.selectType = .Dir
        }
        if title != nil { config.selectTitle = title! }
        config.selectCancelBlock = cancleBlock
        config.selectFinishBlock = { (result: [Any],vc: UIViewController?) -> Void in
            var item = GKFileDataItem()
            if result.count > 0  {
                if let m = result[0] as? GKFileDataItem {
                    item = m
                }
            }
            completion(item, vc)
        }
        
        let controller: UIViewController
        if mountid == nil {
            controller = YKMountListViewController(datasource: YKMountsDataTableSourceNormal(), config: config)
        } else {
            controller = YKFileListViewController(mountID: mountid!, fullpath: (fullpath ?? "/"), config: config)
            config.rootPath = (mountid!,(fullpath ?? "/"))
        }
        
        let nav = UINavigationController(rootViewController: controller)
        fromVC.present(nav, animated: true, completion: nil)
    }
    
    class func showSingleFileSelect(mountid: Int?, fullpath: String?, title: String?,cancleBlock:((UIViewController?)->Void)?, completion:@escaping ((GKFileDataItem,UIViewController?)->Void), fromVC: UIViewController) {
        
        showSingleSelect(filetype: 1, mountid: mountid, fullpath: fullpath, title: title, cancleBlock: cancleBlock, completion: completion, fromVC: fromVC)
    }
    
    class func showSingleDirSelect(mountid: Int?, fullpath: String?, title: String?,cancleBlock:((UIViewController?)->Void)?, completion:@escaping ((GKFileDataItem,UIViewController?)->Void), fromVC: UIViewController) {
        
        showSingleSelect(filetype: 2, mountid: mountid, fullpath: fullpath, title: title, cancleBlock: cancleBlock, completion: completion, fromVC: fromVC)
    }
    
    class func showSingleFileAndDirSelect(mountid: Int?, fullpath: String?, title: String?,cancleBlock:((UIViewController?)->Void)?, completion:@escaping ((GKFileDataItem,UIViewController?)->Void), fromVC: UIViewController) {
        
        showSingleSelect(filetype: 0, mountid: mountid, fullpath: fullpath, title: title, cancleBlock: cancleBlock, completion: completion, fromVC: fromVC)
    }
    
    
    class func showMultiSelect(filetype: Int, mountid: Int?, fullpath: String?, title: String?,cancleBlock:((UIViewController?)->Void)?, completion:@escaping (([GKFileDataItem],UIViewController?)->Void), fromVC: UIViewController) {
        
        let config = YKFileDisplayConfig()
        config.selectMode = .Multi
        switch filetype {
        case 0:
            config.selectType = .FileDir
        case 1:
            config.selectType = .File
        default:
            config.selectType = .Dir
        }
        if title != nil { config.selectTitle = title! }
        config.selectCancelBlock = cancleBlock
        config.selectFinishBlock = { (result: [Any],vc: UIViewController?) -> Void in
            completion(result as! [GKFileDataItem], vc)
        }
        
        let controller: UIViewController
        if mountid == nil {
            controller = YKMountListViewController(datasource: YKMountsDataTableSourceNormal(), config: config)
        } else {
            controller = YKFileListViewController(mountID: mountid!, fullpath: (fullpath ?? "/"), config: config)
            config.rootPath = (mountid!,(fullpath ?? "/"))
        }
        
        let nav = UINavigationController(rootViewController: controller)
        fromVC.present(nav, animated: true, completion: nil)
    }
    
    class func showMultiFileSelect(mountid: Int?, fullpath: String?, title: String?,cancleBlock:((UIViewController?)->Void)?, completion:@escaping (([GKFileDataItem],UIViewController?)->Void), fromVC: UIViewController) {
        
        showMultiSelect(filetype: 1, mountid: mountid, fullpath: fullpath, title: title, cancleBlock: cancleBlock, completion: completion, fromVC: fromVC)
    }
    
    class func showMultiDirSelect(mountid: Int?, fullpath: String?, title: String?,cancleBlock:((UIViewController?)->Void)?, completion:@escaping (([GKFileDataItem],UIViewController?)->Void), fromVC: UIViewController) {
        
        showMultiSelect(filetype: 2, mountid: mountid, fullpath: fullpath, title: title, cancleBlock: cancleBlock, completion: completion, fromVC: fromVC)
    }
    
    class func showMultiFileAndDirSelect(mountid: Int?, fullpath: String?, title: String?,cancleBlock:((UIViewController?)->Void)?, completion:@escaping (([GKFileDataItem],UIViewController?)->Void), fromVC: UIViewController) {
        
        showMultiSelect(filetype: 0, mountid: mountid, fullpath: fullpath, title: title, cancleBlock: cancleBlock, completion: completion, fromVC: fromVC)
    }
    
    
    class func showCopySelect(mountid: Int, files:[GKFileDataItem],fromVC: UIViewController) {
        
        let config = YKFileDisplayConfig()
        
        config.selectMode = .None
        config.op = .Copy
        config.fromMountID = mountid
        config.sourceFiles = files
        
        let controller = YKMountListViewController(datasource: YKMountsDataTableSourceNormal(), config: config)
        let nav = UINavigationController(rootViewController: controller)
        fromVC.present(nav, animated: true, completion: nil)
    }
    
    class func showMoveSelect(mountid: Int, files:[GKFileDataItem],fromVC: UIViewController,completion: (([GKFileDataItem],String)->Void)?) {
        
        let config = YKFileDisplayConfig()
        
        config.selectMode = .None
        config.op = .Move
        config.fromMountID = mountid
        config.sourceFiles = files
        config.operationCompletion = completion
        
        let controller = YKFileListViewController(mountID: mountid, fullpath: "/", config: config)
        
        let nav = UINavigationController(rootViewController: controller)
        fromVC.present(nav, animated: true, completion: nil)
    }
}
