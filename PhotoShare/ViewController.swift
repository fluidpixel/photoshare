//
//  ViewController.swift
//  PhotoShare
//
//  Created by Lauren Brown on 22/07/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import UIKit
import Photos
import Accounts
import Social
import Photos

@available(iOS 9.0, *)
class ViewController: UIViewController, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver {
    
    @IBOutlet weak var galleryButton: UIButton!
    
    @IBOutlet weak var ImageCollection: UICollectionView!

    var collectionHeader:PhotoShareReusableView?

    var assets:PHFetchResult?
    var shareCache = PHCachingImageManager()
    var viewCache = PHImageManager.defaultManager()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Initiliase Photo Library Fetch
        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = 25
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        self.assets = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: fetchOptions)
        
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ImageCollection.delegate = self
        ImageCollection.dataSource = self
        ImageCollection.allowsMultipleSelection = true
        
        let nib = UINib(nibName: "PhotoShareReuseView", bundle: nil)
        ImageCollection.registerNib(nib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "PhotoShareReuseView")
        
        ImageCollection.reloadData()
    }
    
    func showLoginAlert(identifier : String){
        
        print("User is trying to share via \(identifier) when they are not logged in")
        
        let alert = UIAlertController(title: "Login Error", message: "You are trying to share with \(identifier) without logging in. Would you like to login?", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { ( _ : UIAlertAction) -> Void in
            
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            
            alert.dismissViewControllerAnimated(true, completion: { () -> Void in
                
            })
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
            alert.dismissViewControllerAnimated(true, completion: { () -> Void in
                print("User chose not to login")
            })
        }))
        
        self.showViewController(alert, sender: self)
    }
    
    func ShareMessage(type : String, message : String) {

        let alert = UIAlertController(title: "Share \(type)", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil))
        self.showViewController(alert, sender: self)
    }
    
    
    @IBAction func ShareWithFB(sender: UIButton) {
        self.retrieveImageArray {
            (selectedImages:[UIImage]) -> Void in
            
            if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook) {
                
                let sheet: SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
                
                sheet.setInitialText("")
                
                for image in selectedImages {
                    
                    sheet.addImage(image)
                }
                
                sheet.completionHandler = { (result : SLComposeViewControllerResult) in
                    
                    switch result {
                    case SLComposeViewControllerResult.Cancelled:
                        print("Post cancelled")
                        break
                    case SLComposeViewControllerResult.Done:
                        print("Post sent")
                        self.ClearAllSelections()
                        self.ShareMessage("Complete", message: "")
                    }
                }
                self.presentViewController(sheet, animated: true, completion: nil)
                
            }
            else {
                
                if selectedImages.count > 0 {
                    Classes.shareClass.SendToFB(selectedImages, message: nil) { (result, detail) -> () in
                        if result == true {
                            
                            print("INFO: Photo shared - Facebook")
                            self.ShareMessage("Complete", message: detail as! String)
                            
                        } else if detail as? String == "Account"{
                            
                            self.showLoginAlert("Facebook")
                            
                        } else if result == false {
                            
                            self.ShareMessage("Error", message: detail as! String)
                        }
                    }
                }
                else {
                    self.ShareMessage("Error", message: "You haven't selected any images")
                }
            }
        }
    }
    
    @IBAction func ShareWithTwitter(sender: UIButton) {
        
        if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
            
            if let indexPaths = self.ImageCollection.indexPathsForSelectedItems() where indexPaths.count == 1,
                let asset = self.assets?.firstObject as? PHAsset {
                    
                    
                    let options = PHImageRequestOptions()
                    //options.synchronous = true
                    options.deliveryMode = .HighQualityFormat
                    //options.resizeMode = .None
                    
                    let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                    
                    PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: targetSize, contentMode: .AspectFit, options: options) {
                        (img:UIImage?, info:[NSObject : AnyObject]?) -> Void in
                        if let image = img {
                            dispatch_async(dispatch_get_main_queue()) {
                                
                                let sheet: SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
                                
                                sheet.setInitialText("")
                                
                                sheet.addImage(image)
                                
                                sheet.completionHandler = { (result : SLComposeViewControllerResult) in
                                    
                                    switch result {
                                    case SLComposeViewControllerResult.Cancelled:
                                        print("Post cancelled")
                                        break
                                    case SLComposeViewControllerResult.Done:
                                        print("Post sent")
                                        self.ClearAllSelections()
                                        self.ShareMessage("Complete", message: "")
                                    }
                                    
                                    
                                }
                                self.presentViewController(sheet, animated: true, completion: nil)
                            }
                        }
                    }
            }
        }
    }
    
    func ClearAllSelections() {
        
        for indexPath : NSIndexPath in ImageCollection.indexPathsForSelectedItems()! {
            
            ImageCollection.deselectItemAtIndexPath(indexPath, animated: false)
        }
    }
    
    
    
    //collection view methods
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ImageCell", forIndexPath: indexPath) as! ImageCollectionCell
        
        if indexPath.row < assets?.count {
            if let asset = assets?[indexPath.row] as? PHAsset {
                cell.localIdentifier = asset.localIdentifier
                
                viewCache.requestImageForAsset(asset, targetSize: cell.frame.size, contentMode: .AspectFit, options: nil) {
                    (img:UIImage?, info:[NSObject : AnyObject]?) -> Void in
                    if cell.localIdentifier == asset.localIdentifier, let image = img {
                        cell.CellImage.image = image
                    }
                    else if img == nil {
                        print("An error occurred retrieving data from the photo library")
                        print(info)
                    }
                }
            }
        }

        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets?.count ?? 0
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.setCollectionViewHeader()
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        self.setCollectionViewHeader()
    }
    
    //collection view flow layout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let pictureDimension = view.frame.size.width / 4.0
        
        return CGSizeMake(pictureDimension, pictureDimension)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        
        let leftRightInset = view.frame.size.width / 14.0
        return UIEdgeInsetsMake(0, leftRightInset, 0, leftRightInset)
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            
            if let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "PhotoShareReuseView", forIndexPath: indexPath) as? PhotoShareReusableView {
                self.collectionHeader = headerView
                self.setCollectionViewHeader()
                return headerView
            }
            
        default:
            break
            
        }
        return UICollectionReusableView()
    }
    
    
    
    func setCollectionViewHeader() {
        let selectionCount = self.ImageCollection.indexPathsForSelectedItems()?.count ?? 0
        if selectionCount > 0 {
            self.collectionHeader?.commentLabel.text = "PhotoShare sharing \(selectionCount) images"
        }
        else {
            self.collectionHeader?.commentLabel.text = "PhotoShare"
        }
    }
    

    // MARK: PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(changeInstance: PHChange) {
        // TODO:
        
    }
    
    
    // MARK: Photo library utilities
    func retrieveImageArray(toBlock:([UIImage]) -> Void ) {
        if let indexPaths = self.ImageCollection.indexPathsForSelectedItems() where indexPaths.count > 0 {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
                
                var rv:[UIImage] = []
                for index in indexPaths {
                    if let asset = self.assets?[index.row] as? PHAsset {
                        
                        let options = PHImageRequestOptions()
                        options.synchronous = true
                        options.deliveryMode = .HighQualityFormat
                        options.resizeMode = .None
                        
                        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                        
                        PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: targetSize, contentMode: .AspectFit, options: options) {
                            (img:UIImage?, info:[NSObject : AnyObject]?) -> Void in
                            if let image = img {
                                rv.append(image)
                            }
                        }
                    }
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                     toBlock(rv)
                }

            }
        }
        else {
            toBlock([UIImage]())
        }
        
    }
    
}

