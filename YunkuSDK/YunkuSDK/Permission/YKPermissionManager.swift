//
//  YKPermissionManager.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/15.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation

typealias YKPermissions = Array<String>

let YKPermission_ls     = "ls"        //显示
let YKPermission_cd     = "cd"        //进入目录
let YKPermission_pv     = "pv"        //预览文件
let YKPermission_dl     = "dl"        //下载打开文件
let YKPermission_w      = "w"         //写入编辑文件
let YKPermission_ul     = "ul"        //添加新文件
let YKPermission_mk     = "mk"        //新建文件夹
let YKPermission_ren    = "ren"       //重命名
let YKPermission_rm     = "rm"        //删除
let YKPermission_ln     = "ln"        //外链分享
let YKPermission_h      = "h"         //查看历史版本
let YKPermission_hr     = "hr"        //还原历史版本
let YKPermission_rmk    = "rmk"       //查看评论
let YKPermission_rmka   = "rmka"      //添加评论
let YKPermission_t      = "t"         //添加标签
let YKPermission_trm    = "trm"       //删除标签
let YKPermission_p      = "p"         //查看共享参与人
let YKPermission_ps     = "ps"        //管理共享参与人
let YKPermission_ss     = "ss"        //显示当前项
let YKPermission_sren   = "sren"      //重命名当前项
let YKPermission_srm    = "srm"       //删除当前项
let YKPermission_mls    = "mls"       //修改库设置
let YKPermission_b      = "b"         //查看回收站文件
let YKPermission_br     = "br"        //还原回收站文件
let YKPermission_be     = "be"        //删除/清空回收站
let YKPermission_mln    = "mln"       //管理文件(夹)外链


extension Array where Iterator.Element == String {
    
    @inline(__always) func canShow() -> Bool {
        return self.contains(YKPermission_ls)
    }
    
    @inline(__always) func canEnter() -> Bool {
        return self.contains(YKPermission_cd)
    }
    
    @inline(__always) func canPreview() -> Bool {
        return self.contains(YKPermission_pv)
    }
    
    @inline(__always) func canDownload() -> Bool {
        return self.contains(YKPermission_dl)
    }
    
    @inline(__always) func canWrite() -> Bool {
        return self.contains(YKPermission_w)
    }
    
    @inline(__always) func canAddFile() -> Bool {
        return self.contains(YKPermission_ul)
    }
    
    @inline(__always) func canAddDir() -> Bool {
        return self.contains(YKPermission_mk)
    }
    
    @inline(__always) func canReName() -> Bool {
        return self.contains(YKPermission_ren)
    }
    
    @inline(__always) func canDelete() -> Bool {
        return self.contains(YKPermission_rm)
    }
    
    @inline(__always) func canLink() -> Bool {
        return self.contains(YKPermission_ln)
    }
    
    @inline(__always) func canViewHistory() -> Bool {
        return self.contains(YKPermission_h)
    }
    
    @inline(__always) func canRevertHistory() -> Bool {
        return self.contains(YKPermission_hr)
    }
    
    @inline(__always) func canViewRemark() -> Bool {
        return self.contains(YKPermission_rmk)
    }
    
    @inline(__always) func canAddRemark() -> Bool {
        return self.contains(YKPermission_rmka)
    }
    
    @inline(__always) func canViewLibMembers() -> Bool {
        return self.contains(YKPermission_p)
    }
    
    @inline(__always) func canEditLibMembers() -> Bool {
        return self.contains(YKPermission_ps)
    }
    
    @inline(__always) func canEditLibSetting() -> Bool {
        return self.contains(YKPermission_mls)
    }
}

class YKPermissionManager {
    
    class func conver2to3(permissions:[String]) -> YKPermissions {
        
        return []
    }
    
    class func getFilePermission(mountID: Int, fullpath: String) -> YKPermissions {
        return []
    }
    
    
    private class func check(mountID: Int,fullpath: String, name: String, special:YKPermissions?) -> Bool {
        if special != nil {
            return special!.contains(name)
        }
        let p = getFilePermission(mountID: mountID, fullpath: fullpath)
        return p.contains(name)
    }
    
    class func checkShow(mountID: Int,fullpath: String, special:YKPermissions?) -> Bool {
        return check(mountID: mountID, fullpath: fullpath, name: YKPermission_ls, special: special)
    }
    
    class func checkEnter(mountID: Int,fullpath: String, special:YKPermissions?) -> Bool {
        return check(mountID: mountID, fullpath: fullpath, name: YKPermission_cd, special: special)
    }
}

