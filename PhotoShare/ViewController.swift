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
import WatchConnectivity

@available(iOS 9.0, *)
class ViewController: UIViewController, UINavigationControllerDelegate, WCSessionDelegate {
    
    @IBOutlet weak var myImage: UIImageView!
    @IBOutlet weak var galleryButton: UIButton!
    
    var sharedImages = [ String : NSData]()
    
    var FBAccount: ACAccount!
    var TwitterAccount: ACAccount!
    
    var urlArray = [NSDate : NSURL]()
    var fullSizeArray = [NSDate : NSURL]()
    
    var images : NSMutableArray!
    var currentImageCount : Int = 0
    
    var session = WCSession.defaultSession()
    
    let newestUpdateKey = "lastUpdateRecorded"
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        startup()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        startup()
    }
    
    func startup() {
        
        session.delegate = self
        session.activateSession()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadPhotos()
        
            if WCSession.isSupported() {
                
                //if ever sending messages to app unprompted use this section

            }


        let swipeRight = UISwipeGestureRecognizer(target: self, action: "ActionOnSwipe:")
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: "ActionOnSwipe:")
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(swipeLeft)
        // Do any additional setup after loading the view, typically from a nib.
        
        //add long press gesture recogniser as well
        let longPress = UILongPressGestureRecognizer(target: self, action: "ActionOnLongPress:")
        self.view.addGestureRecognizer(longPress)
        
        let account = ACAccountStore()
        
        //link account to Facebook
        
        let accountType = account.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook)
        
        //be sure to move fb id to defaults
        
        let postingOptions = [ACFacebookAppIdKey: "783869441734363", ACFacebookPermissionsKey: ["email"], ACFacebookAudienceKey: ACFacebookAudienceFriends]
        
        account.requestAccessToAccountsWithType(accountType, options: postingOptions as [NSObject : AnyObject]) { (success : ObjCBool, error : NSError!) -> Void in
            
            if success {
                let options = [ACFacebookAppIdKey: "783869441734363", ACFacebookPermissionsKey: ["publish_actions"], ACFacebookAudienceKey: ACFacebookAudienceFriends]
                account.requestAccessToAccountsWithType(accountType, options: options as [NSObject : AnyObject], completion: { (success: ObjCBool, error: NSError!) -> Void in
                    
                    if success {
                        let arrayOfAccounts = account.accountsWithAccountType(accountType)
                        
                        if arrayOfAccounts.count > 0 {
                            self.FBAccount = arrayOfAccounts.last as! ACAccount
                            
                             Classes.shareClass.setUpAccounts(self.FBAccount, accountTwit: self.TwitterAccount)
                            print(self.FBAccount.credential)
                            
                        }
                    } else {
                        print("Access denied - \(error.localizedDescription)")
                    }
                })
            } else {
                print("Access denied - \(error.localizedDescription)")
            }
        }
        
        let anotherAcccountType = account.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        
        account.requestAccessToAccountsWithType(anotherAcccountType, options: nil) { (success : ObjCBool, error : NSError!) -> Void in
            
            if success {
                let arrayOfAccountsTwitter = account.accountsWithAccountType(anotherAcccountType)
                
                if arrayOfAccountsTwitter.count > 0 {
                    
                    self.TwitterAccount = arrayOfAccountsTwitter.last as! ACAccount
                    Classes.shareClass.setUpAccounts(self.FBAccount, accountTwit: self.TwitterAccount)
                }
            }
            
        }
        
    }
    
    func loadPhotos() {
        images = NSMutableArray()
        fetchPhotoFromGallery(0, completionHandler: { (result) -> () in
            if result > 0 {
                if self.images.count > 0 {
                    self.myImage.image = self.images[self.currentImageCount] as? UIImage
                    self.myImage.reloadInputViews()
                }
                
                
                for var i : Int = 0; i < result; i++ {
                    
                    let data : NSData = NSKeyedArchiver.archivedDataWithRootObject(self.images[i])
                    
                    self.sharedImages["\(i)"] = data
                }
            }
        })
    }
    
    @available(iOS 9.0, *) func session(session: WCSession, didReceiveMessageData messageData: NSData, replyHandler: (NSData) -> Void) {
        
        print("Message received from watch \(messageData)")
        
        let stringDate : String = NSString(data: messageData, encoding: NSUTF8StringEncoding)! as String
        
        let date = NSDateFormatter().dateFromString(stringDate)
        
        let lastKnownUpdate : NSDate = NSUserDefaults.standardUserDefaults().objectForKey(newestUpdateKey) as! NSDate
        
        if lastKnownUpdate.earlierDate(date!) == date! {
            
            //transfer all files that are later than that date
            for (key, _) in urlArray {
                
                if key.laterDate(date!) == key {
                    
                    let metadata = ["creationDate" : key]
                    
                    _ = session.transferFile(urlArray[key]!, metadata: metadata)
                }
                
                
            }
        } else { //this should not trigger really
            
            loadPhotos()
        }


    }
    
    func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        
        print(error?.localizedDescription)
        
    }
    
    @available(iOS 9.0, *) func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        
        //do your handle stuff here
        print("Received message to share data via X")
        
        var sentImage : UIImage?
        
        for (date, url) in fullSizeArray {
            
            if date == userInfo["ID"] as! NSDate {
                if let data = NSData(contentsOfURL: url) {
                    sentImage = UIImage(data: data)
                }
                
            }
        }
        
        switch(userInfo["Media"] as! String) {
        case "Facebook":
            Classes.shareClass.SendToFB(sentImage)
            break
        case "Twitter":
            Classes.shareClass.SendTweet(sentImage)
            break
        default:
            print("media is not twitter or facebook")
            break
        }
        
    }
    
    @IBAction func ShareWithFB(sender: UIButton) {
        
        Classes.shareClass.SendToFB(myImage.image!)
        
    }
    
    
    @IBAction func ShareWithTwitter(sender: UIButton) {
        
       Classes.shareClass.SendTweet(myImage.image!)
    }
    
    
   
    
    @IBAction func ActionOnSwipe(sender: UISwipeGestureRecognizer) {
        //change photos on swipe left/right
        
        switch sender.direction {
            
        case UISwipeGestureRecognizerDirection.Left:
            
            if currentImageCount + 1 < images.count {
                currentImageCount = currentImageCount + 1
                myImage.image = images[currentImageCount] as? UIImage
            }
            
            print("Swipe Right")
        case UISwipeGestureRecognizerDirection.Right:
            
            if currentImageCount > 0 {
                currentImageCount = currentImageCount - 1
                myImage.image = images[currentImageCount] as? UIImage
                
            }
            print("Swipe left")
        default:
            break
        }
    }
    
    @IBAction func ActionOnLongPress(sender: UILongPressGestureRecognizer) {
        
        print("Long press activated")
        
        
    }
    
    func fetchPhotoFromGallery(index : Int, completionHandler: (result: Int) -> ()) {
        
        let imgManager = PHImageManager.defaultManager()
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.synchronous = true
        requestOptions.networkAccessAllowed = true
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = 25
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: fetchOptions)
        
        var url = NSURL()
        
        var creationDate: NSDate?
 
            if fetchResult.count > 0 {
                imgManager.requestImageForAsset((fetchResult.objectAtIndex(index) as! PHAsset), targetSize: self.myImage.frame.size, contentMode: PHImageContentMode.AspectFill, options: requestOptions, resultHandler: { (image: UIImage?, result : [NSObject : AnyObject]?)  in

                    _ = fetchResult.objectAtIndex(index).requestContentEditingInputWithOptions(nil, completionHandler: { (contentEditingInput, dict: [NSObject : AnyObject]) -> Void in
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
                        
                        })
                    
                    var dateToCheck : NSDate?  = NSUserDefaults.standardUserDefaults().objectForKey(self.newestUpdateKey) as? NSDate
                    
                    if dateToCheck == nil {
                        dateToCheck = NSDate.distantPast()
                    }
                    
                   // if dateToCheck!.earlierDate(creationDate!) == dateToCheck {
                    self.images.addObject(image!)
                    //}
                    
                    if index + 1 < fetchResult.count {
                        self.fetchPhotoFromGallery(index + 1, completionHandler: { (result) -> () in
                            
                            if result > 0 {
                                completionHandler(result: result)
                            }
                            
                        })
                    } else {
                        
                        print("done loading images")
                        NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: self.newestUpdateKey)
                        completionHandler(result: index)
                    }
                })
            }
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }



}

