//
//  YKTextPreviewController.swift
//  YunkuSDK
//
//  Created by wqc on 2017/9/1.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation

class YKTextPreviewController: YKFilePreviewBaseController {
    
    var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let textview = UITextView(frame: self.view.bounds)
        textview.textColor = YKColor.Title
        textview.font = YKFont.make(14)
        textview.backgroundColor = UIColor.white
        textview.autoresizingMask = [.flexibleHeight,.flexibleWidth]
        textview.autocorrectionType = .no
        textview.autocapitalizationType = .none
        textview.spellCheckingType = .no
        textview.isScrollEnabled = true
        textview.keyboardType = .default
        textview.returnKeyType = .next
        textview.isUserInteractionEnabled = true
        textview.isEditable = false
        self.view.addSubview(textview)
        self.textView = textview
        self.textView.isHidden = true
    }
    
    override func openFile() {
        
        DispatchQueue.global().async {
            if let content = try? String(contentsOfFile: self.localpath, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.textView.text = content
                    self.textView.isHidden = false
                }
            }
        }
        
    }
}
