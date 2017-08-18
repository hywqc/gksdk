//
//  YKMountsListSectionView.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/9.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit

protocol YKMountsListSectionViewDelegate : AnyObject {
    func foldChangedWithView(_ view: YKMountsListSectionView,fold: Bool) -> Void
}

class YKMountsListSectionView: UIView {
    
    var titleLabel: UILabel!
    var subtitleLabel: UILabel!
    var arrow: UIImageView!
    var fold = false
    var index = 0
    unowned var delegate: YKMountsListSectionViewDelegate
    
    private var toggling = false
    
    init(frame: CGRect,title:String, subtitle:String,index:Int,fold:Bool,delegate:YKMountsListSectionViewDelegate) {
        self.delegate = delegate
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        
        let imageview = UIImageView(frame: CGRect(x: 12, y: (frame.size.height-11)/2, width: 11, height: 11))
        imageview.image = YKImage("foldarrow")
        self.addSubview(imageview)
        self.arrow = imageview
        
        var label = UILabel(frame: CGRect.zero)
        label.text = title
        label.textColor = YKColor.Title
        label.textAlignment = .left
        label.font = YKFont.make(16)
        label.sizeToFit()
        label.frame = CGRect(x: imageview.frame.maxX+12, y: 0, width: label.frame.size.width, height: frame.size.height)
        self.addSubview(label)
        self.titleLabel = label
        
        label = UILabel(frame: CGRect.zero)
        label.text = subtitle
        label.textColor = YKColor.SubTitle
        label.textAlignment = .left
        label.font = YKFont.make(14)
        label.sizeToFit()
        label.frame = CGRect(x: titleLabel.frame.maxX+5, y: 0, width: label.frame.size.width, height: frame.size.height)
        self.addSubview(label)
        self.subtitleLabel = label
        
        self.index = index
        self.fold = fold
        if fold {
            self.arrow.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi/2))
        } else {
            self.arrow.transform = CGAffineTransform.identity
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureHandler(gesture:)))
        self.addGestureRecognizer(tapGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    func tapGestureHandler(gesture: UIGestureRecognizer) {
        
        if gesture.state == .ended {
            if toggling {
                return
            }
            
            toggling = true
            if fold {
                UIView.animate(withDuration: 0.1, animations: { 
                    self.arrow.transform = CGAffineTransform.identity
                }, completion: { (finished: Bool) in
                    if finished {
                        self.fold = false
                        self.toggling = false
                    }
                })
                self.delegate.foldChangedWithView(self, fold: false)
            } else {
                UIView.animate(withDuration: 0.1, animations: {
                    self.arrow.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi/2))
                }, completion: { (finished: Bool) in
                    if finished {
                        self.fold = true
                        self.toggling = false
                    }
                })
                self.delegate.foldChangedWithView(self, fold: true)
            }
        }
    }
}
