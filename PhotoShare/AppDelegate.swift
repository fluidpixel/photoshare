//
//  AppDelegate.swift
//  PhotoShare
//
//  Created by Lauren Brown on 22/07/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import UIKit
import WatchConnectivity


struct Classes {
    static let shareClass = Sharing()
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {

    var window: UIWindow?
    var session = WCSession.defaultSession()

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
        
        let date = NSDateFormatter().dateFromString(stringDate)
        
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
            
            print("this has triggered, why?")
//            PhotoManager.sharedInstance.loadPhotos()
        }
        
        
    }
    
    func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        
        print(error?.localizedDescription)
        
    }
    
    @available(iOS 9.0, *) func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        
        //do your handle stuff here
        print("Received message to share data via X")
        
        var sentImage : UIImage?
        
        for (date, url) in PhotoManager.sharedInstance.fullSizeArray {
            
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

}

