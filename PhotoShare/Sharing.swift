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
    
    func SendToFB(image : [UIImage?], message: [String]?, completionHandler: (result: Bool) -> ()) {
        
        if image[0] != nil {
            
            if accountFB != nil {
            
            var parameters = [String : AnyObject]()
            
            parameters["access_token"] = accountFB!.credential.oauthToken
            parameters["message"] = message!
            
            let feedURL = NSURL(string: "https://graph.facebook.com/me/photos")
            
            let postRequest = SLRequest(forServiceType: SLServiceTypeFacebook, requestMethod: SLRequestMethod.POST, URL: feedURL, parameters: parameters)
                
            postRequest.addMultipartData(UIImagePNGRepresentation(image[0]!), withName: "source", type: "multipart/form-data", filename: "photo.png")
            
            postRequest.performRequestWithHandler({ (data : NSData!, response : NSHTTPURLResponse!, error : NSError!) -> Void in
                
                print("response data: %i, url response: %@, error: %@", data.length, response, error);

                if error == nil {
                    print("Facebook response : \(response.statusCode)")
                    completionHandler(result: true)
                } else {
                    print("ERROR: \(error)")
                }
            })

            } else {
                
                print("ERROR: Account not set up")
                completionHandler(result: false)
            }
        
        } else {
            print("ERROR: image does not exist")
        }
        
    }
    
    func SendTweet(image : UIImage?, message : [String]?, completionHandler : (result: Bool) -> ()) {
        
        if image != nil {
            
            if accountTwitter != nil {
                
                let requestURL = NSURL(string: "https://api.twitter.com/1.1/statuses/update_with_media.json")
                
                let message = ["status" : message!]
                
                let postrequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: SLRequestMethod.POST, URL: requestURL!, parameters: message)
                
                postrequest.account = accountTwitter
                
                let data = UIImagePNGRepresentation(image!)

                postrequest.addMultipartData(data, withName: "media", type: "multipart/form-data", filename: "photo.png")
                
                postrequest.performRequestWithHandler({ (data : NSData!, response : NSHTTPURLResponse!, error : NSError!) -> Void in
                    
                    if error == nil {
                        print("Twitter response : \(response.statusCode)")
                        completionHandler(result: true)
                    }

                    print("ERROR: \(error)")
                })
            }
            else {
                print("ERROR: Twitter not setup")
                
                completionHandler(result: false)
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