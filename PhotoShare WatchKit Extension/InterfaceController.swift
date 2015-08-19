//
//  InterfaceController.swift
//  PhotoShare WatchKit Extension
//
//  Created by Lauren Brown on 22/07/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import ImageIO

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    @IBOutlet var imageTable: WKInterfaceTable!
    @IBOutlet weak var watchImage: WKInterfaceImage!
    @IBOutlet var WkButton: WKInterfaceButton!
    
    //stored variables
    var pageNumber = 0
    var arraySize = 0
    var storedImages = [Int : AnyObject]()
    var storedIDs : [String : NSDate]?
    var images = [UIImage]()
    var session : WCSession!
    
    
    let maxPictureCount = 250
    let pictureCountKey = "pictureCount"
    let lastUpdateKey = "DateLastModified"
    let pictureArrayKey = "photoAddresses"
    let IDsArrayKey = "StoredIDs"

    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        let defaults = NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")
        
        var dateLastModified : NSDate? = defaults?.objectForKey(lastUpdateKey) as? NSDate
        
        if dateLastModified == nil {
            dateLastModified = NSDate.distantPast()
        }
        
        if let tempStoredIDs = NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")?.dictionaryForKey(IDsArrayKey) as? [String : NSDate] {
            
            storedIDs = tempStoredIDs
            
        }else {
            storedIDs = [String : NSDate]()
        }
        
        //load in currently stored pictures
        
        let pictureCounter = NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")?.integerForKey(pictureCountKey)
        
        var wasImageSet = false
        
        for var i = 0; i < pictureCounter; i++ {
            
            let filename = "PhotoGallery\(i).jpg"
            var dir : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
            dir = dir.stringByAppendingPathComponent(filename)
            
            let image = UIImage(contentsOfFile: dir as String)
            
            if image != nil {
                if i == 0 {
                    wasImageSet = true
                }
                images.append(image!)
            }
            
        }
        
        
        if !wasImageSet {
            WkButton.setHidden(false)
            WkButton.setTitle("No images found, tap to load them")
        } else {
            WkButton.setHidden(true)
            loadTableData()
        }
        
        if (WCSession.isSupported()) {
            
            session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
            
          //  let action = WKAlertAction(title: "Okay", style: WKAlertActionStyle.Default, handler: { () -> Void in
         //       self.dismissController()
           // })
            
           // presentAlertControllerWithTitle("Waiting for images", message: "We are loading images from your phone, this may take a few seconds", preferredStyle: WKAlertControllerStyle.Alert, actions: [action])
            
            
            let requestData = NSDateFormatter().stringFromDate(dateLastModified!).dataUsingEncoding(NSUTF8StringEncoding)
            session.sendMessageData(requestData!, replyHandler: { (response: NSData) -> Void in
                
                print("response GOT")

            },
                  errorHandler: { (error: NSError) -> Void in
                    
                    print("ERROR : \(error)")
                    
            })
        }

    }
    
    func loadTableData() {
        imageTable.setNumberOfRows(images.count, withRowType: "image row")
        for (index, image) in images.enumerate() {
            if let row = imageTable.rowControllerAtIndex(index) as? ImageTableRowController {
                row.photo.setImage(image)
            }
        }
    }
    
    func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        
        print("received a file at : \(file.fileURL.relativePath!)")
        
        let identifier = file.metadata
        
        let creationDate = identifier!["creationDate"] as! NSDate
        
        if let data = NSData(contentsOfURL: file.fileURL) {
            if let image = UIImage(data: data) {
                
                images.append(image)
                
                var url : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
                
                let userdefaults = NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")
                
                let fileName = "PhotoGallery\(userdefaults!.integerForKey(pictureCountKey)).jpg"
                
                if let tempStoredIDs = userdefaults?.dictionaryForKey(IDsArrayKey) as? [String : NSDate] {
                    
                    storedIDs = tempStoredIDs
                    
                }else {
                    storedIDs = [String : NSDate]()
                }
                
                url = url.stringByAppendingPathComponent(fileName)
                
                UIImageJPEGRepresentation(image, 0.5)?.writeToFile(url as String, atomically: true)
                
                print(url)
                
                //UIImagePNGRepresentation
                
                storedImages[pageNumber] = UIImage(contentsOfFile: "\(url)")
                storedIDs!["\(pageNumber)"] = creationDate
                
                pageNumber++
                
                if let defaults = NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare") {
                
                if var arrayCurrent = defaults.arrayForKey(pictureArrayKey) {
                    
                    arrayCurrent.append(url)
                    
                    defaults.setObject(arrayCurrent, forKey: pictureArrayKey)
                    
                } else {
                    var newArray = [String]()
                    
                    newArray.append(url as String)
                    
                    defaults.setObject(newArray, forKey: pictureArrayKey)
                }
                
                var pictureCount = defaults.integerForKey(pictureCountKey)
                
                pictureCount++
                
                defaults.setValue(pictureCount, forKey: pictureCountKey)
                
                let updatedDate = NSDate()

                defaults.setObject(updatedDate, forKey: lastUpdateKey)
                defaults.setObject(storedIDs, forKey: IDsArrayKey)
                }
                
//                WkButton.setBackgroundImage(storedImages[pageNumber] as? UIImage)
//                WkButton.setTitle("")
                WkButton.setHidden(true)
                loadTableData()
            }
        }

    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        
    }
    

    @IBAction func WkButtonPressed() {
        
        if NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")?.integerForKey(pictureCountKey) > 0 {
        
            if images.count > 0 {
                pageNumber = (pageNumber + 1) % NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")!.integerForKey(pictureCountKey) //fix crash here
                
                WkButton.setHidden(true)
                loadTableData()
            }
        } else {
            
            var dateLastModified : NSDate? = NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")?.objectForKey(lastUpdateKey) as? NSDate
            
            if dateLastModified == nil {
                dateLastModified = NSDate.distantPast()
            }
            
            let requestData = NSDateFormatter().stringFromDate(dateLastModified!).dataUsingEncoding(NSUTF8StringEncoding)
            session.sendMessageData(requestData!, replyHandler: { (response: NSData) -> Void in
                
                print("response GOT")
                
                },
                errorHandler: { (error: NSError) -> Void in
                    
                    print("ERROR : \(error)")
                    
            })
            
        }
    }

    @IBAction func SendTweet() {

        SendData("Twitter")
    }
    
    
    @IBAction func ShareOnFB() {
        
        SendData("Facebook")
    }
    
    @IBAction func SendText() {
        
        SendData("Text")
    }
    
    @IBAction func SendEmail() {
        
        SendData("Email")
    }
    
    func SendData(identifier: String) {

        //dictionary - facebook id + imageno
        
        let metaData : [String : AnyObject] = ["ID" : storedIDs!["\(pageNumber)"] as! AnyObject,
                                                "Media" : identifier]
        
        
        _ = session.transferUserInfo(metaData)
        
    }

}
