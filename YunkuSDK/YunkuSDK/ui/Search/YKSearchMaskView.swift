//
//  YKSearchMaskView.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/9.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit

class YKSearchMaskViewFile: UIView,UITableViewDataSource,UITableViewDelegate {
    
    var activityIndicator: UIActivityIndicatorView!
    var infoLabel: UILabel!
    var tableView: UITableView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.setupViews()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setupViews() {
        self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        self.activityIndicator.sizeToFit()
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.isHidden = true
        self.addSubview(activityIndicator)
        self.activityIndicator.frame = CGRect(x: 10, y: 150, width: activityIndicator.frame.size.width, height: activityIndicator.frame.size.height)
        
        let label = UILabel(frame: CGRect.zero)
        label.textColor = YKColor.SubTitle
        label.text = YKLocalizedString("正在搜索...")
        label.textAlignment = .left
        label.font = YKFont.make(14)
        label.sizeToFit()
        self.addSubview(label)
        self.infoLabel = label
        label.isHidden = true
        label.frame = CGRect(x: 100, y: 200, width: 100, height: 40)
        
        let t = UITableView(frame: self.bounds, style: .plain)
        t.delegate = self
        t.dataSource = self
        t.rowHeight = 54
        t.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        t.separatorStyle = .none
        t.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        
        self.addSubview(t)
        self.tableView = t
        
        //t.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        let row = indexPath.row
        var title = ""
        switch row {
        case 0:
            title = YKLocalizedString("范围")
        case 1:
            title = YKLocalizedString("内容")
        case 2:
            title = YKLocalizedString("文件类型")
        case 3:
            title = YKLocalizedString("创建者")
        case 4:
            title = YKLocalizedString("最后修改者")
        default:
            break
        }
        
        cell?.textLabel?.text = title
        
        cell?.accessoryType = .disclosureIndicator
        
        return cell!
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
}
