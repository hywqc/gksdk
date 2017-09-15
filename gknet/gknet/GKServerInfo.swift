//
//  GKServerInfo.swift
//  gknet
//
//  Created by wqc on 2017/9/14.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation

public class GKServerInfo {
    
    public var https = true
    public var webHost = ""
    public var apiHost = ""
    public var webPort: String?
    public var webHttpsPort: String?
    public var apiPort: String?
    public var apiHttpsPort: String?
    
    public var clientID = ""
    public var clientSecret = ""
    
    public init() {
        
    }
    
    public func fullApiURL(path: String) -> String {
        var uniform = false
        if apiHost.isEmpty || webHost == apiHost {
            uniform = true
            if apiHost.isEmpty {
                apiHost = webHost
            }
        }
        
        let proto = (https ? "https://" : "http://")
        var url = proto + self.apiHost
        url = url.gkRemoveLastSlash
        if https {
            if let httpsport = self.apiHttpsPort {
                if !httpsport.isEmpty && httpsport != "443" {
                    url = url + ":\(httpsport)"
                }
            }
        } else {
            if let httpport = self.apiPort {
                if !httpport.isEmpty && httpport != "80" {
                    url = url + ":\(httpport)"
                }
            }
        }
        
        if uniform {
            url = url + "/m-api"
        }
        
        if path.hasPrefix("/") {
            return url + path
        } else {
            return url + "/\(path)"
        }
    }
    
    public func fullWebURL(path: String) -> String {
        
        let proto = (https ? "https://" : "http://")
        var url = proto + self.webHost
        url = url.gkRemoveLastSlash
        if https {
            if let httpsport = self.webHttpsPort {
                if !httpsport.isEmpty && httpsport != "443" {
                    url = url + ":\(httpsport)"
                }
            }
        } else {
            if let httpport = self.webPort {
                if !httpport.isEmpty && httpport != "80" {
                    url = url + ":\(httpport)"
                }
            }
        }
        
        if path.hasPrefix("/") {
            return url + path
        } else {
            return url + "/\(path)"
        }
    }
    
}
