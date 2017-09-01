//
//  YKQuickLookPreviewController.swift
//  YunkuSDK
//
//  Created by wqc on 2017/9/1.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import QuickLook

class YKQuickLookPreviewController: YKFilePreviewBaseController, QLPreviewControllerDelegate,QLPreviewControllerDataSource {
    
    var qlController: QLPreviewController!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func showQLPreview() {
        self.qlController = QLPreviewController()
        self.qlController.delegate = self
        self.qlController.dataSource = self
        self.addChildViewController(self.qlController)
        self.qlController.view.frame = self.view.bounds
        self.view.addSubview(self.qlController.view)
        self.qlController.didMove(toParentViewController: self)
    }
    
    override func openFile() {
        self.showQLPreview()
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let newpath = self.localpath + "." + self.previewInfo.filename.gkExt
        try? FileManager.default.copyItem(atPath: self.localpath, toPath: newpath)
        let url: NSURL = NSURL(fileURLWithPath: newpath)
        return url
    }
    
}
