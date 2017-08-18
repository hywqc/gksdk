//
//  YKSettingDB.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/14.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gknet
import gkutility

class YKSettingDB : YKBaseDB {
    
    override func createTable() {
        
        
        self.dbQueue.inDatabase { (db: FMDatabase) in
            
            let sql = "CREATE TABLE IF NOT EXISTS USERS(userid int,account varchar[200],accesstoken char[100],refreshtoken char[100],dateline bigint,status smallint,userinfo varchar[4000],PRIMARY KEY (userid));";
            
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func checkLastLogin() -> Int {
        
        var ret = 0
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "select * from USERS where status=1 and refreshtoken<>'' ;"
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    let userid = rs.int(forColumn: "userid")
                    let account = rs.string(forColumn: "account")
                    let token = rs.string(forColumn: "accesstoken")
                    let userinfo = rs.string(forColumn: "userinfo")
                    if account == nil || token == nil || userinfo == nil {
                        break
                    }
                    ret = Int(userid)
                    break
                }
                rs.close()
            }
        }
        return ret
    }
    
    func addAccount(token: String, refreshtoken: String,_ account: GKRequestAccountInfo, active: Bool = true) {
        
        let rinfo = account.rawJson.gkReplaceToSQL
        let now: Int64 = Int64(Date().timeIntervalSince1970)
        self.dbQueue.inDatabase { (db:FMDatabase) in
            var sql = "select userid from USERS where userid=\(account.member_id) ;"
            var bhave = false
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    bhave = true
                    break
                }
                rs.close()
            }
            
            if bhave {
                sql = "update USERS set account='\(account.member_email)', accesstoken='\(token)', refreshtoken='\(refreshtoken)', status=\(active ? 1 : 0), userinfo='\(rinfo)', dateline=\(now) where userid=\(account.member_id) "
            } else {
                sql = "insert into USERS(userid,account,accesstoken,refreshtoken,dateline,status,userinfo) values(\(account.member_id),'\(account.member_email)','\(token)','\(refreshtoken)',\(now),\(active ? 1 : 0),'\(rinfo)') ;"
            }
            
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func getTokenInfo(_ userID: Int) -> (accesstoken:String,refreshtoken:String) {
        var ret = ("","")
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "select * from USERS where userid=\(userID) ;"
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    if let token = rs.string(forColumn: "accesstoken") {
                        ret.0 = token
                    }
                    if let token = rs.string(forColumn: "refreshtoken") {
                        ret.1 = token
                    }
                    break
                }
                rs.close()
            }
        }
        return ret
    }
    
    func getAccount(_ userID: Int) -> GKRequestAccountInfo? {
        
        var accountInfo: GKRequestAccountInfo?
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "select * from USERS where userid=\(userID) ;"
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    if let info = rs.string(forColumn: "userinfo") {
                        if let dic = info.gkDic {
                            let r = GKRequestAccountInfo()
                            r.statuscode = 200
                            r.parseFromDic(dic: dic)
                            accountInfo = r
                        }
                    }
                    break
                }
                rs.close()
            }
        }
        return accountInfo
    }
    
    func getall() -> [GKRequestAccountInfo] {
        var result = [GKRequestAccountInfo]()
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "select * from USERS where userid>0 and accesstoken<>'' and refreshtoken<>''  order by dateline desc ;"
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                while rs.next() {
                    if let info = rs.string(forColumn: "userinfo") {
                        if let dic = info.gkDic {
                            let r = GKRequestAccountInfo()
                            r.statuscode = 200
                            r.parseFromDic(dic: dic)
                            result.append(r)
                        }
                    }
                }
                rs.close()
            }
        }
        return result
    }
    
    func updateAccountInfo(_ account: GKRequestAccountInfo) {
        let rinfo = account.rawJson.gkReplaceToSQL
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "update USERS set userinfo='\(rinfo)' where userid=\(account.member_id) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func updateDateline(_ userid: Int) {
        let now: Int64 = Int64(Date().timeIntervalSince1970)
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "update USERS set dateline=\(now) where userid=\(userid) ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    func updateTokenInfo(_ accessToken: String, _ refreshToken:String) {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            let sql = "update USERS set accesstoken='\(accessToken)',refreshtoken='\(refreshToken)' where status=1 ;"
            try? db.executeUpdate(sql, values: nil)
        }
    }
    
    
    func logout() {
        self.dbQueue.inDatabase { (db:FMDatabase) in
            try? db.executeUpdate("update USERS set status=0 ;", values: nil)
        }
    }
}
