//
//  gkdic.swift
//  gkutility
//
//  Created by wqc on 2017/7/28.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation


public extension Dictionary where Key == String, Value == String {
    
    func gkSign(key: String, urlencode: Bool = true) -> String {
        return gkutility.getSignFromDic(self, key: key, urlencode: urlencode)
    }
    
    var gkStr: String {
        if let s = gkutility.obj2str(obj: self) {
            return s
        }
        return ""
    }
    
    func gkQuery(encode: Bool = true) -> String {
        let querys = self.map { (item: (key: String, value: String)) -> String in
            return item.key + "=" + (encode ? item.value.gkUrlEncode : item.value)
        }
        return querys.joined(separator: "&")
    }
}

public extension Array {
    mutating func gkRemove(at indexes: [Int]) {
        for i in indexes.sorted(by: >) {
            self.remove(at: i)
        }
    }
}


#if GKObjcCompatibility
    public extension NSDictionary {
        func gkSign(key: NSString) -> NSString {
            let dic:[String:String] = self as! [String:String]
            return dic.gkSign(key: key as String) as NSString
        }
        
        func gkQuery(encode: Bool = true) -> NSString {
            let dic:[String:String] = self as! [String:String]
            return dic.gkQuery() as NSString
        }
        
        var gkStr: NSString? {
            let dic:[AnyHashable:Any] = self as! [AnyHashable:Any]
            return gkutility.obj2str(obj: dic) as NSString?
        }
    }
#else

#endif
