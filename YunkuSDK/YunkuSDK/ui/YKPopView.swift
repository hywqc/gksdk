//
//  YKPopView.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/18.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit

final class YKPopView : UIView {
    
    struct YKPopViewItem {
        var title = ""
        var image = ""
        var id = 0
    }
    
    var items = [YKPopViewItem]()
    
    init(items: [YKPopViewItem]) {
        self.items = items
        super.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
