//
//  YKPhotoManager.swift
//  YunkuSDK
//
//  Created by wqc on 2017/9/8.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation
import Photos


struct YKPhotoPickConfig {
    
    var ignoreVideo = false
    var limit = 0
    var multiSelect = true
    
}

class YKAssetItem {
    var original = false
    var isVideo = false
    var asset: PHAsset!
    var thumb: UIImage?
    var checked = false
}

class YKAlbum {
    var title = ""
    var count = 0
    var isVideo = false
    var collection: PHAssetCollection!
    var thumb: UIImage?
}

class YKPhotoManager {
    
    class func checkAuthorization(completion:((Bool)->Void)?) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (reqStatus:PHAuthorizationStatus) in
                completion?(reqStatus == .authorized)
            })
        case .denied,.restricted:
            completion?(false)
            break
        default:
            completion?(true)
            break
        }
    }
    
    class func loadAllAlbums(containVideos:Bool,completion:(([YKAlbum])->Void)?) {
        
        DispatchQueue.global().async {
            let opt = PHFetchOptions()
            opt.wantsIncrementalChangeDetails = false
            var result = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: opt)
            var albums = [YKAlbum]()
            
            let reqOpt =  PHImageRequestOptions()
            reqOpt.isSynchronous = true
            reqOpt.version = .current
            
            result.enumerateObjects({ (collection:PHAssetCollection, index:Int, stop:UnsafeMutablePointer<ObjCBool>) in
                if !containVideos && collection.assetCollectionSubtype == .smartAlbumVideos {
                    return
                }
                if collection.assetCollectionSubtype == .smartAlbumAllHidden {
                    return
                }
                
                if collection.localizedTitle == nil {
                    return
                }
                
                
                let res = PHAsset.fetchAssets(in: collection, options: opt)
                if res.count <= 0 {
                    return
                }
                
                let a = YKAlbum()
                a.title = collection.localizedTitle!
                a.isVideo = (collection.assetCollectionSubtype == .smartAlbumVideos)
                a.count = res.count
                a.collection = collection
                
                let asset = res.firstObject
                PHImageManager.default().requestImage(for: asset!, targetSize: CGSize(width:100,height:100), contentMode: .aspectFit, options: reqOpt, resultHandler: { (img:UIImage?, info:[AnyHashable : Any]?) in
                    a.thumb = img
                })
                
                albums.append(a)
            })
            
            result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            result.enumerateObjects({ (collection:PHAssetCollection, index:Int, stop:UnsafeMutablePointer<ObjCBool>) in
                
                if collection.localizedTitle == nil {
                    return
                }
                let res = PHAsset.fetchAssets(in: collection, options: opt)
                if res.count <= 0 {
                    return
                }
                
                let a = YKAlbum()
                a.title = collection.localizedTitle!
                a.isVideo = (collection.assetCollectionSubtype == .smartAlbumVideos)
                a.count = res.count
                a.collection = collection
                
                
                let asset = res.firstObject
                PHImageManager.default().requestImage(for: asset!, targetSize: CGSize(width:100,height:100), contentMode: .aspectFit, options: reqOpt, resultHandler: { (img:UIImage?, info:[AnyHashable : Any]?) in
                    a.thumb = img
                })
                
                albums.append(a)
            })
            DispatchQueue.main.async {
                completion?(albums)
            }
        }
    }
    
    class func loadAssetsOf(collection: PHAssetCollection, ignoreVideo:Bool) -> [YKAssetItem] {
        
        let opt = PHFetchOptions()
        opt.wantsIncrementalChangeDetails = false
        let res = PHAsset.fetchAssets(in: collection, options: opt)
        
        let reqOpt =  PHImageRequestOptions()
        reqOpt.isSynchronous = true
        reqOpt.version = .current
        
        var result = [YKAssetItem]()
        res.enumerateObjects({ (asset:PHAsset, index:Int, stop:UnsafeMutablePointer<ObjCBool>) in
            
            if ignoreVideo && (asset.mediaType == .video || asset.mediaType == .audio){
                return
            }
            
            let a = YKAssetItem()
            a.asset = asset
            
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width:200,height:200), contentMode: .aspectFit, options: reqOpt, resultHandler: { (img:UIImage?, info:[AnyHashable : Any]?) in
                
                a.thumb = img
            })
            
            result.append(a)
        })
        
        return result
    }
    
    class func showMultiPhotoPicker(completion:(([YKAssetItem])->Void)?) {
        
    }
}
