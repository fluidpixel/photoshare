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
        
        let defaults = NSUserDefaults.standardUserDefaults()
        
        var dateLastModified : NSDate? = defaults.objectForKey(lastUpdateKey) as? NSDate
        
        if dateLastModified == nil {
            dateLastModified = NSDate.distantPast()
        }
        
        if let tempStoredIDs = NSUserDefaults.standardUserDefaults().dictionaryForKey(IDsArrayKey) as? [String : NSDate] {
            
            storedIDs = tempStoredIDs
            
        }else {
            storedIDs = [String : NSDate]()
        }
        
        //load in currently stored pictures
        
        let pictureCounter = NSUserDefaults.standardUserDefaults().integerForKey(pictureCountKey)
        
        var wasImageSet = false
        
        for var i = 0; i < pictureCounter; i++ {
            
            let filename = "PhotoGallery\(i).jpg"
            var dir : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
            dir = dir.stringByAppendingPathComponent(filename)
            
            let image = UIImage(contentsOfFile: dir as String)
            
            if image != nil {
                if i == 0 {
                    WkButton.setBackgroundImage(image)
                    wasImageSet = true
                }
                
                images.append(image!)
            }
            
        }
        
        if !wasImageSet {
            WkButton.setTitle("No images found, tap to load them")
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
    
    func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        
        print("received a file at : \(file.fileURL.relativePath!)")
        
        let identifier = file.metadata
        
        let creationDate = identifier!["creationDate"] as! NSDate
        
        if let data = NSData(contentsOfURL: file.fileURL) {
            if let image = UIImage(data: data) {
                
                images.append(image)
                
                var url : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
                
                let fileName = "PhotoGallery\(NSUserDefaults.standardUserDefaults().integerForKey(pictureCountKey)).jpg"
                
                if let tempStoredIDs = NSUserDefaults.standardUserDefaults().dictionaryForKey(IDsArrayKey) as? [String : NSDate] {
                    
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
                
                let defaults = NSUserDefaults.standardUserDefaults()
                
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
                
                NSUserDefaults.standardUserDefaults().setObject(storedIDs, forKey: IDsArrayKey)
                
                
                WkButton.setBackgroundImage(storedImages[pageNumber] as? UIImage)
                WkButton.setTitle("")
            }
        }

    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        
    }
    

    @IBAction func WkButtonPressed() {
        
        if NSUserDefaults.standardUserDefaults().integerForKey(pictureCountKey) > 0 {
        
            pageNumber = (pageNumber + 1) % NSUserDefaults.standardUserDefaults().integerForKey(pictureCountKey) //fix crash here
            
            WkButton.setBackgroundImage(images[pageNumber])
        } else {
            
            var dateLastModified : NSDate? = NSUserDefaults.standardUserDefaults().objectForKey(lastUpdateKey) as? NSDate
            
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

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
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
