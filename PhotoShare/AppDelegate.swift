//
//  AppDelegate.swift
//  PhotoShare
//
//  Created by Lauren Brown on 22/07/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import UIKit
import WatchConnectivity
import Social
import Accounts

struct Classes {
    static let shareClass = Sharing()
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {

    var window: UIWindow?
    var session = WCSession.defaultSession()
    var FBAccount: ACAccount!
    var TwitterAccount: ACAccount!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        print("LAUNCH")
        
        
        session.delegate = self
        session.activateSession()
        
        return true
    }



    @available(iOS 9.0, *) func session(session: WCSession, didReceiveMessageData messageData: NSData, replyHandler: (NSData) -> Void) {
        
        print("Message received from watch \(messageData)")
        
        let stringDate : String = NSString(data: messageData, encoding: NSUTF8StringEncoding)! as String
        
        let format = NSDateFormatter()
        
        format.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        let date = format.dateFromString(stringDate)
        
        let lastKnownUpdate : NSDate = NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")?.objectForKey(newestUpdateKey) as! NSDate
        
        if lastKnownUpdate.earlierDate(date!) == date! {
            
            //transfer all files that are later than that date
            for (key, _) in PhotoManager.sharedInstance.urlArray {
                
                if key.laterDate(date!) == key {
                    
                    let metadata = ["creationDate" : key]
                    
                    _ = session.transferFile(PhotoManager.sharedInstance.urlArray[key]!, metadata: metadata)
                }
                
                
            }
        } else { //this should not trigger really
            
            print("The last update date for the watch is sooner than the phone, something has gone really wrong here")
//            PhotoManager.sharedInstance.loadPhotos()
        }
        
        
    }
    
    func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        
        print(error?.localizedDescription)
        
        //need to handle this through an alert of some kind
        
        
        
    }
    
    @available(iOS 9.0, *) func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        
        //do your handle stuff here
        let media = userInfo["Media"] as! String
        
        let message = userInfo["Message"] as! [String]
        
        var contact = userInfo["Contact"] as! [String : String]?
        if contact == nil {
            contact = ["Error" : "No Data"]
        } else {
            var temp : String = ""
            for text in message{
                temp = "\(temp) \(text)"
                
            }
            contact!["Message"] = temp
        }
        
        print("Received message to share data via \(media)")
        
        let array = userInfo["ID"] as! [NSDate]
        var imageArray = [UIImage]()
        var urlArray = [NSURL?]()
        
        
        if media == "Twitter" {
            for (date, url) in PhotoManager.sharedInstance.urlArray {
                
                for all in array {
                    
                    if date == all {
                        if let data = NSData(contentsOfURL: url) {
                            imageArray.append(UIImage(data: data)!)
                            
                        }
                        
                    }
                }
                
                
            }
        }else {
            for (date, url) in PhotoManager.sharedInstance.fullSizeArray {
                
                for all in array {
                    
                    if date == all {
                        if let data = NSData(contentsOfURL: url) {
                            imageArray.append(UIImage(data: data)!)
                            urlArray.append(url)
                        }
                        
                    }
                }
            }
        }

        //change this to work with
        
        switch(media) {
        case "Facebook":
            Classes.shareClass.SendToFB(imageArray, message: message) { (result, details )in
                
                if result == true {
                    
                    print("Success! Sent from watch")
                    _ = session.transferUserInfo(["Result": "Success"])
                } else if result == false {
                    print("User not logged in")
                    _ = session.transferUserInfo(["Result": "Fail", "detail" : details!])
                }
                
            }
            break
        case "Twitter":
            Classes.shareClass.SendTweet(imageArray[0], message: message) { (result, detail) in
            
                if result == true {
                    
                    print("Success! Sent from watch")
                    _ = session.transferUserInfo(["Result": "Success"])
                } else if result == false {
                    print("User not logged in")
                    _ = session.transferUserInfo(["Result": "Fail", "detail" : detail!])
                }
            }
            break
            
        case "Email":
            print("Send Email triggered")
            
            
            
            Classes.shareClass.ShareWithEmail("filename", images: imageArray, sendingData: contact!)
            break
        case "Text":
            print("Send Text triggered")
            break
        default:
            print("media is not twitter or facebook")
            break
        }
        
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        
        let account = ACAccountStore()
        
        //link account to Facebook
        
        let accountType = account.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook)
        
        //be sure to move fb id to defaults
        
        let postingOptions = [ACFacebookAppIdKey: "783869441734363", ACFacebookPermissionsKey: ["email"], ACFacebookAudienceKey: ACFacebookAudienceFriends]
        
        account.requestAccessToAccountsWithType(accountType, options: postingOptions as [NSObject : AnyObject]) { (success : Bool, error : NSError!) -> Void in
            
            if success {
                let options = [ACFacebookAppIdKey: "783869441734363", ACFacebookPermissionsKey: ["publish_actions"], ACFacebookAudienceKey: ACFacebookAudienceFriends]
                account.requestAccessToAccountsWithType(accountType, options: options as [NSObject : AnyObject], completion: { (success: Bool, error: NSError!) -> Void in
                    
                    if success {
                        let arrayOfAccounts = account.accountsWithAccountType(accountType)
                        
                        if arrayOfAccounts.count > 0 {
                            self.FBAccount = arrayOfAccounts.last as! ACAccount
                            
                            Classes.shareClass.setUpAccounts(self.FBAccount, accountTwit: self.TwitterAccount)
                            print(self.FBAccount.credential)
                            
                            //grab user's email address
                            let request = SLRequest(forServiceType: SLServiceTypeFacebook, requestMethod: SLRequestMethod.GET, URL: NSURL(string: "https://graph.facebook.com/me"), parameters: ["fields" : "email"])
                            //trying some stuff
                            
                            
                            request.account = self.FBAccount
                            
                            request.performRequestWithHandler({ (data: NSData!, response: NSHTTPURLResponse!, error: NSError!) -> Void in
                                
                                if error == nil && (response as NSHTTPURLResponse).statusCode == 200 {
                                    do {
                                        let userData : NSDictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                                        
                                        if userData["email"] != nil {
                                            let email = userData["email"]
                                            print(email)
                                            NSUserDefaults.standardUserDefaults().setValue(email, forKey: "UserEmail")
                                        }
                                        
                                    }catch {
                                        print(error)
                                    }
                                    
                                    
                                }
                            })
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
        
        account.requestAccessToAccountsWithType(anotherAcccountType, options: nil) { (success : Bool, error : NSError!) -> Void in
            
            if success {
                let arrayOfAccountsTwitter = account.accountsWithAccountType(anotherAcccountType)
                
                if arrayOfAccountsTwitter.count > 0 {
                    
                    self.TwitterAccount = arrayOfAccountsTwitter.last as! ACAccount
                    Classes.shareClass.setUpAccounts(self.FBAccount, accountTwit: self.TwitterAccount)
                }
            }
            
        }

        
    }

}

