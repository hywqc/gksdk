//
//  YKTransDefine.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/14.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation

enum YKTransStatus : Int {
    case None = 0
    case Normal
    case Start
    case Finish
    case Stop
    case Error
    case Removed
}


enum YKTransExpand : Int {
    case None = 0
    case Cache
    case Out
    case Open
    case EditUpload
}

class YKDownloadItemData {
    
    var nID = 0
    var mountid = 0
    var webpath = ""
    var parent = ""
    var filename = ""
    var dir = false
    var filehash = ""
    var uuidhash = ""
    var localpath = ""
    var filesize: Int64 = 0
    var offset: Int64 = 0
    var status: YKTransStatus = .None
    var expand: YKTransExpand = .None
    var errcode = 0
    var errmsg = ""
    var errcount = 0
    var hid: String?
    var net: String?
    var convert = false
}

class YKUploadItemData {
    
    var nID = 0
    var mountid = 0
    var webpath = ""
    var parent = ""
    var filename = ""
    var dir = false
    var filehash = ""
    var uuidhash = ""
    var localpath = ""
    var filesize: Int64 = 0
    var offset: Int64 = 0
    var status: YKTransStatus = .None
    var expand: YKTransExpand = .None
    var errcode = 0
    var errmsg = ""
    var errcount = 0
    var editupload = false
}

