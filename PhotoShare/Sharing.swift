//
//  Sharing.swift
//  PhotoShare
//
//  Created by Lauren Brown on 03/08/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import Foundation
import Social
import Accounts

 let newestUpdateKey = "lastUpdateRecorded"

class Sharing {
    
    var accountFB: ACAccount?
    var accountTwitter: ACAccount?
    
    func setUpAccounts(accountFB: ACAccount?, accountTwit : ACAccount?) {
        
        self.accountFB = accountFB
        self.accountTwitter = accountTwit
    }
    
    

  //class for adding share and send functionality
    
    func SendToFB(image : UIImage?) {
        
        if image != nil {
            
            if accountFB != nil {
            
            var parameters = [String : AnyObject]()
            
            parameters["access_token"] = accountFB!.credential.oauthToken
            
            let feedURL = NSURL(string: "https://graph.facebook.com/me/photos")
            
            let postRequest = SLRequest(forServiceType: SLServiceTypeFacebook, requestMethod: SLRequestMethod.POST, URL: feedURL, parameters: parameters)
                
            postRequest.addMultipartData(UIImagePNGRepresentation(image!), withName: "source", type: "multipart/form-data", filename: "photo.png")
            
            postRequest.performRequestWithHandler({ (data : NSData!, response : NSHTTPURLResponse!, error : NSError!) -> Void in
                
                
                print("response data: %i, url response: %@, error: %@", data.length, response, error);

                
                if error == nil {
                    print("Facebook response : \(response.statusCode)")
                } else {
                    print("ERROR: \(error)")
                }
            })
            

            } else {
                print("ERROR: Account not set up")
            }
        
        } else {
            print("ERROR: image does not exist")
        }
        
    }
    
    func SendTweet(image : UIImage?) {
        
        if image != nil {
            
            if accountTwitter != nil {
                
                let requestURL = NSURL(string: "https://api.twitter.com/1.1/statuses/update_with_media.json")
                
                let postrequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: SLRequestMethod.POST, URL: requestURL!, parameters: nil) //put photo here
                
                postrequest.account = accountTwitter
                
                let data = UIImagePNGRepresentation(image!)
                
                postrequest.addMultipartData(data, withName: "media", type: "multipart/form-data", filename: "photo.png") //add capability to name image
                
                postrequest.performRequestWithHandler({ (data : NSData!, response : NSHTTPURLResponse!, error : NSError!) -> Void in
                    
                    print("Twitter response : \(response.statusCode)")
                    
                    print("ERROR: \(error)")
                })
                
            }
            else {
                print("ERROR: Twitter not supported")
            }
        } else {
            print("ERROR: image does not exist")
        }
        
    }
    
    func ShareWithText(imageNo: Int) {
        
    }
    
    func ShareWithEmail(imageNo: Int) {
        
    }
}