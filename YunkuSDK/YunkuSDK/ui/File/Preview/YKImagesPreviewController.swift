//
//  YKImagesPreviewController.swift
//  YunkuSDK
//
//  Created by wqc on 2017/9/1.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import gknet
import gkutility

class YKImagePreView : UIView {
    
    var fileItem: GKFileDataItem!
    
    var imageView: UIImageView!
    var progressView: UIProgressView!
    
    var isLoading = false
    var haveLoad = false
    
    init(frame: CGRect, file:GKFileDataItem) {
        self.fileItem = file
        super.init(frame: frame)
        self.backgroundColor = UIColor.black
        
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        imageView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        imageView.isHidden = true
        self.addSubview(imageView)
        
        progressView = UIProgressView(frame: CGRect(x: 30, y: 250, width: frame.size.width-60, height: 5))
        progressView.setProgress(0, animated: false)
        self.addSubview(progressView)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func load() {
        if isLoading || haveLoad { return }
        isLoading = true
        let webhost = (YKClient.shareInstance.https ? "https://" : "http://") +  YKClient.shareInstance.webHost
        if let url = URL(string: fileItem.thumb(webhost: webhost, big: true)) {
            self.imageView.sd_setImageWithPreviousCachedImage(with: url, placeholderImage: nil, options: [], progress: { [weak self] (receivedSize:Int, expectedSize:Int, url:URL?) in
                self?.progressView.progress = Float(receivedSize)/Float(expectedSize)
            }, completed: { [weak self] (image:UIImage?, error:Error?, type:SDImageCacheType, url:URL?) in
                self?.progressView.isHidden = true
                self?.imageView.isHidden = false
                self?.isLoading = false
                self?.haveLoad = true
            })
        }
    }
    
}

class YKImagesPreviewController: YKBaseViewController, UIScrollViewDelegate {
    
    var scrollView: UIScrollView!
    var imageViews = [YKImagePreView]()
    var files = [GKFileDataItem]()
    
    var currentIndex = 0
    
    init(files:[GKFileDataItem]) {
        self.files = files
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = []
        self.setupViews()
        self.navigationItem.leftBarButtonItem = self.cancelBarButton
        self.gotoImage(index: 0)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.layout()
    }
    
    var cancelBarButton: UIBarButtonItem {
        return UIBarButtonItem(title: YKString.kYKCancel, style: .plain, target: self, action: #selector(onCancel))
    }
    
    func setupViews() {
        
        scrollView = UIScrollView(frame: self.view.bounds)
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.autoresizesSubviews = false
        scrollView.scrollsToTop = false
        scrollView.delegate = self
        self.view.addSubview(scrollView)
        
        for item in files {
            let v = YKImagePreView(frame: self.scrollView.bounds, file: item)
            self.imageViews.append(v)
            self.scrollView.addSubview(v)
        }
        
        scrollView.contentSize = CGSize(width:CGFloat(files.count)*self.scrollView.frame.size.width,height:self.scrollView.frame.size.height)
    }
    
    func layout() {
        self.scrollView.frame = self.view.bounds
        scrollView.contentSize = CGSize(width:CGFloat(files.count)*self.view.frame.size.width,height:self.view.frame.size.height)
        for i in 0..<self.files.count {
            let rc = CGRect(x: self.scrollView.frame.size.width*CGFloat(i), y: 0, width: self.scrollView.frame.size.width, height: self.scrollView.frame.size.height)
            let v = self.imageViews[i]
            v.frame = rc
        }
    }
    
    func gotoImage(index:Int) {
        let v = self.imageViews[index]
        let f = self.files[index]
        self.setNavTitle(f.filename)
        v.load()
    }
    
    func onCancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x > 0 {
            var index = Int(scrollView.contentOffset.x) / Int(scrollView.frame.size.width)
            if index  == currentIndex { return }
            
            index = min(index, self.files.count-1)
            index = max(index, 0)
            
            currentIndex = index
            
            self.gotoImage(index: index)
        }
    }
}
