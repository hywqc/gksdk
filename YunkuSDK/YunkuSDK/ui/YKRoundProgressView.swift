//
//  YKRoundProgressView.swift
//  YunkuSDK
//
//  Created by wqc on 2017/9/4.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation


class YKRoundProgressView : UIView {
    
    
    var annular = true
    var bkgColor = UIColor.init(white: 1, alpha: 0.3)
    let progressTintColor = YKColor.RGBA(161, 161, 161)
    let progressFont = YKFont.make(12)
    
    var progress: Float = 0.0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        
        let sz = self.bounds.size
        //let circleRect = self.bounds.insetBy(dx: 2, dy: 2)
        //let context = UIGraphicsGetCurrentContext()
        
        if self.annular {
            let lineWidth: CGFloat = 2
            let processBackgroundPath = UIBezierPath()
            processBackgroundPath.lineWidth = lineWidth
            processBackgroundPath.lineCapStyle = .butt
            let center = CGPoint(x:sz.width/2,y:sz.height/2)
            let radius = (sz.width - lineWidth)/2
            let startAngle = CGFloat(-(Double.pi / 2));
            var endAnglr = CGFloat(CGFloat(2*Double.pi) + startAngle)
            processBackgroundPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAnglr, clockwise: true)
            self.bkgColor.set()
            processBackgroundPath.stroke()
            
            let processPath = UIBezierPath()
            processPath.lineCapStyle = .square
            processPath.lineWidth = lineWidth
            endAnglr = CGFloat((self.progress * 2 * Float(Double.pi))) + startAngle
            processPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAnglr, clockwise: true)
            progressTintColor.set()
            processPath.stroke()
            
            let np = min(100, Int(self.progress*100))
            let pstr = "\(np)%"
            let strsz = pstr.gkSize(maxWidth: sz.width, font: progressFont)
            let rcstr = CGRect(x: (sz.width - strsz.width)/2, y: (sz.height - strsz.height)/2, width: strsz.width, height: strsz.height)
            (pstr as NSString).draw(in: rcstr, withAttributes: [NSForegroundColorAttributeName : UIColor.white,
                                                                NSFontAttributeName:self.progressFont])
        }
    }
}
