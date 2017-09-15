//
//  gkHttpEngine.swift
//  gknet
//
//  Created by wqc on 2017/7/24.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gkutility



fileprivate let kTokenInvalidCode = 40101
fileprivate let kTokenExpiredCode = 40102
fileprivate let kTryCount: Int = 3


public class GKHttpEngine : GKHttpBaseSession {
    
    @objc(shareInstance)
    public static let `default` = GKHttpEngine()
    
    var serverInfo: GKServerInfo!
    private var clientInfo: String = ""
    private var deviceID: String = ""
    
    private var bStop = false
    
    private var access_token: String = ""
    private var refresh_token: String = ""
    
    public func setToken(_ token: String, _ refreshToken: String) {
        access_token = token
        refresh_token = refreshToken
    }
    
    
    public var refreshTokenNotifyCallback: ((String,String,Int?,String?)->Void)?
    
    public func configServerInfo(_ serverInfo: GKServerInfo, deviceID: String,errorLog: GKRequestLogger? = nil ) {
        
        self.serverInfo = serverInfo
        self.errorLog = errorLog
        self.deviceID = deviceID
        
        let brand = UIDevice.current.model
        let version = UIDevice.current.systemName+UIDevice.current.systemVersion
        let display = UIDevice.current.name
        let info = ["BRAND":brand,
                    "VERSION":version,
                    "DISPLAY":display,
                    "CLIENT_ID":(serverInfo.clientID)]
        clientInfo = info.gkStr
        
    }
    
    public func exit() {
        self.bStop = true
    }
    
    private func sign(_ param: [String:String]) -> String {
        return param.gkSign(key: serverInfo.clientSecret)
    }
    
    private func generateurl(_ url: String) -> String {
        
        if url.hasPrefix("https://") {
            if serverInfo.https {
                return url
            } else {
                let r = Range(uncheckedBounds: (lower: url.startIndex, upper: url.characters.index(url.startIndex, offsetBy: 6)))
                return url.replacingCharacters(in: r, with: "http:")
            }
        } else if url.hasPrefix("http://") {
            if !serverInfo.https {
                return url
            } else {
                let r = Range(uncheckedBounds: (lower: url.startIndex, upper: url.characters.index(url.startIndex, offsetBy: 5)))
                return url.replacingCharacters(in: r, with: "https:")
            }
        } else {
            return serverInfo.fullApiURL(path:url)
        }
    }
    
    public func refreshToken() -> GKRequestRetToken {
        
        var param = ["grant_type":"refresh_token",
                     "refresh_token":refresh_token,
                     "info":clientInfo,
                     "device":deviceID,
                     "client_id":serverInfo.clientID]
        let d: Int64 = Int64(Date().timeIntervalSince1970)
        param["dateline"] = "\(d)"
        param["sign"] = sign(param)
        
        let ret = self.POST(url: generateurl(GKAPI.OAUTH_TOKEN), headers: nil, param: param, reqType: GKRequestRetToken.self)
        let retToken = ret as! GKRequestRetToken
        
        if retToken.statuscode == 200 {
            self.access_token = retToken.accessToken
            self.refresh_token = retToken.refreshToken
            
            print("refresh token: \(retToken.accessToken)");
            
            refreshTokenNotifyCallback?(retToken.accessToken,retToken.refreshToken,nil,nil)
            
        } else {
            refreshTokenNotifyCallback?("","",retToken.errcode,retToken.errmsg)
        }
        
        return retToken
    }
    
    public func login(account: String, password: String) -> GKRequestRetToken {
        
        assert(serverInfo != nil,"you should config server info first")
        
        var param = ["grant_type":"password",
                     "username":account,
                     "password":password,
                     "device":deviceID,
                     "info":clientInfo,
                     "client_id":serverInfo.clientID]
        param["sign"] = sign(param)
        
        let ret = self.POST(url: generateurl(GKAPI.OAUTH_TOKEN), headers: nil, param: param, reqType: GKRequestRetToken.self) as! GKRequestRetToken
        if ret.statuscode == 200 {
            self.access_token = ret.accessToken
            self.refresh_token = ret.refreshToken
        }
        return ret
    }
    
    public func fetchSource(_: String) -> GKRequestRetSource {
        
        assert(serverInfo != nil,"you should config server info first")
        
        var param = ["source":"wanda",
                     "client_id":serverInfo.clientID]
        param["sign"] = sign(param)
        
        let ret = self.GET(url: generateurl(GKAPI.SOURCE_INFO), headers: nil, param: param, reqType: GKRequestRetSource.self)
        return ret as! GKRequestRetSource
    }
    
    public func fetchAccountInfo() -> GKRequestAccountInfo {
        var result: GKRequestAccountInfo!
        for _ in 0..<kTryCount {
            var param = ["token":access_token]
            param["sign"] = sign(param)
            
            result = self.POST(url: generateurl(GKAPI.ACCOUNT_INFO), headers: nil, param: param, reqType: GKRequestAccountInfo.self) as! GKRequestAccountInfo
            if result.statuscode == 200 {
                break
            } else if result.errcode == kTokenExpiredCode || result.errcode == kTokenInvalidCode {
                if bStop { break }
                let _ = self.refreshToken()
            }
        }
        return result
    }
    
    public func fetchEnts() -> GKRequestRetEnts {
        
        var result: GKRequestRetEnts!
        for _ in 0..<kTryCount {
            var param = ["token":access_token]
            param["sign"] = sign(param)
            
            result = self.GET(url: generateurl(GKAPI.ENTS), headers: nil, param: param, reqType: GKRequestRetEnts.self) as! GKRequestRetEnts
            if result.statuscode == 200 {
                break
            } else if result.errcode == kTokenExpiredCode || result.errcode == kTokenInvalidCode {
                if bStop { break }
                let _ = self.refreshToken()
            }
        }
        
        return result
    }
    
    public func fetchEnts(reget:Bool = false, completion: ((GKRequestRetEnts)->Void)?) -> GKRequestID {
        
        var param = ["token":access_token]
        param["sign"] = sign(param)
        let taskID = self.GET(url: generateurl(GKAPI.ENTS), headers: nil, param: param, completion: { (ret: GKRequestBaseRet) in
            let temp = ret as! GKRequestRetEnts
            if (ret.statuscode == kTokenExpiredCode || ret.statuscode == kTokenInvalidCode) && !self.bStop{
                let _ = self.refreshToken()
                let _ = self.fetchEnts(reget:true, completion: completion)
            } else {
                completion?(temp)
            }
        }, reqType: GKRequestRetEnts.self)
        return taskID
    }
    
    public func fetchMounts(org_id: String?) -> GKRequestRetMounts {
        
        var result: GKRequestRetMounts!
        for _ in 0..<kTryCount {
            var param = ["token":access_token]
            if org_id != nil { param["org_id"] = org_id! }
            param["sign"] = sign(param)
            
            result = self.GET(url: generateurl(GKAPI.MOUNTS), headers: nil, param: param, reqType: GKRequestRetMounts.self) as! GKRequestRetMounts
            if result.statuscode == 200 {
                break
            } else if result.errcode == kTokenExpiredCode || result.errcode == kTokenInvalidCode {
                if bStop { break }
                let _ = self.refreshToken()
            }
        }
        
        if bStop {
            result.errcode = GKOperationExitCode
        }
        
        return result
    }
    
    public func fetchMounts(reget:Bool = false,org_id: String?, completion: ((GKRequestRetMounts)->Void)?) -> GKRequestID {
        
        var param = ["token":access_token]
        if org_id != nil { param["org_id"] = org_id! }
        param["sign"] = sign(param)
        let taskID = self.GET(url: generateurl(GKAPI.MOUNTS), headers: nil, param: param, completion: { (ret: GKRequestBaseRet) in
            let temp = ret as! GKRequestRetMounts
            if (ret.statuscode == kTokenExpiredCode || ret.statuscode == kTokenInvalidCode) && !self.bStop{
                let _ = self.refreshToken()
                let _ = self.fetchMounts(reget:true, org_id: org_id, completion: completion)
            } else {
                completion?(temp)
            }
        }, reqType: GKRequestRetMounts.self)
        return taskID
    }
    
    public func fetchShortcuts() -> GKRequestRetShortcuts {
        
        var result: GKRequestRetShortcuts!
        for _ in 0..<kTryCount {
            var param = ["token":access_token]
            param["sign"] = sign(param)
            
            result = self.GET(url: generateurl(GKAPI.SHORTCUTS), headers: nil, param: param, reqType: GKRequestRetShortcuts.self) as! GKRequestRetShortcuts
            if result.statuscode == 200 {
                break
            } else if result.errcode == kTokenExpiredCode || result.errcode == kTokenInvalidCode {
                if bStop { break }
                let _ = self.refreshToken()
            }
        }
        
        if bStop {
            result.errcode = GKOperationExitCode
        }
        
        return result
    }
    
    public func fetchFileList(mountID: Int, fullpath: String, dir: Int = 0, hashs: String? = nil, start: Int = 0, size: Int = 10000, dialog_id: String? = nil, message_id: String? = nil) -> GKRequestRetFiles {
        
        var result: GKRequestRetFiles!
        for _ in 0..<kTryCount {
            var param = ["token":access_token]
            param["mount_id"] = "\(mountID)"
            param["fullpath"] = fullpath
            param["start"] = "\(start)"
            param["size"] = "\(size)"
            param["dir"] = "\(dir)"
            if hashs != nil {
                param["hashs"] = hashs!
            }
            if dialog_id != nil {
                param["dialog_id"] = dialog_id!
            }
            if message_id != nil {
                param["message_id"] = message_id!
            }
            param["sign"] = sign(param)
            
            result = self.GET(url: generateurl(GKAPI.FILE_LIST), headers: nil, param: param, reqType: GKRequestRetFiles.self) as! GKRequestRetFiles
            if result.statuscode == 200 {
                break
            } else if result.errcode == kTokenExpiredCode || result.errcode == kTokenInvalidCode {
                if bStop { break }
                let _ = self.refreshToken()
            }
        }
        
        if bStop {
            result.errcode = GKOperationExitCode
        }
        
        return result
        
    }
    
    
    public func fetchFileList(reget:Bool = false,mountID: Int, fullpath: String, dir: Int = 0, hashs: String? = nil, start: Int = 0, size: Int = 10000, dialog_id: String? = nil, message_id: String? = nil, completion: ((GKRequestRetFiles)->Void)?) -> GKRequestID {
        
        var param = ["token":access_token]
        param["mount_id"] = "\(mountID)"
        param["fullpath"] = fullpath
        param["start"] = "\(start)"
        param["size"] = "\(size)"
        param["dir"] = "\(dir)"
        if hashs != nil {
            param["hashs"] = hashs!
        }
        if dialog_id != nil {
            param["dialog_id"] = dialog_id!
        }
        if message_id != nil {
            param["message_id"] = message_id!
        }
        param["sign"] = sign(param)
        
        let taskID = self.GET(url: generateurl(GKAPI.FILE_LIST), headers: nil, param: param, completion: { (ret: GKRequestBaseRet) in
            let temp = ret as! GKRequestRetFiles
            if (ret.statuscode == kTokenExpiredCode || ret.statuscode == kTokenInvalidCode) && !self.bStop{
                let _ = self.refreshToken()
                let _ = self.fetchFileList(reget: true, mountID: mountID, fullpath: fullpath, dir: dir, hashs: hashs, start: start, size: size, dialog_id: dialog_id, message_id: message_id, completion: completion)
            } else {
                completion?(temp)
            }
        }, reqType: GKRequestRetFiles.self)
        return taskID
        
    }
    
    
    public func fetchFavFiles(reget:Bool = false,type: Int, completion: ((GKRequestRetFiles)->Void)?) -> GKRequestID {
        
        var param = ["token":access_token]
        param["favorite_type"] = "\(type)"
        param["sign"] = sign(param)
        
        let taskID = self.GET(url: generateurl(GKAPI.FAVORITE_FILES), headers: nil, param: param, completion: { (ret: GKRequestBaseRet) in
            let temp = ret as! GKRequestRetFiles
            if (ret.statuscode == kTokenExpiredCode || ret.statuscode == kTokenInvalidCode) && !self.bStop{
                let _ = self.refreshToken()
                let _ = self.fetchFavFiles(reget: true, type: type, completion: completion)
            } else {
                completion?(temp)
            }
        }, reqType: GKRequestRetFiles.self)
        return taskID
    }
    
    
    
    public func searchFile(reget:Bool = false,mount_id: Int, fullpath: String?, keyword: String, scope: String?, ext: String?, create_member_id: Int?, last_member_id: Int?, start: Int?, size: Int?, order: String?, completion: ((GKRequestRetFiles)->Void)?) -> GKRequestID {
        
        var param = ["token":access_token]
        param["mount_id"] = "\(mount_id)"
        if fullpath != nil {
            param["fullpath"] = fullpath!
        }
        param["keyword"] = keyword
        if scope != nil {
            param["scope"] = scope!
        }
        if ext != nil {
            param["ext"] = ext!
        }
        if create_member_id != nil {
            param["create_member_id"] = "\(create_member_id!)"
        }
        if last_member_id != nil {
            param["last_member_id"] = "\(last_member_id!)"
        }
        if start != nil {
            param["start"] = "\(start!)"
        }
        if size != nil {
            param["size"] = "\(size!)"
        }
        if order != nil {
            param["order"] = order!
        }
        param["sign"] = sign(param)
        let taskID = self.GET(url: generateurl(GKAPI.FILE_SEARCH), headers: nil, param: param, completion: { (ret: GKRequestBaseRet) in
            let temp = ret as! GKRequestRetFiles
            if (ret.statuscode == kTokenExpiredCode || ret.statuscode == kTokenInvalidCode) && !self.bStop{
                let _ = self.refreshToken()
                let _ = self.searchFile(reget: true, mount_id: mount_id, fullpath: fullpath, keyword: keyword, scope: scope, ext: ext, create_member_id: create_member_id, last_member_id: last_member_id, start: start, size: size, order: order, completion: completion)
            } else {
                completion?(temp)
            }
        }, reqType: GKRequestRetFiles.self)
        return taskID
    }
    
    
    public func getFileDownloadUrl(mountID: Int, filehash: String, fullpath:String? = nil, uuidhash:String? = nil, net: String? = nil, open: Int? = 0, stat: Int? = 0) -> GKRequestRetDownloadURL {
        
        var result: GKRequestRetDownloadURL!
        for _ in 0..<kTryCount {
            var param = ["token":access_token]
            param["mount_id"] = "\(mountID)"
            param["filehash"] = filehash
            if fullpath != nil {
                param["fullpath"] = fullpath!
            }
            if uuidhash != nil {
                param["hash"] = uuidhash!
            }
            if net != nil {
                param["net"] = net!
            }
            if open != nil {
                param["open"] = "\(open!)"
            }
            
            if stat != nil {
                param["stat"] = "\(stat!)"
            }

            param["sign"] = sign(param)
            
            result = self.POST(url: generateurl(GKAPI.GET_DOWNLOAD_URL), headers: nil, param: param, reqType: GKRequestRetDownloadURL.self) as! GKRequestRetDownloadURL
            if result.statuscode == 200 {
                break
            } else if result.errcode == kTokenExpiredCode || result.errcode == kTokenInvalidCode {
                if bStop { break }
                let _ = self.refreshToken()
            }
        }
        
        if bStop {
            result.errcode = GKOperationExitCode
        }
        
        return result
        
    }
    
    
    public func getServerSite(type: String, storage_point:String? = nil) -> GKRequestRetGetServerSite {
        
        var result: GKRequestRetGetServerSite!
        for _ in 0..<kTryCount {
            var param = ["token":access_token]
            param["type"] = type
            if storage_point != nil {
                param["storage_point"] = storage_point!
            }
            param["sign"] = sign(param)
            
            result = self.POST(url: generateurl(GKAPI.GET_SERVER_SITE), headers: nil, param: param, reqType: GKRequestRetGetServerSite.self) as! GKRequestRetGetServerSite
            if result.statuscode == 200 {
                break
            } else if result.errcode == kTokenExpiredCode || result.errcode == kTokenInvalidCode {
                if bStop { break }
                let _ = self.refreshToken()
            }
        }
        
        if bStop {
            result.errcode = GKOperationExitCode
        }
        
        return result
        
    }
    
    
    public func copyFiles(sourceMountID: Int, sourcePathList:[String],targetMountID:Int,targetPath:String) -> GKRequestBaseRet{
        
        var result: GKRequestBaseRet!
        for _ in 0..<kTryCount {
            var param = ["token":access_token]
            param["mount_id"] = "\(sourceMountID)"
            param["fullpaths"] = sourcePathList.joined(separator: "|")
            param["target_mount_id"] = "\(targetMountID)"
            param["target_fullpath"] = targetPath
            param["sign"] = sign(param)
            
            result = self.POST(url: generateurl(GKAPI.FILE_COPY), headers: nil, param: param, reqType: GKRequestBaseRet.self)
            if result.statuscode == 200 {
                break
            } else if result.errcode == kTokenExpiredCode || result.errcode == kTokenInvalidCode {
                if bStop { break }
                let _ = self.refreshToken()
            }
        }
        
        if bStop {
            result.errcode = GKOperationExitCode
        }
        
        return result
        
    }
    
    public func moveFiles(sourceMountID: Int, sourcePathList:[String],targetMountID:Int,targetPath:String) -> GKRequestBaseRet{
        
        var result: GKRequestBaseRet!
        for _ in 0..<kTryCount {
            var param = ["token":access_token]
            param["mount_id"] = "\(sourceMountID)"
            param["fullpaths"] = sourcePathList.joined(separator: "|")
            param["target_mount_id"] = "\(targetMountID)"
            param["target_fullpath"] = targetPath
            param["sign"] = sign(param)
            
            result = self.POST(url: generateurl(GKAPI.FILE_MOVE), headers: nil, param: param, reqType: GKRequestBaseRet.self)
            if result.statuscode == 200 {
                break
            } else if result.errcode == kTokenExpiredCode || result.errcode == kTokenInvalidCode {
                if bStop { break }
                let _ = self.refreshToken()
            }
        }
        
        if bStop {
            result.errcode = GKOperationExitCode
        }
        
        return result
        
    }
    
    public func renameFile(mountID: Int, fullpath:String,newName:String) -> GKRequestBaseRet{
        
        var result: GKRequestBaseRet!
        for _ in 0..<kTryCount {
            var param = ["token":access_token]
            param["mount_id"] = "\(mountID)"
            param["fullpath"] = fullpath
            param["newname"] = newName
            param["sign"] = sign(param)
            
            result = self.POST(url: generateurl(GKAPI.FILE_RENAME), headers: nil, param: param, reqType: GKRequestBaseRet.self)
            if result.statuscode == 200 {
                break
            } else if result.errcode == kTokenExpiredCode || result.errcode == kTokenInvalidCode {
                if bStop { break }
                let _ = self.refreshToken()
            }
        }
        
        if bStop {
            result.errcode = GKOperationExitCode
        }
        
        return result
        
    }
    
    
    
    /// 删除文件
    ///
    /// - Parameters:
    ///   - mount_id: 库id
    ///   - pathList: 文件路径数组
    /// - Returns: 是否成功
    public func deleteFiles(mount_id: Int, pathList:[String]) -> GKRequestBaseRet{
        
        var result: GKRequestBaseRet!
        for _ in 0..<kTryCount {
            var param = ["token":access_token]
            param["mount_id"] = "\(mount_id)"
            param["fullpaths"] = pathList.joined(separator: "|")
            param["sign"] = sign(param)
            
            result = self.POST(url: generateurl(GKAPI.FILE_DELETE), headers: nil, param: param, reqType: GKRequestBaseRet.self)
            if result.statuscode == 200 {
                break
            } else if result.errcode == kTokenExpiredCode || result.errcode == kTokenInvalidCode {
                if bStop { break }
                let _ = self.refreshToken()
            }
        }
        
        if bStop {
            result.errcode = GKOperationExitCode
        }
        
        return result
        
    }
    
    
    /// 锁定/解锁文件
    ///
    /// - Parameters:
    ///   - mount_id: 库id
    ///   - fullpath: 文件路径
    ///   - lock: 是否锁定
    /// - Returns: 成功200
    public func lockFile(mount_id: Int, fullpath:String, lock: Bool) -> GKRequestBaseRet{
        
        var result: GKRequestBaseRet!
        for _ in 0..<kTryCount {
            var param = ["token":access_token]
            param["mount_id"] = "\(mount_id)"
            param["fullpath"] = fullpath
            param["lock"] = (lock ? "lock" : "unlock")
            param["sign"] = sign(param)
            
            result = self.POST(url: generateurl(GKAPI.FILE_LOCK), headers: nil, param: param, reqType: GKRequestBaseRet.self)
            if result.statuscode == 200 {
                break
            } else if result.errcode == kTokenExpiredCode || result.errcode == kTokenInvalidCode {
                if bStop { break }
                let _ = self.refreshToken()
            }
        }
        
        if bStop {
            result.errcode = GKOperationExitCode
        }
        
        return result
        
    }
    
    //MARK: Upload
    public func createFolder(mountid:Int,webpath:String,create_dateline: Int64?,last_dateline:Int64?) -> GKRequestRetCreateFile {
        var result: GKRequestRetCreateFile!
        for _ in 0..<kTryCount {
            var param = ["token":access_token]
            param["mount_id"] = "\(mountid)"
            param["fullpath"] = webpath
            if create_dateline != nil {
                param["create_dateline"] = "\(create_dateline!)"
            }
            if last_dateline != nil {
                param["last_dateline"] = "\(last_dateline!)"
            }
            param["sign"] = sign(param)
            
            result = self.POST(url: generateurl(GKAPI.CREATE_FOLDER), headers: nil, param: param, reqType: GKRequestRetCreateFile.self) as! GKRequestRetCreateFile
            if result.statuscode == 200 {
                break
            } else if result.errcode == kTokenExpiredCode || result.errcode == kTokenInvalidCode {
                if bStop { break }
                let _ = self.refreshToken()
            }
        }
        return result
    }
    
    public func createFile(mountid:Int,webpath:String,filehash:String,filesize:Int64,overwrite: Bool, create_dateline: Int64? = nil,last_dateline:Int64? = nil,dateline:Int64? = nil, dialog_id:String? = nil,ent_id:Int? = nil,filefield:String? = nil, data: Data? = nil) -> GKRequestRetCreateFile {
        var result: GKRequestRetCreateFile!
        for _ in 0..<kTryCount {
            var param = ["token":access_token]
            param["mount_id"] = "\(mountid)"
            param["fullpath"] = webpath
            if create_dateline != nil {
                param["create_dateline"] = "\(create_dateline!)"
            }
            if last_dateline != nil {
                param["last_dateline"] = "\(last_dateline!)"
            }
            if dateline != nil {
                param["dateline"] = "\(dateline!)"
            }
            
            if dialog_id != nil {
                param["dialog_id"] = dialog_id!
            }
            if ent_id != nil {
                param["ent_id"] = "\(ent_id!)"
            }
            param["sign"] = sign(param)
            //param["overwrite"] = (overwrite ? "1" : "0")
            param["filehash"] = filehash
            param["filesize"] = "\(filesize)"
            
            result = self.POST(url: generateurl(GKAPI.CREATE_FILE), headers: nil, param: param, reqType: GKRequestRetCreateFile.self) as! GKRequestRetCreateFile
            if result.statuscode == 200 {
                break
            } else if result.errcode == kTokenExpiredCode || result.errcode == kTokenInvalidCode {
                if bStop { break }
                let _ = self.refreshToken()
            }
        }
        return result
    }
    
    private let HEADER_X_GK_UPLOAD_FILENAME =  "x-gk-upload-filename"
    private let HEADER_X_GK_UPLOAD_PATHHASH =	"x-gk-upload-pathhash"
    private let HEADER_X_GK_UPLOAD_FILEHASH =	"x-gk-upload-filehash"
    private let HEADER_X_GK_UPLOAD_FILESIZE =	"x-gk-upload-filesize"
    private let HEADER_X_GK_UPLOAD_MOUNTID  =   "x-gk-upload-mountid"
    private let HEADER_X_GK_TOKEN			=	"x-gk-token"
    
    public func uploadFileInit(host:String,mountid:Int,filename:String,uuidhash:String,filehash:String,filesize:Int64) -> GKRequestBaseRet {
        var result: GKRequestBaseRet!
        
        for _ in 0..<kTryCount {
            var header = [HEADER_X_GK_TOKEN:access_token]
            header[HEADER_X_GK_UPLOAD_MOUNTID] = "\(mountid)"
            header[HEADER_X_GK_UPLOAD_FILENAME] = filename
            header[HEADER_X_GK_UPLOAD_PATHHASH] = uuidhash
            header[HEADER_X_GK_UPLOAD_FILEHASH] = filehash
            header[HEADER_X_GK_UPLOAD_FILESIZE] = "\(filesize)"
            
            let url = "\(host)/upload_init"
            
            result = self.POST(url: url, headers: header, param: nil, reqType: GKRequestBaseRet.self) 
            if result.statuscode == 200 {
                break
            } else if result.errcode == kTokenExpiredCode || result.errcode == kTokenInvalidCode {
                if bStop { break }
                let _ = self.refreshToken()
            }
        }
        return result
    }
    
    private let HEADER_X_GK_UPLOAD_SESSION = "x-gk-upload-session"
    private let HEADER_X_GK_UPLOAD_RANGE = "x-gk-upload-range"
    private let HEADER_CONTENT_LENGTH = "Content-Length"
    private let HEADER_X_GK_UPLOAD_PART_CRC = "x-gk-upload-crc"
    
    public func uploadFilePart(host:String,session:String,start:Int64,end:Int64,data:Data,crc:String) -> GKRequestBaseRet {
        var result: GKRequestBaseRet!
        
        for _ in 0..<1 {
            
            var header = [HEADER_X_GK_UPLOAD_SESSION:session]
            header[HEADER_X_GK_UPLOAD_RANGE] = "\(start)-\(end)"
            header[HEADER_CONTENT_LENGTH] = "\(data.count)"
            header[HEADER_X_GK_UPLOAD_PART_CRC] = crc
            
            let url = "\(host)/upload_part"
            
            result = self.PUT(url: url, headers: header, param: nil, data: data, reqType: GKRequestBaseRet.self)
            if result.statuscode == 200 {
                break
            } else if result.errcode == kTokenExpiredCode || result.errcode == kTokenInvalidCode {
                if bStop { break }
                let _ = self.refreshToken()
            }
        }
        return result
    }
    
    public func uploadFileFinish(host:String,session:String,filesize:Int64) -> GKRequestBaseRet {
        var result: GKRequestBaseRet!
        
        for _ in 0..<kTryCount {
            
            var header = [HEADER_X_GK_UPLOAD_SESSION:session]
            header[HEADER_X_GK_UPLOAD_FILESIZE] = "\(filesize)"
            
            let url = "\(host)/upload_finish"
            
            result = self.POST(url: url, headers: header, param: nil, reqType: GKRequestBaseRet.self)
            if result.statuscode == 200 {
                break
            } else if result.errcode == kTokenExpiredCode || result.errcode == kTokenInvalidCode {
                if bStop { break }
                let _ = self.refreshToken()
            }
        }
        return result
    }
    
}
