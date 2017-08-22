//
//  YKBottomSheetView.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/21.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit


class YKBottomSheetView: UIView,UIScrollViewDelegate {
    
    private let BtnSize: CGFloat = 48
    private let BtnTextHeight: CGFloat = 20
    private let TitleHeight: CGFloat = 35
    private let CancelBtnHeight: CGFloat = 40
    
    struct Item {
        var title = ""
        var id = 0
        var image = ""
    }
    
    var maskBtn: UIButton?
    
    var title: String?
    var message: String?
    var cancelTitle: String?
    
    var titleLabel: UILabel?
    var messageLabel: UILabel?
    var cancelButton: UIButton?
    var scrollView: UIScrollView!
    var pageControl: UIPageControl?
    
    var completion: ((Int,Any?)->Void)?
    
    var data = [Item]()
    var param: Any?
    var parentView: UIView?
    
    class func show(items:[Item], title:String? = nil, message:String? = nil, cancelTitle:String? = nil, param:Any? = nil, parentView: UIView? = nil,completion:((Int,Any?)->Void)?) {
        
        let sheet = YKBottomSheetView(items: items, title: title, message: message, cancelTitle: cancelTitle, completion: completion, param: param, parentView: parentView)
        sheet.show()
    }
    
    private init(items:[Item], title:String? = nil, message:String? = nil, cancelTitle:String? = nil, completion:((Int,Any?)->Void)?, param:Any? = nil, parentView: UIView? = nil) {
        self.title = title
        self.message = message
        self.cancelTitle = cancelTitle
        self.data = items
        self.completion = completion
        self.param = param
        self.parentView = parentView
        super.init(frame: CGRect.zero)
        
        if title != nil {
            let label = UILabel(frame: CGRect.zero)
            label.backgroundColor = UIColor.clear
            label.textColor = YKColor.Title
            label.font = YKFont.make(15)
            label.textAlignment = .center
            label.text = title!
            self.titleLabel = label
            self.addSubview(label)
        }
        
        if message != nil {
            let label = UILabel(frame: CGRect.zero)
            label.backgroundColor = UIColor.clear
            label.textColor = YKColor.SubTitle
            label.font = YKFont.make(12)
            label.textAlignment = .center
            label.text = message!
            self.messageLabel = label
            self.addSubview(label)
        }
        
        if self.cancelTitle != nil {
            let btn = UIButton(type: .custom)
            btn.backgroundColor = UIColor.white
            btn.setTitleColor(YKColor.Title, for: .normal)
            btn.titleLabel?.font = YKFont.Title
            btn.titleLabel?.textAlignment = .center
            btn.setTitle(self.cancelTitle!, for: .normal)
            btn.addTarget(self, action: #selector(onCancelBtn), for: .touchUpInside)
            self.addSubview(btn)
            self.cancelButton = btn
        }
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        let screenRect = UIScreen.main.bounds
        let minInterval: CGFloat = 25
        var maxOfOneline = Int(screenRect.size.width / BtnSize)
        while screenRect.size.width < (CGFloat(maxOfOneline)*BtnSize + (CGFloat(maxOfOneline)+1)*minInterval) {
            maxOfOneline -= 1
        }
        
        var numOfRows = data.count / maxOfOneline
        if data.count % maxOfOneline > 0 {
            numOfRows += 1
        }
        
        numOfRows = min(2, numOfRows)
        
        let numOfOneline = min(maxOfOneline, data.count)
        
        let btnSpacingH = (screenRect.size.width - CGFloat(numOfOneline)*BtnSize)/(CGFloat(numOfOneline)+1)
        
        var pages = 1
        if numOfOneline * numOfRows < data.count {
            let pagecontrol = UIPageControl(frame: CGRect.zero)
            pagecontrol.backgroundColor = self.backgroundColor
            pagecontrol.hidesForSinglePage = true
            pagecontrol.defersCurrentPageDisplay = true
            pagecontrol.pageIndicatorTintColor = UIColor(white: 0.778, alpha: 1)
            pagecontrol.currentPageIndicatorTintColor = UIColor(white: 0.571, alpha: 1)
            self.addSubview(pagecontrol)
            pages = (data.count/(numOfRows*numOfOneline))
            if data.count % (numOfRows*numOfOneline) > 0 {
                pages += 1
            }
            pagecontrol.numberOfPages = pages
            self.pageControl = pagecontrol
        }
        
        let scrollview = UIScrollView(frame: CGRect.zero)
        scrollview.showsVerticalScrollIndicator = false
        scrollview.showsHorizontalScrollIndicator = false
        scrollview.scrollsToTop = false
        scrollview.isPagingEnabled = true
        scrollview.backgroundColor = self.backgroundColor
        self.scrollView = scrollview
        self.addSubview(scrollview)
        
        var scrollviewPaddingTop: CGFloat = 10
        let scrollviewPaddingBottom: CGFloat = 10
        var totalHeight: CGFloat = 0
        if title != nil {
            totalHeight += TitleHeight
        }
        
        var messageSize: CGSize?
        if message != nil {
            messageSize = message!.gkSize(maxWidth: screenRect.size.width-30, font: messageLabel!.font)
            totalHeight += (messageSize!.height+1)
        }
        
        if title == nil && message == nil {
            scrollviewPaddingTop *= 2
        }
        
        let btnSpacingV: CGFloat = 10
        let pagecontrolHeight: CGFloat = 20
        
        let scrollviewHeight = (CGFloat(numOfRows)*(BtnSize+BtnTextHeight)) + scrollviewPaddingTop + scrollviewPaddingBottom + (CGFloat(numOfRows)-1)*btnSpacingV
        
        totalHeight += scrollviewHeight
        
        if pages > 1 {
            totalHeight += pagecontrolHeight
        }
        
        if cancelTitle != nil {
            totalHeight += CancelBtnHeight
            self.backgroundColor = YKColor.RGBA(248, 248, 248)
        } else {
            totalHeight += 20
            self.backgroundColor = UIColor.white
        }
        
        self.frame = CGRect(x: 0, y: screenRect.size.height - totalHeight, width: screenRect.size.width, height: totalHeight)
        
        var y: CGFloat = 0
        var rect = CGRect.zero
        if titleLabel != nil {
            rect.origin.x = 0
            rect.origin.y = 0
            rect.size = CGSize(width: screenRect.size.width, height: TitleHeight)
            titleLabel!.frame = rect
            y = rect.maxY
        }
        
        if message != nil {
            rect.origin = CGPoint(x: 15, y: y)
            rect.size = messageSize!
            messageLabel!.frame = rect
            y = rect.maxY
        }
        
        scrollview.frame = CGRect(x: 0, y: y, width: screenRect.size.width, height: scrollviewHeight)
        y = scrollview.frame.maxY
        
        if pageControl != nil {
            pageControl!.frame = CGRect(x: 0, y: y, width: screenRect.size.width, height: pagecontrolHeight)
            y = pageControl!.frame.maxY
        }
        
        if cancelButton != nil {
            cancelButton?.frame = CGRect(x: 0, y: y, width: screenRect.size.width, height: CancelBtnHeight)
        }
        
        let onePageCount = numOfRows*numOfOneline
        
        for p in 0..<pages {
            var rc = scrollview.bounds
            rc.origin.x = CGFloat(p)*scrollview.frame.size.width
            let container = UIView(frame: rc)
            
            let remians = data.count - p*onePageCount
            let start = p*onePageCount
            let count = min(remians, onePageCount)
            
            for index in 0..<count {
                
                let item = data[start+index]
                
                let btn = UIButton(type: .custom)
                var btnframe = CGRect(x: 0, y: 0, width: BtnSize, height: BtnSize)
                btnframe.origin.x = BtnSize*(CGFloat(index%numOfOneline))+(CGFloat(index%numOfOneline+1))*btnSpacingH
                btnframe.origin.y = scrollviewPaddingTop + CGFloat(index/numOfOneline)*(BtnSize+BtnTextHeight) + CGFloat(index/numOfOneline)*btnSpacingV
                btn.frame = btnframe
                btn.backgroundColor = UIColor.clear
                btn.setImage(YKImage(item.image), for: .normal)
                btn.tag = item.id
                btn.addTarget(self, action: #selector(onBtn(button:)), for: .touchUpInside)
                
                var labelframe = CGRect(x: 0, y: 0, width: BtnSize, height: BtnTextHeight)
                let offset: CGFloat = btnSpacingH/2-5
                labelframe.origin.x = btnframe.minX-offset
                labelframe.origin.y = btnframe.maxY
                labelframe.size.width = BtnSize+2*offset
                let label = UILabel(frame: labelframe)
                label.textColor = YKColor.SubTitle
                label.font = YKFont.SubTitle
                label.textAlignment = .center
                label.backgroundColor = UIColor.clear
                label.text = item.title
                
                container.addSubview(btn)
                container.addSubview(label)
            }
            
            scrollview.addSubview(container)
        }
        
        scrollview.contentSize = CGSize(width: screenRect.size.width*CGFloat(pages), height: scrollview.frame.size.height)
    }
    
    private func show() {
        
        maskBtn = UIButton(type: .custom)
        maskBtn!.frame = UIScreen.main.bounds
        maskBtn!.backgroundColor = YKColor.RGBA(0, 0, 0, 0.2)
        maskBtn!.addTarget(self, action: #selector(onDismiss), for: .touchUpInside)
        maskBtn!.addSubview(self)
        
        if parentView != nil {
            parentView!.addSubview(maskBtn!)
        } else {
            let win = UIApplication.shared.keyWindow
            win?.rootViewController?.view.addSubview(maskBtn!)
        }
        
        maskBtn!.addSubview(self)
        
        maskBtn!.alpha = 0
        self.alpha = 0
        
        let to = self.frame
        var from = to
        from.origin.y += to.size.height
        self.frame = from
        
        UIView.animate(withDuration: 0.2, animations: { 
            self.frame = to
            self.maskBtn!.alpha = 1
            self.alpha = 1
        }, completion: nil)
    }
    
    func onBtn(button:UIButton) {
        let id = button.tag
        dismiss()
        completion?(id,param)
    }
    
    func onCancelBtn() {
        dismiss()
    }
    
    func onDismiss() {
        dismiss()
    }
    
    private func dismiss(animate:Bool = true) {
        var rc = self.frame
        rc.origin.y += rc.size.height
        if animate {
            UIView.animate(withDuration: 0.2, animations: {
                self.frame = rc
                self.maskBtn?.alpha = 0
                self.alpha = 0
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
    
    //MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var page = Int(scrollView.contentOffset.x/scrollView.frame.size.width)
        if pageControl != nil {
            page = max(0, min(page, pageControl!.numberOfPages))
            if page != pageControl!.currentPage {
                pageControl!.currentPage = page
            }
        }
    }
}
