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

@available(iOS 9.0, *)
class ViewController: UIViewController, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var galleryButton: UIButton!
    
    @IBOutlet weak var ImageCollection: UICollectionView!

    var currentImageCount : Int = 0
    var images = [UIImage]()
    var selectedImages = [UIImage]()

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
       
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ImageCollection.delegate = self
        ImageCollection.dataSource = self
        ImageCollection.allowsMultipleSelection = true
        
        let nib = UINib(nibName: "PhotoShareReuseView", bundle: nil)
        ImageCollection.registerNib(nib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "PhotoShareReuseView")
        
        ImageCollection.reloadData()
        
        PhotoManager.sharedInstance.loadPhotos { (images) -> () in
            
            self.images = images as NSArray as! [UIImage]
            self.ImageCollection.reloadData()            
            
            }
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
        } else {
            ShareMessage("Error", message: "You haven't selected any images")
        }
        
    }
    
    @IBAction func ShareWithTwitter(sender: UIButton) {
        if selectedImages.count == 1 {
            Classes.shareClass.SendTweet(selectedImages[0], message: nil) { (result, detail) in
                
                if result == true {
                    
                    print("INFO: Photo shared - Twitter")
                    self.ShareMessage("Complete", message: detail as! String)
                } else if detail as? String == "Account"{
                    
                    self.showLoginAlert("Twitter")
                    
                }else if result == false {
                    
                    self.ShareMessage("Error", message: detail as! String)
                }
            }
        } else {
            ShareMessage("Error", message: "You can only share one image to Twitter at a time")
        }

    }
    
    //collection view methods
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

       let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ImageCell", forIndexPath: indexPath) as! ImageCollectionCell
        
        if indexPath.row < images.count {
            cell.CellImage.image = images[indexPath.row]
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        selectedImages.append(images[indexPath.row])
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ImageCollectionCell
        
        cell.layer.borderWidth = 2.0
        cell.layer.borderColor = UIColor.greenColor().CGColor
      
       
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? ImageCollectionCell {
            
            let image = cell.CellImage.image
            if selectedImages.contains(image!) {
                let index = selectedImages.indexOf(image!)
                
                selectedImages.removeAtIndex(index!)
            }
            
            cell.layer.borderColor = UIColor.clearColor().CGColor
        }
        
        
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
                if selectedImages.count > 0 {
                    headerView.commentLabel.text = "PhotoShare sharing \(selectedImages.count) images"
                }else {
                    headerView.commentLabel.text = "PhotoShare"
                }
                
                
                return headerView
            }
            
        default:
            break
            
        }
        return UICollectionReusableView()
    }
    
    

}

