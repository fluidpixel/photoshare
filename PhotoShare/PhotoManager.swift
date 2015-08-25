//
//  Photos.swift
//  PhotoShare
//
//  Created by Stuart Varrall on 18/08/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import Foundation
import Photos

class PhotoManager {
    
    static let sharedInstance = PhotoManager()
    
    var images : NSMutableArray!
    var sharedImages = [ String : NSData]()
    var urlArray = [NSDate : NSURL]()
    var fullSizeArray = [NSDate : NSURL]()
    
    func loadPhotos(handler: (images: NSMutableArray) -> ()) {
        images = NSMutableArray()
        fetchPhotoFromGallery(0, completionHandler: { (result) -> () in
            if result > 0 {
                if self.images.count > 0 {
                    handler(images: self.images)
                }
                
                for var i : Int = 0; i < result; i++ {
                    
                    let data : NSData = NSKeyedArchiver.archivedDataWithRootObject(self.images[i])
                    
                    self.sharedImages["\(i)"] = data
                }
            }
        })
    }
    
    func fetchPhotoFromGallery(index : Int, completionHandler: (result: Int) -> ()) {
        
        let imgManager = PHImageManager.defaultManager()
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.synchronous = true
        requestOptions.networkAccessAllowed = true
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.FastFormat
        
        let fetchOptions = PHFetchOptions()
        
        fetchOptions.fetchLimit = 25
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: fetchOptions)
        
        var url = NSURL()
        
        var creationDate: NSDate?
        
        if fetchResult.count > 0 {
            
            let size = CGSizeMake(320, 640)
            
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), { () -> Void in
                
                imgManager.requestImageForAsset((fetchResult.objectAtIndex(index) as! PHAsset), targetSize: size, contentMode: PHImageContentMode.AspectFill, options: requestOptions, resultHandler: { (image: UIImage?, result : [NSObject : AnyObject]?)  in
                    
                    let editingOptions = PHContentEditingInputRequestOptions()
                    
                    editingOptions.networkAccessAllowed = true
                    
                    _ = fetchResult.objectAtIndex(index).requestContentEditingInputWithOptions(editingOptions, completionHandler: { (contentEditingInput, dict: [NSObject : AnyObject]) -> Void in
                        if contentEditingInput != nil {
                            url = contentEditingInput!.fullSizeImageURL!
                            
                            let arrayURL = "\(url)".characters.split{$0 == "/"}.map{String($0)}
                            
                            let fileName = "\(arrayURL.last!)"
                            
                            //get display size image and save that for loading
                            let displayImage = contentEditingInput?.displaySizeImage
                            
                            //save that image in the documents
                            
                            var url2 : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
                            
                            url2 = url2.stringByAppendingPathComponent(fileName)
                            
                            UIImageJPEGRepresentation(displayImage!, 0.5)?.writeToFile(url2 as String, atomically: true)
                            
                            let urlStringConversion = NSURL(fileURLWithPath: url2 as String)
                            
                            creationDate = contentEditingInput?.creationDate
                            
                            if creationDate == nil {
                                creationDate = NSDate()
                            }
                            
                            if self.urlArray[creationDate!] == nil {
                                self.urlArray[creationDate!] = urlStringConversion
                                self.fullSizeArray[creationDate!] = url
                            }
                            
                            print(url)
                        }
                    })
                    
                    var dateToCheck : NSDate?  = NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")?.objectForKey(newestUpdateKey) as? NSDate
                    
                    if dateToCheck == nil {
                        dateToCheck = NSDate.distantPast()
                    }
                    
                    // if dateToCheck!.earlierDate(creationDate!) == dateToCheck {
                    if let fetchedImage = image {
                        self.images.addObject(fetchedImage)
                        //}
                    }
                    
                    if index + 1 < fetchResult.count {
                        self.fetchPhotoFromGallery(index + 1, completionHandler: { (result) -> () in
                            if result > 0 {
                                completionHandler(result: result)
                            }
                        }) } else {
                        
                        print("done loading images")
                        NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")?.setObject(NSDate(), forKey: newestUpdateKey)
                        completionHandler(result: index)
                    }
                })
                
            })
            
            
        }
    }
}