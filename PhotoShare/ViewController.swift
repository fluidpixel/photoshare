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
class ViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var myImage: UIImageView!
    @IBOutlet weak var galleryButton: UIButton!
    
    var FBAccount: ACAccount!
    var TwitterAccount: ACAccount!
    var currentImageCount : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PhotoManager.sharedInstance.loadPhotos { (images) -> () in
            self.myImage.image = images[self.currentImageCount] as? UIImage
            self.myImage.reloadInputViews()
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
    
    
    
    @IBAction func ShareWithFB(sender: UIButton) {
        
        Classes.shareClass.SendToFB([myImage.image!]) { (result) -> () in
            if result == true {
                
                print("INFO: Photo shared - Facebook")
                
            } else if result == false {
                self.showLoginAlert("Facebook")
            }
        } 
        
    }
    
    
    @IBAction func ShareWithTwitter(sender: UIButton) {
        
        Classes.shareClass.SendTweet(myImage.image!) { result in
            
            if result == true {
                
                 print("INFO: Photo shared - Twitter")
            } else if result == false {
                
                self.showLoginAlert("Twitter")
            }
        }
    }
    
    
   
    
    @IBAction func ActionOnSwipe(sender: UISwipeGestureRecognizer) {
        //change photos on swipe left/right
        
        switch sender.direction {
            
        case UISwipeGestureRecognizerDirection.Left:
            
            if currentImageCount + 1 < PhotoManager.sharedInstance.images.count {
                currentImageCount = currentImageCount + 1
                myImage.image = PhotoManager.sharedInstance.images[currentImageCount] as? UIImage
            }
            
            print("Swipe Right")
        case UISwipeGestureRecognizerDirection.Right:
            
            if currentImageCount > 0 {
                currentImageCount = currentImageCount - 1
                myImage.image = PhotoManager.sharedInstance.images[currentImageCount] as? UIImage
                
            }
            print("Swipe left")
        default:
            break
        }
    }
    
    @IBAction func ActionOnLongPress(sender: UILongPressGestureRecognizer) {
        
        print("Long press activated")
        
        
    }
    

}

