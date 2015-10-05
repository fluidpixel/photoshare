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
import Photos

import WatchKit

struct Classes {
    static let shareClass = Sharing()
}

let SharedApp = UIApplication.sharedApplication().delegate as! AppDelegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate, PHPhotoLibraryChangeObserver {
    
    var window: UIWindow?
    var session = WCSession.defaultSession()
    var FBAccount: ACAccount!
    var TwitterAccount: ACAccount!
    
    var fetchResult:PHFetchResult!
    var watchImageManager = PHImageManager.defaultManager()
    
    var activeFileTransfers = Set<WCSessionFileTransfer>()
    
    var watchImageSize = CGSize(width: 312, height: 390)
    
    // MARK: UIApplicationDelegate
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        print("LAUNCH")
        
        #if DEBUG
            // Send any uncaught exceptions as a message to the watch
            NSSetUncaughtExceptionHandler {
                (exception:NSException) -> Void in
                print("CRASH: \(exception.description)")
                print("Stack Trace: \(exception.callStackSymbols)")
                let session = WCSession.defaultSession()
                session.sendMessage(["CRASH":"\(exception.description)", "Stack Trace:": "(exception.callStackSymbols)"], replyHandler: nil, errorHandler: nil)
            }
        #endif
        
        session.delegate = self
        session.activateSession()
        
        // Initiliase Photo Library Fetch
        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = 25
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        self.fetchResult = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: fetchOptions)
        
        self.sessionReachabilityDidChange(self.session)
        
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
        
        return true
    }
    
    
    func applicationWillTerminate(application: UIApplication) {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
        NSNotificationCenter.defaultCenter().removeObserver(FBAccount)
        NSNotificationCenter.defaultCenter().removeObserver(TwitterAccount)
    }
    
    func login() {
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
                            
                            request.account = self.FBAccount
                            
                            NSNotificationCenter.defaultCenter().addObserver(self.FBAccount, selector: "accountChanged:", name: ACAccountStoreDidChangeNotification, object: nil)
                            
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
                    NSNotificationCenter.defaultCenter().addObserver(self.TwitterAccount, selector: "accountChanged:", name: ACAccountStoreDidChangeNotification, object: nil)
                }
            }
            
        }

    }
    
    @objc func accountChanged(notif : NSNotification) {
        refreshAccountTokenStatus()
    }
    
    func refreshAccountTokenStatus() {
        let account = ACAccountStore()
        //FACEBOOK
        account.renewCredentialsForAccount(FBAccount) { (result: ACAccountCredentialRenewResult, error: NSError!) -> Void in
            if (error != nil) {
                switch result {
                case ACAccountCredentialRenewResult.Renewed:
                    print("FACEBOOK: Credentials renewed")
                    break
                case ACAccountCredentialRenewResult.Rejected:
                    print("FACEBOOK: User declined permission to renew")
                    break
                case ACAccountCredentialRenewResult.Failed:
                    print("FACEBOOK: renew failed, you can try again")
                    break
                }
            } else {
                print("\(error.localizedDescription)")
            }
        }
        //TWITTER
        account.renewCredentialsForAccount(TwitterAccount) { (result: ACAccountCredentialRenewResult, error: NSError!) -> Void in
            if (error != nil) {
                switch result {
                case ACAccountCredentialRenewResult.Renewed:
                    print("TWITTER: Credentials renewed")
                    break
                case ACAccountCredentialRenewResult.Rejected:
                    print("TWITTER: User declined permission to renew")
                    break
                case ACAccountCredentialRenewResult.Failed:
                    print("TWITTER: renew failed, you can try again")
                    break
                }
            } else {
                print("\(error.localizedDescription)")
            }
        }
    }
    
    
    func applicationDidBecomeActive(application: UIApplication) { //is this ever called from the watch?
        
        login()
        
    }
    
    // MARK: WCSessionDelegate
    
    // TODO: Fix this for new Photo-Library Integration

    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        
        if FBAccount == nil || TwitterAccount == nil {
            login()
        }
        
        let media = message["Media"] as! String
        let messageReceived = message["Message"] as! [String]
        
        var contact = message["Contact"] as? [String : String]
        
        if contact == nil {
            contact = ["Error" : "No Data"]
        } else {
            var temp : String = ""
            for text in message{
                temp = "\(temp) \(text)"
                
            }
            contact!["Message"] = temp
        }
        
        let localIDs:[String] = message[kSelectedImagesLocalIdentifiers] as? [String] ?? []

        let assets = PHAsset.fetchAssetsWithLocalIdentifiers(localIDs, options: nil)
        var images:[UIImage] = []
        
        assets.enumerateObjectsUsingBlock {
            if let asset = $0.0 as? PHAsset {
                images.append(self.getHQImageForAssetSync(asset))
            }
        }
        
        switch (media) {
            
        case "Facebook":
            Classes.shareClass.SendToFB(images, message: messageReceived) {
                (result, details )in
                
                if result == true {
                    
                    print("Success! Sent from watch")
                    replyHandler(["Result": "Success"])
                    //_ = session.transferUserInfo(["Result": "Success"])
                } else if result == false {
                    print("User not logged in")
                    replyHandler(["Result": "Failed", "detail" : details!])
                    //_ = session.transferUserInfo(["Result": "Fail", "detail" : details!])
                }
                
            }
            
        case "Twitter":
            Classes.shareClass.SendTweet(images[0], message: messageReceived) {
                (result, detail) in
                
                if result == true {
                    
                    print("Success! Sent from watch")
                    replyHandler(["Result": "Success"])
                    //_ = session.transferUserInfo(["Result": "Success"])
                } else if result == false {
                    print("User not logged in")
                    replyHandler(["Result": "Failed", "detail" : detail!])
                    //_ = session.transferUserInfo(["Result": "Fail", "detail" : detail!])
                }
            }
            
        case "Email":
            print("Send Email triggered")
            
            Classes.shareClass.ShareWithEmail("filename", images: images, sendingData: contact!)
            
        case "Text":
            print("Send Text triggered")
            
        default:
            print("media is not twitter or facebook")
            print("User Info Received: \(message)")
            #if DEBUG
                session.sendMessage(["Unknown User Info Received by App":message], replyHandler: nil, errorHandler: nil)
            #endif
        }

    }
    
    func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: NSError?) {
        #if DEBUG
            if let error = error {
                session.sendMessage(["File Transfer Error": error.localizedDescription], replyHandler: nil, errorHandler: nil)
            }
        #endif
        if fileTransfer.file.metadata?[kDeleteWhenTransfered]?.boolValue ?? false {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(fileTransfer.file.fileURL)
            }
            catch {
                #if DEBUG
                    session.sendMessage(["File Removal Error": fileTransfer.file.fileURL.path ?? "(NULL)"], replyHandler: nil, errorHandler: nil)
                #endif
            }
        }
        
        self.activeFileTransfers.remove(fileTransfer)
        
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        if let _ = message[kWPRequestImageData] as? String {
            sessionReachabilityDidChange(session)
        }
        else if let localIDs = message[kWPRequestImagesForLocalIdentifiers] as? [String] {
            for localID in localIDs {
                self.sendImage(localID, session: session)
            }
        }
    }
    
    func sessionReachabilityDidChange(session: WCSession) {
        print("sessionReachabilityDidChange")
        if session.reachable {
            
            let watchSize = WKInterfaceDevice.currentDevice().screenBounds.size
            let watchScale = WKInterfaceDevice.currentDevice().screenScale
            self.watchImageSize = CGSize(width: watchScale * watchSize.width, height: watchScale * watchSize.height)
            
            self.sendAssetList(session)
            
//            self.fetchResult.enumerateObjectsUsingBlock {
//                if let asset = $0.0 as? PHAsset {
//                    self.sendImage(asset, session: session)
//                }
//            }
            
        }
        else {
            // TODO: Watch App has disconnected
            self.cancelAllImageFileTransfers()
        }
    }
    
    func sendAssetList(session: WCSession) -> [String] {
        
        var list:[String] = []
        var modified:[String:NSDate] = [:]
        
        list.reserveCapacity(self.fetchResult.count)
        for index in 0..<self.fetchResult.count {
            let asset = self.fetchResult[index]
            list.insert( asset.localIdentifier, atIndex: index )
            
            modified[asset.localIdentifier] = asset.modificationDate
            
        }
        
        if session.reachable {
            session.sendMessage([kLocalIdentifierList: list, kAssetsLastModifiedDates:modified], replyHandler: nil, errorHandler: nil)
        }
        return list
    }
    
    // cancels all file transfers for a given asset
    func cancelFileTransfers(localID:String) {
        for ft in self.activeFileTransfers {
            if let id = ft.file.metadata?[kLocalIdentifier]?.string where id == localID {
                self.activeFileTransfers.remove(ft)
                ft.cancel()
                _ = try? NSFileManager.defaultManager().removeItemAtURL(ft.file.fileURL)
            }
        }
    }
    func cancelAllImageFileTransfers() {
        for ft in self.activeFileTransfers {
            if let _ = ft.file.metadata?[kLocalIdentifier] {
                self.activeFileTransfers.remove(ft)
                ft.cancel()
                _ = try? NSFileManager.defaultManager().removeItemAtURL(ft.file.fileURL)
            }
        }
    }
    
    @objc(sendImageForLocalIdentifier:session:)
    func sendImage(localID:String, session: WCSession) {
        if let asset = PHAsset.fetchAssetsWithLocalIdentifiers([localID], options: nil).firstObject as? PHAsset {
            self.sendImage(asset, session: session)
            
        }
    }

    @objc(sendImageAsset:session:)
    func sendImage(asset:PHAsset, session: WCSession) {
        
        self.cancelFileTransfers(asset.localIdentifier)
        
        if session.reachable, let tempFile = createTemporaryFilename("JPG") {
            
            let options = PHImageRequestOptions()
            options.deliveryMode = PHImageRequestOptionsDeliveryMode.Opportunistic
            options.resizeMode = PHImageRequestOptionsResizeMode.Fast
            
            self.watchImageManager.requestImageForAsset(asset, targetSize: watchImageSize, contentMode: .AspectFill, options: options) {
                (img:UIImage?, info:[NSObject : AnyObject]?) -> Void in
                
                if session.reachable, let image = img, let imageData = UIImageJPEGRepresentation(image, 1.0) {
                    do {
                        try imageData.writeToURL(tempFile, options: .AtomicWrite)
                        
                        var metadata:[String:AnyObject] = [:] // info as? [String:AnyObject] ?? [:]
                        metadata[kLocalIdentifier] = asset.localIdentifier
                        metadata[kDeleteWhenTransfered] = true
                        metadata[kAssetModificationDate] = asset.modificationDate
                        metadata["PHImageResultIsDegradedKey"] = info?[PHImageResultIsDegradedKey]?.boolValue ?? true
                        
                        self.activeFileTransfers.insert(session.transferFile(tempFile, metadata: metadata))
                        
                    }
                    catch {
                        // Failed to create temporary file
                    }
                }
            }
            
        }
    }
    
    
    // MARK: PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(changeInstance: PHChange) {
        
        if let changes = changeInstance.changeDetailsForFetchResult(fetchResult) {
            self.fetchResult = changes.fetchResultAfterChanges
            if self.session.reachable {
                
                var assetsToSend = Set<PHObject>()
                
                if changes.hasIncrementalChanges {
                    
                    // if there are moves, insertions or deletions then send the new asset list
                    if changes.hasMoves || changes.removedObjects.count > 0 || changes.insertedObjects.count > 0 {
                        self.sendAssetList(self.session)
                    }
                    
                    assetsToSend.unionInPlace(changes.insertedObjects)
                    assetsToSend.unionInPlace(changes.changedObjects)
 
                }
                else {
                    
                    self.sendAssetList(self.session)

                    self.fetchResult.enumerateObjectsUsingBlock {
                        assetsToSend.insert($0.0 as! PHObject)
                    }
                    
                }
                
                for object in assetsToSend {
                    if let asset = object as? PHAsset {
                        self.sendImage(asset, session: self.session)
                    }
                }

            }
            
        }
        
    }
    
    // Must be run on a background thread
    func getHQImageForAssetSync(asset:PHAsset) -> UIImage {
        let options = PHImageRequestOptions()
        options.synchronous = true
        options.deliveryMode = .HighQualityFormat
        options.resizeMode = .None
        
        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        
        var rv:UIImage!
        PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: targetSize, contentMode: .AspectFit, options: options) {
            (img:UIImage?, info:[NSObject : AnyObject]?) -> Void in
            rv = img
        }
        
        return rv
    }
}

