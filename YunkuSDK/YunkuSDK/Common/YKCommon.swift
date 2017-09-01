//
//  YKCommon.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/9.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit
import gkutility
import gknet


let YKAlertSizeWWAN: Int64 = 5*1024*1024
let YKAlertSizeWifi: Int64 = 100*1024*1024

let YKMEMBER_AVATER_URLFORMAT = ""


enum YKSelectIconType {
    case None
    case Selected
    case UnSelected
    case Disable
    case DiableSelected
    case Hidden
}

enum YKSelectMode {
    case None
    case Single
    case Multi
}

enum YKSelectExcludeType {
    case None
    case Special
    case Block
}



class YKBaseDisplayConfig {
    
    static let SelectChangeNotification = "YKSelectChangeNotification"
    
    var selectMode: YKSelectMode = .None
    var selectCancelBlock: ((UIViewController?)->Void)?
    var selectFinishBlock: (([Any],UIViewController?)->Void)?
    var selectTitle = ""
    var selectCancelTitle = YKLocalizedString("取消")
    var selectConfirmTitle = YKLocalizedString("确定")
    
    var selectedData = [Any]()
    
    var excludeType: YKSelectExcludeType = .None
    var excludeList: [Any]?
    var excludeBlock: ((Any)->Bool)?
    
    var selectLimit = 0
    
    var isembeed = false
    var allowSearch = false
    
}

class YKFileDisplayConfig: YKBaseDisplayConfig {
    
    //选择模式下的选择类型,分选择库,选择文件,选择文件夹和选择路径
    enum SelectType {
        case Mount
        case File
        case Dir
        case FileDir
        case Path
    }
    
    //非选择模式下的显示类型,用于库列表或文件列表
    enum Operation {
        case Normal
        case Copy
        case Move
        case Save
        case OpenShare
        case Fav
        case Members //通过库选择成员,用于库列表
    }
    
    var selectType: SelectType = .File
    var op: Operation = .Normal
    
    //空表示从库列表目录进入
    var rootPath: (mountID:Int,path:String)?
    
    let compareblock = { (item1: Any, item2: Any) -> Bool in
        
        if item1 is GKMountDataItem && item2 is GKMountDataItem {
            return (item1 as! GKMountDataItem).mount_id ==  (item2 as! GKMountDataItem).mount_id
        } else if item1 is GKFileDataItem && item2 is GKFileDataItem {
            let f1: GKFileDataItem = item1 as! GKFileDataItem
            let f2: GKFileDataItem = item2 as! GKFileDataItem
            return (f1.mount_id == f2.mount_id && f1.uuidhash == f2.uuidhash)
        }
        
        return false
    }
    
    deinit {
        //print("config deinit")
    }
    
    func changeSelectData(item:Any,add: Bool, vc: UIViewController?) {
        if add {
            self.selectedData.append(item)
        } else {
            for index in 0..<selectedData.count {
                let m = selectedData[index]
                if compareblock(item,m) {
                    selectedData.remove(at: index)
                    break
                }
            }
        }
        
        let str = self.getSelectBarStr()
        
        if vc != nil {
            let bar = vc?.navigationItem.rightBarButtonItem
            let newbar = UIBarButtonItem(title: str, style: .plain, target: bar?.target, action: bar?.action)
            newbar.isEnabled = (selectedData.count > 0)
            vc!.navigationItem.rightBarButtonItem = newbar
        }
        
        NotificationCenter.default.post(name: Notification.Name(YKBaseDisplayConfig.SelectChangeNotification), object: nil)
    }
    
    func getSelectBarStr() -> String {
        var pre = self.selectConfirmTitle
        if pre.isEmpty {
            pre = YKLocalizedString("确定")
        }
        let str = pre + ((selectedData.count > 0) ? "(\(selectedData.count))" : "")
        return str
    }
    
    func checkFileIsExclude(file: Any) -> Bool {
        switch excludeType {
        case .Special:
            if self.excludeList != nil {
                
                for item in excludeList! {
                    if compareblock(file,item) {
                        return true
                    }
                }
                
            }
        case .Block:
            if excludeBlock != nil {
                if excludeBlock!(file) {
                    return true
                }
            }
        default:
            return false
        }
        return false
    }
    
    func checkHasSelected(file: Any) -> Bool {
        if selectedData.isEmpty { return false }
        for item in selectedData {
            if compareblock(item,file) {
                return true
            }
        }
        return false
    }
}

func YKLocalizedString(_ key: String, _ value:String? = nil) -> String {
    if let bundle = YKAppDelegate.shareInstance.languageBundle {
        return bundle.localizedString(forKey: key, value: value, table: nil)
    } else {
        return key
    }
}

func YKImage(_ name: String, _ ext: String? = nil, _ parent: String? = nil) -> UIImage? {
    if let bundle = YKAppDelegate.shareInstance.resourceBundle {
        var path = bundle.bundlePath.gkAddLastSlash
        var theparent = ""
        var fname = name
        if parent != nil {
            theparent = parent!
        } else {
            let temp = name.gkParentPath
            if !temp.isEmpty {
                theparent = temp
                fname = name.gkFileName
            }
        }
        if !theparent.isEmpty {
            path.append(theparent)
            path = path.gkAddLastSlash
        }
        var filename = fname
        let strext = (ext ?? "png")
        if !filename.contains(".") {
            if !filename.contains("@") {
                let x = Int(UIScreen.main.scale)
                if x > 1 {
                    filename.append("@\(Int(UIScreen.main.scale))x.\(strext)")
                } else {
                    filename.append(".\(strext)")
                }
                
                let p = path.appending("\(filename)")
                if !FileManager.default.fileExists(atPath: p) {
                    filename = fname.appending(".\(strext)")
                }
                
                
            } else {
                filename.append(".\(strext)")
            }
        }
        
        return UIImage(contentsOfFile: path.appending("\(filename)"))
    } else {
        return nil
    }
}


func YKSafePostNotification(_ name: String,_ object:Any? = nil,_ userInfo:[AnyHashable:Any]? = nil) {
    
    if Thread.isMainThread {
        NotificationCenter.default.post(name: Notification.Name(name), object: object, userInfo: userInfo)
    } else {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(name), object: object, userInfo: userInfo)
        }
    }
    
}




class YKCommon {
    
    private static let imageExts = ";jpg;jpeg;png;gif;bmp;"
    
    private static let convertPreviewExts = ";doc;docx;xls;ppt;pptx;"
    
    class func isSupportImage(_ filename: String) -> Bool {
        let ext = (filename as NSString).pathExtension
        if imageExts.contains(";\(ext);") {
            return true
        }
        return false
    }
    
    class func needConvertPreview(filename: String) -> Bool {
        var ext = filename.gkExt
        if ext.isEmpty { return false }
        ext = ";\(ext);"
        return convertPreviewExts.contains(ext)
    }
    
    @inline(__always) class func avatarURL(memberID: Int, entID: Int, size: Int = 96) -> URL? {
        
        let str = (YKClient.shareInstance.https ? "https://" : "http://") + YKClient.shareInstance.webHost + "index/avatar?id=\(memberID)&ent_id=\(entID)&size=\(size)"
        return URL(string: str)
    }
    
    class func verifyFilename(_ filename: String) -> String? {
        let name = filename.gkTrimSpace
        if name.isEmpty {
            return YKLocalizedString("名称不能为空")
        } else if name.characters.count > 255 {
            return YKLocalizedString("文件名过长")
        }
        
        let range = (name as NSString).range(of: "/|\\:|\\*|\\?|\"|\\\\|<|>|\\|", options: .regularExpression)
        if range.location != NSNotFound {
            return YKLocalizedString("请不要在名称中使用 / \\ : * ? \" < > |")
        }
        
        return nil
    }
}
