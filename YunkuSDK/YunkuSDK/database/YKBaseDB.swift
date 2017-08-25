//
//  YKBaseDB.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/4.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gkutility

class YKBaseDB : NSObject {
    
    var dbQueue: FMDatabaseQueue
    let dbPath: String
    
    init(path: String) {
        self.dbPath = path
        self.dbQueue = FMDatabaseQueue(path: path)
        super.init()
        if !self.checkIntegrity() {
            gkutility.deleteFile(path: path)
            self.dbQueue = FMDatabaseQueue(path: path)
        }
        self.createTable()
        self.updateTable()
    }
    
    func createTable() {
        
    }
    
    func updateTable() {
        
    }
    
    func checkIntegrity() -> Bool {
        var bret = false
        self.dbQueue.inDatabase { (db: FMDatabase) in
            let sql = "pragma integrity_check"
            if let rs = db.executeQuery(sql, withParameterDictionary: nil) {
                if rs.next() {
                    if let temp = rs.string(forColumnIndex: 0) {
                        if temp.lowercased() == "ok" {
                            bret = true
                        }
                    }
                    rs.close()
                }
                
            }
        }
        return bret
    }
    
    func close() {
        
    }
}
