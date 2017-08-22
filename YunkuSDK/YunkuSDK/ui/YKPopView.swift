//
//  YKPopView.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/18.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit
import gkutility


final class YKPopView : UIView {
    
    let titleColor = YKColor.Title
    let titleFont = YKFont.Title
    let bgColor = UIColor.white
    let btnHeight: CGFloat = 44
    
    var showPoint = CGPoint.zero
    var arrowPoint = CGPoint.zero
    
    var screentRect: CGRect!
    
    var maskBtn: UIButton?

    var completion: ((Int)->Void)?
    
    struct Item {
        var text = ""
        var textColor: UIColor?
        var image: String?
        var id = 0
    }
    
    var items = [Item]()
    
    
    private let vspacing: CGFloat = 2
    private let arrowSize: CGFloat = 4
    
    class func showItems(_ items: [Item], completion:((Int)->Void)?, event: UIEvent) {
        let pop = YKPopView(items: items, completion: completion)
        pop.showWithTouch(event: event)
        
    }
    
    init(items: [Item], completion: ((Int)->Void)?) {
        self.items = items
        self.completion = completion
        screentRect = UIScreen.main.bounds
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        
        let roundFrame = CGRect(x: 0, y: arrowSize, width: self.bounds.size.width, height: self.bounds.size.height - arrowSize)
        
        let xMin = roundFrame.minX
        let yMin = roundFrame.minY
        
        
        let roundPath = UIBezierPath(roundedRect: CGRect(x: xMin, y: yMin, width: roundFrame.size.width, height: roundFrame.size.height), cornerRadius: 3)
        
        let arrowPath = UIBezierPath()
        
        arrowPath.move(to: CGPoint(x: arrowPoint.x - arrowSize, y: yMin))
        arrowPath.addLine(to: arrowPoint)
        arrowPath.addLine(to: CGPoint(x: arrowPoint.x + arrowSize, y: yMin))
        arrowPath.close()
        
        bgColor.setFill()
        roundPath.append(arrowPath)
        roundPath.fill()
    }
    
    func showWithTouch(event: UIEvent) {
        if let touchs = event.allTouches {
            if touchs.isEmpty { return }
            let sendView = (touchs.first?.view)!
            let win = UIApplication.shared.keyWindow
            let pointInWindow = sendView.convert(CGPoint.zero, to: win?.rootViewController?.view)
            let sendFrame = CGRect(x: pointInWindow.x, y: pointInWindow.y, width: sendView.frame.size.width, height: sendView.frame.size.height)
            showPoint = CGPoint(x: sendFrame.origin.x + sendFrame.size.width/2, y: sendFrame.maxY)
            self.calcFrame()
            self.show()
        }
    }
    
    private func calcFrame() {
        
        var rect = CGRect.zero
        rect.size.height = CGFloat(items.count)*btnHeight + vspacing*2 + arrowSize
        
        var width: CGFloat = 0
        for item in items {
            let s = item.text
            let sz = s.gkSize(maxWidth: CGFloat.greatestFiniteMagnitude, font: titleFont)
            width = max(width, sz.width)
        }
        rect.size.width = width + 60
        rect.origin.x = showPoint.x - rect.size.width/2
        rect.origin.y = showPoint.y
        
        if rect.origin.x < 5 {
            rect.origin.x = 5
        }
        
        if  (rect.origin.x + rect.size.width) > (screentRect.size.width - 5)  {
            rect.origin.x = screentRect.size.width - 5 - rect.size.width
        }
        
        self.frame = rect
    }
    
    private func setupBtns() {
        
        var y = vspacing + arrowSize
        let lineh = 1.0/UIScreen.main.scale
        for index in 0..<items.count {
            let item = items[index]
            let btn = UIButton(type: .custom)
            btn.setTitle(item.text, for: .normal)
            btn.setTitleColor((item.textColor != nil ? item.textColor : titleColor), for: .normal)
            btn.titleLabel?.textAlignment = .center
            btn.titleLabel?.font = titleFont
            btn.tag = item.id
            btn.frame = CGRect(x: 2, y: y, width: self.frame.size.width-4, height: btnHeight)
            btn.addTarget(self, action: #selector(onClieckItem(button:)), for: .touchUpInside)
            self.addSubview(btn)
            y += btnHeight
            
            if index != (items.count - 1)  {
                let line = UIView(frame: CGRect(x: 10, y: btn.frame.maxY-lineh, width: btn.frame.size.width-20, height: lineh))
                line.isOpaque = true
                line.backgroundColor = YKColor.Separator
                self.addSubview(line)
            }
        }
        
    }
    
    func onClieckItem(button: UIButton) {
        let id = button.tag
        self.dismiss(animate: true)
        completion?(id)
    }
    
    private func show() {
        
        maskBtn = UIButton(type: .custom)
        maskBtn!.frame = screentRect
        maskBtn!.backgroundColor = YKColor.RGBA(0, 0, 0, 0.2)
        maskBtn!.addTarget(self, action: #selector(onDismiss), for: .touchUpInside)
        maskBtn!.addSubview(self)
        
        let win = UIApplication.shared.keyWindow
        win?.rootViewController?.view.addSubview(maskBtn!)
        
        self.setupBtns()
        
        var p = self.convert(showPoint, from: maskBtn)
        if (p.x + arrowSize + 10) > self.frame.size.width {
            p.x = self.frame.size.width - arrowSize - 10
        }
        self.arrowPoint = p
        self.layer.anchorPoint = CGPoint(x: p.x/self.frame.size.width, y: p.y/self.frame.size.height)
        self.calcFrame()
        
        maskBtn?.alpha = 0
        self.alpha = 0
        self.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView .animate(withDuration: 0.15) { 
            self.transform = CGAffineTransform.identity
            self.alpha = 1
            self.maskBtn?.alpha = 1
        }
    }
    
    func onDismiss() {
        self.dismiss(animate: true)
    }
    
    private func dismiss(animate: Bool) {
        if animate {
            UIView.animate(withDuration: 0.2, animations: { 
                self.maskBtn?.alpha = 0.0
                self.alpha = 0.0
            }, completion: { (finished:Bool) in
                if finished {
                    self.removeFromSuperview()
                    self.maskBtn?.removeFromSuperview()
                    self.maskBtn = nil
                }
            })
        } else {
            self.removeFromSuperview()
            self.maskBtn?.removeFromSuperview()
            self.maskBtn = nil
        }
    }
}
