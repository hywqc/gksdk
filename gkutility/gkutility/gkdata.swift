//
//  gkdata.swift
//  gkutility
//
//  Created by wqc on 2017/7/28.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation

private let  DEFAULT_SEED: UInt32 = 0xFFFFFFFF
private let  DEFAULT_POLYNOMIAL: UInt32 = 0xEDB88320

public extension Data {
    
    var gkDic: [AnyHashable:Any]? {
        return gkutility.json2dic(obj:self)
    }
    
    var gkArr: [Any]? {
        return gkutility.json2arr(obj:self)
    }
    
    var gkStr: String? {
        return gkutility.data2str(data: self)
    }
    
    var gkcrc32: UInt32 {
        return gkobjassist.crc32(of: self, seed: DEFAULT_SEED, usingPolynomial: DEFAULT_POLYNOMIAL)
    }
}

#if GKObjcCompatibility
    public extension NSData {
        var gkDic: NSDictionary? {
            let d: Data = self as Data
            return d.gkDic as NSDictionary?
        }
        
        var gkArr: NSArray? {
            let d: Data = self as Data
            return d.gkArr as NSArray?
        }
        
        var gkStr: NSString? {
            let d: Data = self as Data
            return d.gkStr as NSString?
        }
        
        var gkcrc32: UInt32 {
            let d: Data = self as Data
            return d.gkcrc32
        }
    }
#else

#endif
