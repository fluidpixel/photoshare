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
import MobileCoreServices

let newestUpdateKey = "lastUpdateRecorded"

class Sharing {
    
    var accountFB: ACAccount?
    var accountTwitter: ACAccount?
    
    func setUpAccounts(accountFB: ACAccount?, accountTwit : ACAccount?) {
        
        self.accountFB = accountFB
        self.accountTwitter = accountTwit
    }
    
    var urls: [NSURL]?

    func loginToFB (completion: (success:Bool, error: NSError?) -> Void) {
        let accountType = ACAccountStore().accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook)
        
        //be sure to move fb id to defaults
        
        let postingOptions = [ACFacebookAppIdKey: "783869441734363", ACFacebookPermissionsKey: ["email"], ACFacebookAudienceKey: ACFacebookAudienceFriends]
        
        ACAccountStore().requestAccessToAccountsWithType(accountType, options: postingOptions as [NSObject : AnyObject]) { (success : Bool, error : NSError!) -> Void in
            
            if success {
                let options = [ACFacebookAppIdKey: "783869441734363", ACFacebookPermissionsKey: ["publish_actions"], ACFacebookAudienceKey: ACFacebookAudienceFriends]
                ACAccountStore().requestAccessToAccountsWithType(accountType, options: options as [NSObject : AnyObject], completion: { (success: Bool, error: NSError!) -> Void in
                    
                    if success {
                        let arrayOfAccounts = ACAccountStore().accountsWithAccountType(accountType)
                        
                        if arrayOfAccounts.count > 0 {
                            self.accountFB = arrayOfAccounts.last as? ACAccount
                            
//                            Classes.shareClass.setUpAccounts(self.accountFB, accountTwit: self.TwitterAccount)
                            print(self.accountFB!.credential)
                            
                            //grab user's email address
                            let request = SLRequest(forServiceType: SLServiceTypeFacebook, requestMethod: SLRequestMethod.GET, URL: NSURL(string: "https://graph.facebook.com/me"), parameters: ["fields" : "email"])
                            
                            request.account = self.accountFB
                            
                            NSNotificationCenter.defaultCenter().addObserver(self, selector: "accountChanged:", name: ACAccountStoreDidChangeNotification, object: nil)
                            
                            request.performRequestWithHandler({ (data: NSData!, response: NSHTTPURLResponse!, error: NSError!) -> Void in
                                
                                if error == nil && (response as NSHTTPURLResponse).statusCode == 200 {
                                    do {
                                        let userData : NSDictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                                        
                                        if userData["email"] != nil {
                                            let email = userData["email"]
                                            print(email)
                                            NSUserDefaults.standardUserDefaults().setValue(email, forKey: "UserEmail")
                                            completion(success:true, error:error)
                                        }
                                        
                                    }catch {
                                        print(error)
                                    }
                                } else {
                                    do {
                                        let userData : NSDictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
                                        
                                        let err = NSError(domain: "facebook", code: 6, userInfo: nil)
//                                        if userData["email"] != nil {
//                                            let email = userData["email"]
//                                            print(email)
//                                            NSUserDefaults.standardUserDefaults().setValue(email, forKey: "UserEmail")
                                            completion(success:false, error:err)
//                                        }
                                        
                                    }catch {
                                        print(error)
                                    }
                                }
                            })
                        }
                    } else {
                        completion(success:false, error:error)
                        
                        print("Access denied - \(error?.localizedDescription)")
                    }
                })
            } else {
                completion(success:false, error:error)
                print("Access denied - \(error?.localizedDescription)")
            }
        }
    }
    
    func loginToTwitter(completion: (success:Bool, error: NSError?) -> Void) {
        let anotherAcccountType = ACAccountStore().accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        
        ACAccountStore().requestAccessToAccountsWithType(anotherAcccountType, options: nil) { (success : Bool, error : NSError!) -> Void in
            
            if success {
                let arrayOfAccountsTwitter = ACAccountStore().accountsWithAccountType(anotherAcccountType)
                
                if arrayOfAccountsTwitter.count > 0 {
                    
                    self.accountTwitter = arrayOfAccountsTwitter.last as? ACAccount
//                    Classes.shareClass.setUpAccounts(self.FBAccount, accountTwit: self.TwitterAccount)
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: "accountChanged:", name: ACAccountStoreDidChangeNotification, object: nil)
                    completion(success: true, error: error)
                } else {
                    completion(success: false, error: NSError(domain: "Accounts", code: 6, userInfo: nil))
                }
            } else {
                completion(success: false, error: NSError(domain: "Accounts", code: 0, userInfo: nil))
            }
            
            
        }
    }
    
    
    @objc func accountChanged(notif : NSNotification) {
        refreshAccountTokenStatus()
    }
    
    func refreshAccountTokenStatus() {
        //FACEBOOK
        
        if accountFB != nil {
            ACAccountStore().renewCredentialsForAccount(accountFB!) { (result: ACAccountCredentialRenewResult, error: NSError!) -> Void in
                if (error == nil) {
                    switch result {
                    case ACAccountCredentialRenewResult.Renewed:
                        print("FACEBOOK: Credentials renewed")
                        break
                    case ACAccountCredentialRenewResult.Rejected:
                        print("FACEBOOK: User declined permission to renew")
                        self.accountFB = nil
                        break
                    case ACAccountCredentialRenewResult.Failed:
                        print("FACEBOOK: renew failed, you can try again")
                        break
                    }
                } else {
                    print("\(error.localizedDescription)")
                }
            }
        }
        //TWITTER
        
         if accountTwitter != nil {
            ACAccountStore().renewCredentialsForAccount(accountTwitter) { (result: ACAccountCredentialRenewResult, error: NSError!) -> Void in
                if (error == nil) {
                    switch result {
                    case ACAccountCredentialRenewResult.Renewed:
                        print("TWITTER: Credentials renewed")
                        break
                    case ACAccountCredentialRenewResult.Rejected:
                        print("TWITTER: User declined permission to renew")
                        self.accountTwitter = nil
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
    }
    
  //class for adding share and send functionality
    
    func SendToFB(image : [UIImage], message: [String]?, completionHandler: (result: Bool, detail: AnyObject?) -> ()) {
        
       loginToFB { (success, error) -> Void in
        //todo change for multiple images/retrieve errors
        var photoIds = [String]()
        var counter = 0
        for var i = 0; i < image.count; i++ {
            
            if self.accountFB != nil {
                
                var parameters = [String : AnyObject]()
                
                var finalMessage = ""
                
                if message != nil {
                    for all in message! {
                        if all != PlaceholderText {
                            finalMessage += all
                        }
                    }
                }
                
                parameters["access_token"] = self.accountFB!.credential.oauthToken
                
                parameters["caption"] = finalMessage
                
                let feedURL = NSURL(string: "https://graph.facebook.com/me/photos")
                
                let postRequest = SLRequest(forServiceType: SLServiceTypeFacebook, requestMethod: SLRequestMethod.POST, URL: feedURL, parameters: parameters)
                
                postRequest.addMultipartData(UIImageJPEGRepresentation(image[i], 0.8), withName: "source", type: "multipart/form-data", filename: "photo.jpg")
                
                postRequest.performRequestWithHandler({ (data : NSData!, response : NSHTTPURLResponse!, error : NSError!) -> Void in
                    
                    if error == nil {
                        
                        print("Facebook response : \(response.statusCode)")
                        
                        if response.statusCode >= 400 && response.statusCode < 500 {
                            completionHandler(result: false, detail: "Bad request, try again")
                        } else if response.statusCode >= 500 {
                            completionHandler(result: false, detail: "Server error, Facebook is having problems")
                        }
                        
                        counter++
                        
                        do {
                            let userData = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
                            if userData == nil {
                                
                            }else {
                                if let value = userData?.valueForKey("id") as? String {
                                    photoIds.append(value)
                                }
                                print(userData!)
                            }
                        } catch {
                            print(error)
                        }
                        
                        
                        if (counter == image.count) {
                            completionHandler(result: true, detail: "All photos shared")
                            // self.sendFBMessage(["testing"], photoIds: photoIds) { (result, detail) -> () in
                            
                            //     if result == true {
                            //         completionHandler(result: true, detail: detail)
                            //     }
                            //  }
                        }
                    } else {
                        print("ERROR: \(error)")
                    }
                })
                
            } else {
                
                print("ERROR: Account not set up")
                completionHandler(result: false, detail: "Account")
            }
        }

        }
        
    }
    
    func SendTweet(image : UIImage?, message : [String]?, completionHandler : (result: Bool, details : AnyObject?) -> ()) {
        
        if image != nil {
            
            loginToTwitter({ (success, error) -> Void in
                
                if self.accountTwitter != nil {
                    let requestURL = NSURL(string: "https://api.twitter.com/1.1/statuses/update_with_media.json")
                    
                    var messageTwitter : [String : String]? = nil
                    
                    if message != nil {
                        var finalMessage : String = ""
                        
                        for all in message! {
                            finalMessage += all
                        }
                        
                        messageTwitter = ["status" : finalMessage]
                    }else {
                        messageTwitter = ["status" : "This is a test"]
                    }
                    
                    let postrequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: SLRequestMethod.POST, URL: requestURL!, parameters: messageTwitter)
                    
                    postrequest.account = self.accountTwitter
                    
                    let data = UIImageJPEGRepresentation(image!, 0.8)
                    
                    postrequest.addMultipartData(data, withName: "media", type: "multipart/form-data", filename: "photo.jpeg")
                    
                    
                    
                    postrequest.performRequestWithHandler({ (data : NSData!, response : NSHTTPURLResponse!, error : NSError!) -> Void in
                        
                        if error == nil {
                            print("Twitter response : \(response.statusCode)")
                            
                            if response.statusCode >= 400 && response.statusCode < 500 {
                                completionHandler(result: false, details: "Bad request, try again")
                            } else if response.statusCode >= 500 {
                                completionHandler(result: false, details: "Server error, Twitter is having problems")
                            }
                            
                            do {
                                let userData = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
                                if userData == nil {
                                    
                                }else {
                                    print(userData!)
                                }
                            } catch {
                                print(error)
                            }
                            
                            completionHandler(result: true, details: "Photo shared to Twitter")
                        }
                        
                        
                        print("ERROR: \(error)")
                    })
                }
                else {
                print("ERROR: Twitter not setup")
                
                completionHandler(result: false, details: "Not logged in")
            }
                })
            
        } else {
            print("ERROR: image does not exist")
        }
        
    }
    
    func ShareWithText(imageNo: Int) {
        
    }
    
    func ShareWithEmail(filename: String, images: [UIImage?], sendingData : [String : String]) {
        
        //using sendgrids web api
        
        //start with test message
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        let username = "fpTestAccount"
        let password = "fpSTUDIOS2015" // hide these - encode?
        //need filepath for image?
        
        let email = NSUserDefaults.standardUserDefaults().valueForKey("UserEmail") as? String
        
        if email == nil {
            print("ERROR : Could not find valid email for sender")
        }
        // testing data
        let sendTo = ""//"laurenevabrown28@gmail.com"
        let sendName = ""//"Lauren Brown"
        let message = "This is a test"
        
        // set sendingData
        if sendingData["Error"] != nil {
            print(sendingData["Error"])
        } else {
            //sendTo = sendingData["Address"]!
            //sendName = sendingData["Name"]!
            //message = sendingData["Message"]!
        }
        
        let URL = NSURL(string: "https://api.sendgrid.com/api/mail.send.json")
        
//        let URLParams = [
//            "api_user": username,
//            "api_key": password,
//            "to": sendTo,
//            "toname": sendName,
//            "subject": "Testing",
//            "text": message,
//            "from": email!,
//            "files[\(filename)]" :(filename)
//        ]
//        
//        URL = self.NSURLByAppendingQueryParameters(URL, queryParameters: URLParams)
        
        let boundary = generateBoundaryString()
        
        let request = NSMutableURLRequest(URL: URL!)
        request.HTTPMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        //create body
    
//        let body = NSMutableData()
        let data = UIImageJPEGRepresentation(images[0]!, 1.0)
        let mime = "image/jpeg"
//        
//        body.appendString("--\(boundary)\r\n")
//        body.appendString("Content-Disposition: form-data; name = \"api_user\"")
//        body.appendString(username)
//        body.appendString("\r\n")
//        
//        body.appendString("--\(boundary)\r\n")
//        body.appendString("Content-Disposition: form-data; name = \"api_key\"")
//        body.appendString(password)
//        body.appendString("\r\n")
//        
//        body.appendString("--\(boundary)\r\n")
//        body.appendString("Content-Disposition: form-data; name = \"to\"")
//        body.appendString(sendTo)
//        body.appendString("\r\n")
//        
//        body.appendString("--\(boundary)\r\n")
//        body.appendString("Content-Disposition: form-data; name = \"toname\"")
//        body.appendString(sendName)
//        body.appendString("\r\n")
//        
//        body.appendString("--\(boundary)\r\n")
//        body.appendString("Content-Disposition: form-data; name = \"subject\"")
//        body.appendString("Testing")
//        body.appendString("\r\n")
//        
//        body.appendString("--\(boundary)\r\n")
//        body.appendString("Content-Disposition: form-data; name = \"text\"")
//        body.appendString(message)
//        body.appendString("\r\n")
//        
//        body.appendString("--\(boundary)\r\n")
//        body.appendString("Content-Disposition: form-data; name = \"from\"")
//        body.appendString(email!)
//        body.appendString("\r\n")
//        
//        body.appendString("--\(boundary)\r\n")
//        body.appendString("Content-Disposition: form-data; name= \"files[\(filename)]\"; filename=\"\(filename)\"\r\n")
//        body.appendString("Content-Type: \(mime)\r\n\r\n")
//        body.appendData(data)
//        body.appendString("\r\n")
//        
//        body.appendString("--\(boundary)--\r\n")
        
        
        
        let bodyString = "--\(boundary)\r\nContent-Disposition: form-data; name=\"api_user\"\r\n\n\(username)\r\n" +
                        "--\(boundary)\r\nContent-Disposition: form-data; name=\"api_key\"\r\n\n\(password)\r\n" +
                        "--\(boundary)\r\nContent-Disposition: form-data; name=\"to\"\r\n\n\(sendTo)\r\n" +
                        "--\(boundary)\r\nContent-Disposition: form-data; name=\"toname\"\r\n\n\(sendName)\r\n" +
                        "--\(boundary)\r\nContent-Disposition: form-data; name=\"subject\"\r\n\ntest\r\n" +
                        "--\(boundary)\r\nContent-Disposition: form-data; name=\"text\"\r\n\n\(message)\r\n" +
                        "--\(boundary)\r\nContent-Disposition: form-data; name=\"from\"\r\n\n\(email!)\r\n" +
                        "--\(boundary)\r\nContent-Disposition: form-data; name=\"files[\(filename)]\"; filename=\"\(filename)\"\r\nContent-Type: \(mime)\r\n\r\n\(data!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)))\r\n--\(boundary)"
        
       // let bodyStringpart2 = "\r\n--\(boundary)"
        
        //let mutable = NSMutableData()
        //mutable.appendData(bodyString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!)
       // mutable.appendData(!)
       // mutable.appendData(bodyStringpart2.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!)

        request.HTTPBody = bodyString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        
        
        request.setValue("\(request.HTTPBody!.length)", forHTTPHeaderField: "Content-Length")
        //request.HTTPBody = bodyString.dataUsingEncoding(NSUTF8StringEncoding)
        
        //let string = (NSString(data: body as NSData, encoding: NSUTF8StringEncoding))
        print(request)
        print(bodyString)
        
        let task = session.dataTaskWithRequest(request) { (data : NSData?, response : NSURLResponse?, error : NSError?) -> Void in
            if error == nil {
                
                if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                    print("URL Session Task Succeeded: HTTP \(statusCode)")
                    do {
                        let userData = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
                        if userData == nil {

                        }else {
                            print(userData!)
                        }
                        
                        
                    }catch {
                        print(error)
                    }
                    
                }
            }
        }
        task.resume()
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().UUIDString)"
    }
    
    func findMimetype() -> String {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ".jpg", nil)?.takeRetainedValue() {
            
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as NSString as String
            }
        }
        return "application/octet-stream"
    }
    
    func NSURLByAppendingQueryParameters(URL : NSURL!, queryParameters : Dictionary<String, String>) -> NSURL {
        let URLString : NSString = NSString(format: "%@?%@", URL.absoluteString, self.stringFromQueryParameters(queryParameters))
        return NSURL(string: URLString as String)!
    }
    
    func stringFromQueryParameters(queryParameters : Dictionary<String, String>) -> String {
        var parts: [String] = []
        for (name, value) in queryParameters {
            let part = NSString(format: "%@=%@",
                name.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!,
                value.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)
            parts.append(part as String)
        }
        return parts.joinWithSeparator("&")
    }
    
 
}

extension NSMutableData {
    
    func appendString(string : String) {
        let data : NSData = string.dataUsingEncoding(NSUTF8StringEncoding)!
        appendData(data)
    }
    
}