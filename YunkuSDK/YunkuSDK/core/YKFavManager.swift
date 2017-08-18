//
//  YKFavManager.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/14.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gknet
import gkutility


final class YKFavManager {
    
    static let shareInstance = YKFavManager()
    private init() {
        
    }
    
    func getFiles(type:Int,completion: (([GKFileDataItem],String?)->Void)?) -> GKRequestID {
        
        return 0
    }
}
