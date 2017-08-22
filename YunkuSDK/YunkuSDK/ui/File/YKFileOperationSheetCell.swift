//
//  YKFileOperationSheetCell.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/21.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit

class YKFileOperationSheetCell: UITableViewCell {
    
    private let btnWidth: CGFloat = 80
    private let btnHeight: CGFloat = 44
    
    var btn1,btn2,btn3,btn4: UIButton!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createbtn(_ title: String, _ image: String) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.titleLabel?.font = YKFont.make(14)
        btn.contentHorizontalAlignment = .center
        btn.setImage(YKImage(image), for: .normal)
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5)
        btn.frame = CGRect(x: 0, y: 0, width: btnWidth, height: btnHeight)
        self.contentView.addSubview(btn)
        return btn;
    }
    
    func setup() {
        self.contentView.backgroundColor = YKColor.Blue
        
        btn1 = createbtn(YKLocalizedString("分享"), "iconOperationShare")
        btn1.addTarget(self, action: #selector(onShareBtn), for: .touchUpInside)
        btn2 = createbtn(YKLocalizedString("删除"), "iconOperationDelete")
        btn2.addTarget(self, action: #selector(onDeleteBtn), for: .touchUpInside)
        btn3 = createbtn(YKLocalizedString("属性"), "iconOperationProperty")
        btn3.addTarget(self, action: #selector(onPropertyBtn), for: .touchUpInside)
        btn4 = createbtn(YKLocalizedString("更多"), "iconOperationMore")
        btn4.addTarget(self, action: #selector(onMoreBtn), for: .touchUpInside)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let sz = self.contentView.frame.size
        
        let interval = (sz.width - 4*btn1.frame.size.width)/5
        
        var rect = CGRect(x: interval, y: (sz.height-btnHeight)/2, width: btnWidth, height: btnHeight)
        btn1.frame = rect
        rect.origin.x += (btnWidth + interval)
        btn2.frame = rect
        rect.origin.x += (btnWidth + interval)
        btn3.frame = rect
        rect.origin.x += (btnWidth + interval)
        btn4.frame = rect
    }
    
    func onShareBtn() {
        
    }
    
    func onDeleteBtn() {
        
    }
    
    func onPropertyBtn() {
        
    }
    
    func onMoreBtn() {
        
    }
}
