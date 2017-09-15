//
//  YKFileLinkConfigController.swift
//  YunkuSDK
//
//  Created by wqc on 2017/9/14.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gknet

enum YKShareLinkType : Int {
    case Copy = 1
    case Email
    case SMS
    case Fellow
    case Chat
    case WeChat
    case QQ
}


class YKFileLinkConfigController: YKBaseViewController, UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate {
    
    enum AccessControlType {
        case All
        case Ent
        case Password
    }
    
    var fileItem: GKFileDataItem!
    var entID = 0
    var preferPermissions: YKPermissions?
    
    var accessControl:[(type:AccessControlType,desc:String)] = []
    var selectedAccessControl: AccessControlType = .All
    
    var datelineControl:[(key:String,time:Int64)] = []
    var selectedDatelineControl = 0
    
    var password: String? = nil
    var customDateline: Int64? = nil
    
    var expireDateline: TimeInterval = 0
    
    var allowDownload = false
    var allowUpload = false
    
    lazy var tableView: UITableView =  {
        let t = UITableView(frame: CGRect.zero, style: .plain)
        t.delegate = self
        t.dataSource = self
        t.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        t.sectionHeaderHeight = 30
        t.rowHeight = 48
        t.backgroundColor = YKColor.BKG
        return t
    }()
    
    init(file:GKFileDataItem,permission: YKPermissions?) {
        self.fileItem = file
        self.preferPermissions = permission
        super.init(nibName: nil, bundle: nil)
        
        for str in YKCustomConfig.shareConfig.linkAccessControls {
            if str == "all" {
                accessControl.append((.All,YKLocalizedString("任何获得该链接的人都可以访问")))
            } else if str == "ent" {
                var entname = ""
                if let em = YKMountCenter.shareInstance.entManagerBy(entID: self.entID) {
                    entname = em.ent.ent_name
                }
                let s = NSString(format: YKLocalizedString("只有[%@]的成员才能访问") as NSString, entname) as String
                accessControl.append((.Ent,s))
            
            } else if str == "password" {
                accessControl.append((.Password,YKLocalizedString("需要密码才能访问")))
            }
        }
        
        let now = Int64(Date().timeIntervalSince1970)
        let perday: Int64 = (60*60*24)
        self.datelineControl = [
            (YKLocalizedString("永不失效"),-1),
            (YKLocalizedString("两天"),(now + perday*2)),
            (YKLocalizedString("一个星期"),(now + perday*7)),
            (YKLocalizedString("一个月"),(now + perday*30)),
            (YKLocalizedString("自定义失效时间"),0)
        ]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.tableView)
        self.tableView.frame = self.view.bounds
        
        self.setNavTitle(self.fileItem.filename)
        
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        v.backgroundColor = self.tableView.backgroundColor
        self.tableView.tableFooterView = v
        
        var btn = UIButton(type: .custom)
        btn.frame = CGRect(x: 15, y: (100-44)/2, width: (self.view.frame.size.width-30), height: 44);
        btn.backgroundColor = YKColor.Blue
        btn.setTitle(YKLocalizedString("生成外链并分享"), for: .normal)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.titleLabel?.font = YKFont.make(14)
        btn.layer.cornerRadius = 5
        v.addSubview(btn)
        
        let rect = btn.frame
        btn = UIButton(type: .custom)
        btn.frame = CGRect(x: (rect.maxX-100), y: rect.maxY + 10, width: 100, height: 25)
        btn.titleLabel?.textAlignment = .right
        btn.setTitle(YKLocalizedString("已生成的外链"), for: .normal)
        btn.setTitleColor(YKColor.Blue, for: .normal)
        btn.titleLabel?.font = YKFont.make(13)
        v.addSubview(btn)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onTextFieldChanged(notification:)), name: NSNotification.Name.UITextFieldTextDidChange, object: nil)
    }
    
    func onTextFieldChanged(notification: Notification) {
        
        if let textField = notification.object as? UITextField {
            self.password = textField.text
        }
    }
    
    func switchChanged(sender:UISwitch) {
        if sender.tag == 100 {
            self.allowDownload = sender.isOn
        } else if sender.tag == 200{
            self.allowUpload = sender.isOn
        }
    }
    
    //Mark: UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }

    
    //MARK: UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return ((self.selectedAccessControl == .Password) ? 2 : 1)
        case 1:
            return ((self.customDateline != nil) ? 2 : 1)
        case 2:
            return (fileItem.dir ? 2 : 1)
        default:
            break
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let v = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 30))
        v.backgroundColor = YKColor.BKG
        
        let l = UILabel(frame: CGRect(x: 10, y: (v.frame.size.height-20), width: v.frame.size.width-20, height: 20))
        l.font = YKFont.make(13)
        l.textColor = YKColor.SubTitle
        l.textAlignment = .left
        v.addSubview(l)
        
        var str = ""
        switch section {
        case 0:
            str = YKLocalizedString("访问控制")
        case 1:
            str = YKLocalizedString("失效时间")
        case 2:
            str = YKLocalizedString("权限")
        default:
            break
        }
        l.text = str
        
        return v
    }
    
    func passwordCell() -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cellpsw")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cellpsw")
            
            var rect = CGRect(x: 15, y: 0, width: 80, height: self.tableView.rowHeight)
            
            let label = UILabel(frame: rect)
            label.font = YKFont.Title
            label.textColor = YKColor.Title
            label.text = YKLocalizedString("密码:")
            label.tag = 1
            label.sizeToFit()
            label.frame = CGRect(x: 15, y: 0, width: label.frame.size.width, height: self.tableView.rowHeight)
            cell?.contentView.addSubview(label)
            
            rect = label.frame
            rect.origin.x = rect.maxX+5
            rect.size = CGSize(width: self.tableView.frame.size.width-rect.origin.x-10, height: rect.size.height)
            let textField = UITextField(frame: rect)
            textField.backgroundColor = UIColor.white
            textField.textColor = YKColor.Title
            textField.font = YKFont.make(13)
            textField.delegate = self
            textField.leftViewMode = .always
            textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
            textField.returnKeyType = .done
            textField.layer.cornerRadius = 8
            textField.placeholder = YKLocalizedString("点击输入密码(数字或字母)")
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.spellCheckingType = .no
            textField.tag = 2
            cell?.contentView.addSubview(textField)
            
            cell?.accessoryType = .none
        }
        
        if let textfield = cell?.contentView.viewWithTag(2) as? UITextField {
            if self.password != nil {
                textfield.text = self.password
            }
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if 0 == indexPath.section && 1 == indexPath.row {
            return self.passwordCell()
        }
        
        var cellid = "cell"
        if 2==indexPath.section {
            cellid = "cell1"
        }
        var cell = tableView.dequeueReusableCell(withIdentifier: cellid)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellid)
            cell?.textLabel?.font = YKFont.Title
            cell?.textLabel?.textColor = YKColor.Title
            cell?.detailTextLabel?.textColor = UIColor.gray
            if 2==indexPath.section {
                let switcher = UISwitch()
                switcher.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged)
                switcher.sizeToFit()
                cell?.accessoryView = switcher
            }
        }
        
        switch indexPath.section {
        case 0:
            if 0 == indexPath.row {
                for pair in self.accessControl {
                    if pair.type == self.selectedAccessControl {
                        cell?.textLabel?.text = pair.desc
                        break
                    }
                }
                cell?.accessoryType = .disclosureIndicator
                cell?.selectionStyle = .default
            } else {
                cell?.textLabel?.text = self.password ?? ""
                cell?.accessoryType = .disclosureIndicator
                cell?.selectionStyle = .none
            }
        case 1:
            if 0 == indexPath.row {
                let pair = self.datelineControl[self.selectedDatelineControl]
                cell?.textLabel?.text = pair.key
            } else {
                cell?.textLabel?.text = self.password ?? ""
            }
            cell?.accessoryType = .disclosureIndicator
            cell?.selectionStyle = .default
        case 2:
            if 0 == indexPath.row {
                cell?.textLabel?.text = "允许下载"
                if let sw = cell?.accessoryView as? UISwitch {
                    sw.tag = 100
                    sw.setOn(self.allowDownload, animated: false)
                }
            } else {
                cell?.textLabel?.text = "允许上传"
                if let sw = cell?.accessoryView as? UISwitch {
                    sw.tag = 200
                    sw.setOn(self.allowUpload, animated: false)
                }
            }
            cell?.selectionStyle = .none
        default:
            break
        }
        
        
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if 0 == indexPath.section && 0 == indexPath.row {
            let actionsheet = UIAlertController(title: YKLocalizedString("访问控制"), message: nil, preferredStyle: .actionSheet)
            for index in 0..<self.accessControl.count {
                let item = self.accessControl[index]
                let act = UIAlertAction(title: item.desc, style: .default, handler: { (act:UIAlertAction) in
                    self.selectedAccessControl = item.type
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                })
                actionsheet.addAction(act)
            }
            let actCancel = UIAlertAction(title: YKString.kYKCancel, style: .cancel, handler: nil)
            actionsheet.addAction(actCancel)
            self.present(actionsheet, animated: true, completion: nil)
            
        } else if 0 == indexPath.section && 0 == indexPath.row {
            
            
        }
        
    }
}
