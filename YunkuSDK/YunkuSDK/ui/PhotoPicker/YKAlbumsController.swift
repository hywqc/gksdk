//
//  YKAlbumsController.swift
//  YunkuSDK
//
//  Created by wqc on 2017/9/8.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit
import Photos

class YKAlbumsController: YKBaseTableViewController {
    
    var albumes = [YKAlbum]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = true
        
        self.setNavTitle(YKLocalizedString("选择相册"))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: YKString.kYKCancel, style: .plain, target: self, action: #selector(onCancel))
        
        YKPhotoManager.checkAuthorization { (authorized:Bool) in
            if authorized {
                YKPhotoManager.loadAllAlbums(containVideos: false, completion: { (result:[YKAlbum]) in
                    self.albumes = result
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    func onCancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func setupTableView() {
        self.tableView.rowHeight = 64
        self.tableView.separatorStyle = .singleLine
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.albumes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        let item  = self.albumes[indexPath.row]
        cell?.textLabel?.text = "\(item.title)(\(item.count))"
        cell?.imageView?.image = item.thumb
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item  = self.albumes[indexPath.row]
        let controller = YKPhotosViewController(album: item)
        self.navigationController?.pushViewController(controller, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
