//
//  gkstring.swift
//  gkutility
//
//  Created by wqc on 2017/7/27.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation


public extension String {
    
    var gkUrlEncode: String {
        let charactersGeneralDelimitersToEncode = ":#[]@/?"
        let charactersSubDelimitersToEncode = "!$&'()*+,;="
        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: charactersGeneralDelimitersToEncode.appending(charactersSubDelimitersToEncode))
        
        
        if let s = self.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) {
            return s
        }
        return self
    }
    
    var gkParentPath: String {
        if let r = self.range(of: "/", options: .backwards, range: nil, locale: nil) {
            let s = String(self.characters.prefix(upTo: r.lowerBound))
            return s
        }
        return ""
    }
    
    var gkFileName: String {
        if let r = self.range(of: "/", options: .backwards, range: nil, locale: nil) {
            let pos = self.characters.index(after: r.lowerBound)
            let s = String(self.characters.suffix(from: pos))
            return s
        }
        
        return self
    }
    
    var gkTrimSlash: String {
        let set = CharacterSet(charactersIn: "/")
        return self.trimmingCharacters(in: set)
    }
    
    var gkTrimSpace: String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    var gkAddLastSlash: String {
        if self.isEmpty {
            return self
        }
        let c = self.characters.last
        if c! == "/" {
            return self
        }
        return self.appending("/")
    }
    
    var gkRemoveLastSlash: String {
        
        if self.isEmpty {
            return self
        }
        let c = self.characters.last
        if c! != "/" {
            return self
        }
        return self.substring(to:  self.characters.index(before: self.characters.endIndex))
    }
    
    var gkReplaceToSQL: String {
        return self.replacingOccurrences(of: "'", with: "''")
    }
    
    
    var gkMD5: String {
        
        let s = gkobjassist.md5(self)
        return s
    }
    
    var gkSha1: String {
        return gkobjassist.sha1(self)
    }
    
    func gkSign(key: String, urlencode: Bool = true) -> String {
        
        let s = gkobjassist.generateSign(self, key: key)
        return (urlencode ? s.gkUrlEncode : s)
    }
    
    var gkDic: [AnyHashable:Any]? {
        return gkutility.json2dic(obj:self)
    }
    
    var gkArr: [Any]? {
        return gkutility.json2arr(obj:self)
    }
    
    var gkBase64: String {
        if let d = gkutility.str2data(str: self) {
            return d.base64EncodedString()
        }
        return ""
    }
    
    func gkSize(maxWidth:CGFloat,font:UIFont) -> CGSize {
        let s = self as NSString
        
        return s.boundingRect(with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin,.usesFontLeading], attributes: [NSFontAttributeName:font], context: nil).size
    }
    
}


#if GKObjcCompatibility
    public extension NSString {
        
        public func gkUrlEncode() -> NSString {
            let s: String = String(self)
            return s.gkUrlEncode as NSString
        }
        
        public func gkParentPath() -> NSString {
            let s: String = String(self)
            return s.gkParentPath as NSString
        }
        
        public func gkFileName() -> NSString {
            let s: String = String(self)
            return s.gkFileName as NSString
        }
        
        public func gkTrimSlash() -> NSString {
            let s: String = String(self)
            return s.gkTrimSlash as NSString
        }
        
        public func gkTrimSpace() -> NSString {
            let s: String = String(self)
            return s.gkTrimSpace as NSString
        }
        
        public func gkAddLastSlash() -> NSString {
            let s: String = String(self)
            return s.gkAddLastSlash as NSString
        }
        
        public func gkRemoveLastSlash() -> NSString {
            let s: String = String(self)
            return s.gkRemoveLastSlash as NSString
        }
        
        public func gkReplaceToSQL() -> NSString {
            let s: String = String(self)
            return s.gkReplaceToSQL as NSString
        }
        
        public func gkMD5() -> NSString {
            let s: String = String(self)
            return s.gkMD5 as NSString
        }
        
        public func gkSha1() -> NSString {
            let s: String = String(self)
            return s.gkSha1 as NSString
        }
        
        public func gkBase64() -> NSString {
            let s: String = String(self)
            return s.gkBase64 as NSString
        }
        
        public func gkDic() -> NSDictionary? {
            let s: String = String(self)
            return s.gkDic as NSDictionary?
        }
        
        public func gkArr() -> NSArray? {
            let s: String = String(self)
            return s.gkArr as NSArray?
        }
        
        func gkSign(key: String, urlencode: Bool = true) -> NSString {
            
            let s: String = String(self)
            return s.gkSign(key:key,urlencode: urlencode) as NSString
        }
        
        func gkSize(maxWidth:CGFloat,font:UIFont) -> CGSize {
            return self.boundingRect(with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin,.usesFontLeading], attributes: [NSFontAttributeName:font], context: nil).size
        }
        
    }

#else
    
    

#endif
