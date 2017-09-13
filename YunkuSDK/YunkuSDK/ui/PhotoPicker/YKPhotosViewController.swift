//
//  YKPhotosViewController.swift
//  YunkuSDK
//
//  Created by wqc on 2017/9/8.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import Photos

class YKAssetCell : UICollectionViewCell {
    
    var imageView: UIImageView!
    var selectIcon: UIImageView!
    var videoIcon: UIImageView!
    var videoBar: UIView!
    var videoDuration: UILabel!
    
    var asset: YKAssetItem?
    
    let selectIconSize: CGFloat = 27
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        var rect = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        self.imageView = UIImageView(frame: rect)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        self.addSubview(imageView)
        
        rect.size = CGSize(width: selectIconSize, height: selectIconSize)
        selectIcon = UIImageView(frame: rect)
        selectIcon.image = YKImage("unselect", nil, "PhotoPicker")
        selectIcon.contentMode = .scaleAspectFill
        self.addSubview(selectIcon)
    }
    
    func bindAsset(_ asset: YKAssetItem) {
        self.asset = asset
        self.imageView.image = asset.thumb
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var rect = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        self.imageView.frame = rect
        
        rect.origin.x = self.frame.size.width - selectIconSize
        rect.origin.y = self.frame.size.height - selectIconSize
        rect.size = CGSize(width: selectIconSize, height: selectIconSize)
        self.selectIcon.frame = rect
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


}

class YKPhotosViewController: YKBaseViewController,UICollectionViewDelegate,UICollectionViewDataSource {
    
    var ignoreVideo = false
    
    var collectionView: UICollectionView!
    var bottomBar: UIView!
    var okBtn: UIButton!
    var originalBtn: UIButton!
    var countLabel: UILabel!
    var sizeLabel: UILabel!
    
    var album: YKAlbum!
    
    var assets = [YKAssetItem]()
    
    init(album: YKAlbum) {
        self.album = album
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = []
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.setupViews()
        
        self.load()
    }
    
    func setupViews() {
        let flowLayout = UICollectionViewFlowLayout()
        let margin: CGFloat = 1
        let itemSize: CGFloat = (self.view.frame.size.width - 5*margin)/4
        flowLayout.itemSize = CGSize(width: itemSize, height: itemSize)
        flowLayout.minimumInteritemSpacing = margin
        flowLayout.minimumLineSpacing = margin
        
        
        let rect = CGRect(x: 0, y: margin, width: self.view.frame.size.width, height: self.view.frame.size.height)
        self.collectionView = UICollectionView(frame: rect, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = UIColor.white
        collectionView.showsVerticalScrollIndicator = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
        self.view.addSubview(collectionView)
        
        collectionView.register(YKAssetCell.self, forCellWithReuseIdentifier: "YKAssetCell")
    }
    
    func load() {
        DispatchQueue.global().async {
            let result = YKPhotoManager.loadAssetsOf(collection: self.album.collection, ignoreVideo: false)
            DispatchQueue.main.async {
                self.assets = result
                self.reloadData()
            }
        }
    }
    
    func reloadData() {
        self.collectionView.contentSize = CGSize(width:self.view.frame.size.width, height:CGFloat((self.assets.count+3)/4)*(self.view.frame.size.width));
        self.collectionView.reloadData()
    }
    
    //MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "YKAssetCell", for: indexPath)
        
        let item = self.assets[indexPath.row]
        if let assetCell = cell as? YKAssetCell {
            assetCell.bindAsset(item)
        }
        
        return cell
    }
}
