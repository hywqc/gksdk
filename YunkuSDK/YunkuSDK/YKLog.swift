//
//  YKLog.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/4.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gkutility

class YKLog {
    
    static let shanreLog = YKLog()
    
    var path = ""
    
    var filehanle: FileHandle?
    let queue = DispatchQueue(label: "gklog.queue")
    
    func setpath(_ path:String) {
        self.path = path
        if !gkutility.fileExist(path: path) {
            let _ = gkutility.createFile(path: path, data: nil)
        }
        self.filehanle = FileHandle(forUpdatingAtPath: self.path)
    }
    
    func log(msg:String) {
        self.queue.async {
            if self.filehanle == nil {
                self.filehanle = FileHandle(forUpdatingAtPath: self.path)
            }
            if self.filehanle != nil {
                let time = gkutility.formatDateline(Date().timeIntervalSince1970, format: GKTimeFormatYMDHMS)
                let fullmsg = "\(time) - \(#function) - \(#line) - \(msg) \n"
                self.filehanle!.seekToEndOfFile()
                if let data = fullmsg.data(using: .utf8) {
                    self.filehanle!.write(data)
                }
            }
        }
    }
    
}
