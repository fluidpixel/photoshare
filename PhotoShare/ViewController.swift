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

//import FBSDKCoreKit
//import FBSDKLoginKit

struct Observer {
    static var MessageReceived = "MessageReceived"
    static var PopoverDismissed = "Popover Dismissed"
    static var Message : [String?] = [nil, nil]
}



@available(iOS 9.0, *)
class ViewController: UIViewController, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var galleryButton: UIButton!
    
    @IBOutlet weak var ImageCollection: UICollectionView!

    @IBOutlet weak var ClearAllButton: UIButton!
    @IBOutlet var twitterButton: UIButton!
    @IBOutlet var facebookButton: UIButton!
    @IBOutlet weak var sharingLabel: UILabel!
    
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
    
        self.twitterButton.enabled = false
        self.facebookButton.enabled = false
        
        self.ClearAllButton.enabled = false
        
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "MessageReceived", name: Observer.MessageReceived, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "popoverDismissed", name: Observer.PopoverDismissed, object: nil)
    }
    
    
    
    //MARK: Button/Alert Actions
    
    func MessageReceived() {
        sharingLabel.hidden = true
        ShareMessage(Observer.Message[0]!, message: Observer.Message[1])
    }
    
    func popoverDismissed() {
        sharingLabel.hidden = true
    }
    
    func showLoginAlert(identifier : String){
        
        print("User is trying to share via \(identifier) when they are not logged in")
        
        let alert = UIAlertController(title: "Login Error", message: "You are trying to share with \(identifier) without logging in.\nPlease login to \(identifier) through the iOS Settings Page", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "Login", style: UIAlertActionStyle.Default, handler: { ( _ : UIAlertAction) -> Void in
            
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            
            alert.dismissViewControllerAnimated(true, completion: { () -> Void in
                
            })
        }))
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
            alert.dismissViewControllerAnimated(true, completion: { () -> Void in
                print("User chose not to login")
            })
        }))
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func ShareMessage(type : String, message : String?) {

        let alert = UIAlertController(title: "Share \(type)", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            alert.dismissViewControllerAnimated(true, completion: { () -> Void in
                print("User chose not to login")
            })
        }))
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func ShareWithFB(sender: UIButton) {
        
        Classes.shareClass.loginToFB({ (success, error) -> Void in
            if !success {
                if  error?.code == 6 {
                    dispatch_async(dispatch_get_main_queue()) { () -> Void in
                        self.showLoginAlert("Facebook")
                    }
                } else {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.ShareMessage("Facebook", message: "PhotoShare doesn't have access to post to Facebook. Please check Settings->Facebook and toggle the PhotoShare access to your account")
                        })
                }
            } else {
                if SLComposeViewController.isAvailableForServiceType(SLServiceTypeFacebook) {
                    let selectionCount = self.ImageCollection.indexPathsForSelectedItems()?.count ?? 0
                    if selectionCount > 0 {
                        dispatch_async(dispatch_get_main_queue()) { () -> Void in
                            self.sharingLabel.hidden = false
                            self.performSegueWithIdentifier("message", sender: self)
                        }
                    }
                }
            }
        })
    }
    
    @IBAction func ShareWithTwitter(sender: UIButton) {
        
        Classes.shareClass.loginToTwitter({ (success, error) -> Void in
            if !success && error?.code == 6 {
                self.showLoginAlert("Twitter")
            } else {
                if SLComposeViewController.isAvailableForServiceType(SLServiceTypeTwitter) {
                    dispatch_async(dispatch_get_main_queue()) { () -> Void in
                        self.performSegueWithIdentifier("messageTwitter", sender: self)
                        self.sharingLabel.hidden = false
                    }
                }
            }
        })
                
    }
    
    func ClearAllSelections() {
        
        for indexPath : NSIndexPath in ImageCollection.indexPathsForSelectedItems()! {
            
            ImageCollection.deselectItemAtIndexPath(indexPath, animated: false)
        }
        setCollectionViewHeader()
        twitterButton.enabled = false
        facebookButton.enabled = false
        ClearAllButton.enabled = false
    }
    
    @IBAction func OnClearAll(sender: UIButton) {
        ClearAllSelections()
    }
    
    
    //MARK: collection view methods
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ImageCell", forIndexPath: indexPath) as! ImageCollectionCell
        
        if indexPath.row < assets?.count {
            if let asset = assets?[indexPath.row] as? PHAsset {
                cell.localIdentifier = asset.localIdentifier
                
                cell.CellImage.image = nil
                cell.favourite.hidden = !asset.favorite
                
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
    
    //MARK: collection view layout
    
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
        
        switch selectionCount {
        case 0:
            self.collectionHeader?.commentLabel.text = "PhotoShare"
        case 1:
            self.collectionHeader?.commentLabel.text = "PhotoShare: sharing \(selectionCount) image"
        default:
            self.collectionHeader?.commentLabel.text = "PhotoShare: sharing \(selectionCount) images"
        }
        
        self.twitterButton.enabled = (selectionCount == 1)
        self.facebookButton.enabled = selectionCount > 0
        self.ClearAllButton.enabled = selectionCount > 0
    }
    
    var selectedItems:[String] {
        get {
            if let selection = self.ImageCollection.indexPathsForSelectedItems() where selection.count > 0,
                let assets = self.assets {
                    return selection.map { return assets[$0.row].localIdentifier }
            }
            else {
                return []
            }
        }
        set {
            if let assets = self.assets {
                for index in 0..<assets.count {
                    if let asset = assets[index] as? PHAsset where newValue.indexOf(asset.localIdentifier) != nil {
                        self.ImageCollection.selectItemAtIndexPath( NSIndexPath(forRow: index, inSection: 0), animated: false, scrollPosition: .None)
                    }
                    else {
                        self.ImageCollection.deselectItemAtIndexPath( NSIndexPath(forRow: index, inSection: 0), animated: false)
                    }
                }
            }
        }
    }
    
    //MARK: popup delegate
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        
        if segue.identifier == "message" {
            let vc = segue.destinationViewController as! MessagePopoverController
            vc.modalPresentationStyle = UIModalPresentationStyle.Popover
//            vc.popoverPresentationController!.delegate = self
            vc.presentationController?.delegate = self
            
            
            retrieveImageArray({ (images: [UIImage]) -> Void in
                vc.Image.image = images[0]
                vc.imagesToShare = images
                vc.shareType = SLServiceTypeFacebook
                if images.count > 1 {
                    vc.Image3.image = images[1]
                }
            })
        } else if segue.identifier == "messageTwitter" {
            let vc = segue.destinationViewController as! MessagePopoverController
            vc.modalPresentationStyle = UIModalPresentationStyle.Popover
            vc.popoverPresentationController!.delegate = self
            vc.shareType = SLServiceTypeTwitter
            
            if let indexPaths = self.ImageCollection.indexPathsForSelectedItems(),
                let asset = self.assets?.objectAtIndex(indexPaths[0].row) as? PHAsset {


                    let options = PHImageRequestOptions()
                    //options.synchronous = true
                    options.deliveryMode = .HighQualityFormat
                    //options.resizeMode = .None

                    let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)

                    PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: targetSize, contentMode: .AspectFit, options: options) {
                        (img:UIImage?, info:[NSObject : AnyObject]?) -> Void in
                        if let image = img {
                            dispatch_async(dispatch_get_main_queue()) {
                                
                                vc.Image.image = image
                                vc.imagesToShare = [image]
                            }
                        }
                    }
            }
        }
        
    }
    
    // MARK: PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(changeInstance: PHChange) {
        // TODO:
        if let assets = self.assets,
            let changes = changeInstance.changeDetailsForFetchResult(assets) {
                
                dispatch_async(dispatch_get_main_queue()) {
                    
                    if !changes.hasIncrementalChanges || changes.hasMoves || (changes.insertedIndexes != nil) || (changes.removedIndexes != nil) {
                        // Full refesh - need to preserve the user's selection
                        let selectedItems = self.selectedItems
                        
                        self.assets = changes.fetchResultAfterChanges
                        self.ImageCollection.reloadData()
                        
                        self.selectedItems = selectedItems
                        
                    }
                    else if let changedIndexes = changes.changedIndexes {
                        // no changes in order etc so only reload changed images
                        
                        self.assets = changes.fetchResultAfterChanges
                        
                        let indexPaths = self.ImageCollection.indexPathsForVisibleItems().filter { changedIndexes.containsIndex($0.row) }
                        print("Changing Index Paths: \(indexPaths.map {$0.row})")
                        self.ImageCollection.reloadItemsAtIndexPaths(indexPaths)
                    }
                }
        }
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

