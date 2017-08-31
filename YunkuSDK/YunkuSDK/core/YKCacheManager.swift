//
//  YKCacheManager.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/29.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gkutility

class YKCacheManager {
    
    enum CacheType {
        case Original
        case Convert
    }
    
    struct CacheNode {
        var type: CacheType
        var path: String
    }
    
    var root: String {
        return gkutility.cachePath().gkAddLastSlash
    }
    var nodes: [CacheNode] = []
    
    var queue = DispatchQueue(label: "com.gokuai.cache.queue")
    
    static let shareManager = YKCacheManager()
    
    private init() {
        var p = self.root + "original/"
        let _ = gkutility.createDir(path: p)
        self.nodes.append(CacheNode(type: .Original, path: p))
        p = self.root + "convert/"
        let _ = gkutility.createDir(path: p)
        self.nodes.append(CacheNode(type: .Convert, path: p))
    }
    
    func addToCache(_ path: String, key: String, type: CacheType, replace: Bool = true) {
        self.queue.async {
            if path.isEmpty || key.isEmpty { return }
            if !gkutility.fileExist(path: path) { return }
            var dir = ""
            for item in self.nodes {
                if item.type == type {
                    dir = item.path
                    break
                }
            }
            if dir.isEmpty { return }
            let dest = dir + key
            if replace {
                gkutility.deleteFile(path: dest)
            }
            do {
                try FileManager.default.copyItem(atPath: path, toPath: dest)
            } catch  {
                
            }
        }
    }
    
    func deleteCache(key: String, type: CacheType?) {
        self.queue.async {
            if key.isEmpty { return }
            if type != nil {
                var dir = ""
                for item in self.nodes {
                    if item.type == type! {
                        dir = item.path
                        break
                    }
                }
                if dir.isEmpty {
                    return
                }
                let dest = dir + key
                gkutility.deleteFile(path: dest)
            } else {
                for item in self.nodes {
                    if item.path.isEmpty { continue }
                    let p = item.path + key
                    gkutility.deleteFile(path: p)
                }
            }
        }
    }
    
    func deleteAll() {
        self.queue.async {
            gkutility.deleteFile(path: self.root)
        }
    }
    
    func checkCache(key: String, type: CacheType?) -> String? {
        if key.isEmpty { return nil }
        if type != nil {
            var path = ""
            var dir = ""
            for item in self.nodes {
                if item.type == type! {
                    dir = item.path
                    break
                }
            }
            if dir.isEmpty {
                return nil
            }
            path = dir + key
            if gkutility.fileExist(path: path) {
                return path
            }
        } else {
            for item in self.nodes {
                if item.path.isEmpty { continue }
                let p = item.path + key
                if gkutility.fileExist(path: p) {
                    return p
                }
            }
        }
        return nil
    }
    
    func cachePath(key: String, type: CacheType) -> String {
        var dir = ""
        for item in self.nodes {
            if item.type == type {
                dir = item.path
                break
            }
        }
        if dir.isEmpty { return "" }
        return dir + key
    }
    
}
