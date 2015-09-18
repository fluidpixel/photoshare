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

  //class for adding share and send functionality
    
    func SendToFB(image : [UIImage?], message: [String]?, urls : [NSURL?], completionHandler: (result: Bool, detail: AnyObject?) -> ()) {
        
        //todo change for multiple images/retrieve errors
        var photoIds = [String]()
        var counter = 0
        for var i = 0; i < image.count; i++ {
        
            if image[i] != nil {
                
                if accountFB != nil {
                
                var parameters = [String : AnyObject]()
                
                parameters["access_token"] = accountFB!.credential.oauthToken
                
                let feedURL = NSURL(string: "https://graph.facebook.com/me/photos")
                
                let postRequest = SLRequest(forServiceType: SLServiceTypeFacebook, requestMethod: SLRequestMethod.POST, URL: feedURL, parameters: parameters)
                    
                postRequest.addMultipartData(UIImagePNGRepresentation(image[i]!), withName: "source", type: "multipart/form-data", filename: "photo.png")
                
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
                                photoIds.append(userData!.valueForKey("id") as! String)
                                print(userData!)
                            }
                        } catch {
                            print(error)
                        }
                        
                        //let m2 = ["Testing multiple images and text"]
                        
                         
                        if (counter == image.count) {
                            self.sendFBMessage(message, photoIds: photoIds) { (result, detail) -> () in
                                
                                if result == true {
                                    completionHandler(result: true, detail: nil)
                                }
                            }
                        }
                    } else {
                        print("ERROR: \(error)")
                    }
                })

                } else {
                    
                    print("ERROR: Account not set up")
                    completionHandler(result: false, detail: "Account not setup")
                }
            
            } else {
                print("ERROR: image does not exist")
            }
        }
        
    }
    
    func sendFBMessage(message: [String]?, photoIds : [String]?, completionHandler: (result : Bool, detail: AnyObject?) -> Void){
        
        if message != nil {
            let postURL = NSURL(string: "https://graph.facebook.com/me/feed")
            
            var feedParameters = [String : AnyObject]()
            
            var finalMessage : String = ""
            
            for all in message! {
                finalMessage += all
            }
            
    //        for var all = 0; all < photoIds!.count; all++ { //MULTIPLE IMAGES ON STATUS IS WIP
    //            
    //            feedParameters["image[\(all)][url]"] = photoIds![all]
    //            feedParameters["image[\(all)][user_generated]"] = true
    //        }
            
            feedParameters["message"] = finalMessage
            
            feedParameters["object_attachment"] = photoIds![0]
            feedParameters["access_token"] = self.accountFB!.credential.oauthToken
            
            let postRequestFeed = SLRequest(forServiceType: SLServiceTypeFacebook, requestMethod: SLRequestMethod.POST, URL: postURL, parameters: feedParameters)
            
            postRequestFeed.performRequestWithHandler({ (data : NSData!, response : NSHTTPURLResponse!, error : NSError!) -> Void in
                
                
                
                if error == nil {
                    
                    print("Facebook response : \(response.statusCode)")
                    
                    if response.statusCode >= 400 && response.statusCode < 500 {
                        completionHandler(result: false, detail: "Bad request, try again")
                    } else if response.statusCode >= 500 {
                        completionHandler(result: false, detail: "Server error, Facebook is having problems")
                    }
                    
                    
                    do {
                        let userData = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
                        if userData == nil {
                            
                        }else {
                            
                            print(userData!)
                            completionHandler(result: true, detail: userData!)
                        }
                    } catch {
                        completionHandler(result: false, detail: "JSON parse error")
                        print(error)
                    }
                    
                    
                    
                } else {
                    completionHandler(result: false, detail: error.localizedDescription)
                }
            })
        } else {
            completionHandler(result: true, detail: nil)
        }

    }
    
    func SendTweet(image : UIImage?, message : [String]?, completionHandler : (result: Bool, details : AnyObject?) -> ()) {
        
        if image != nil {
            
            if accountTwitter != nil {
                
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
                
                postrequest.account = accountTwitter
                
                let data = UIImagePNGRepresentation(image!)

                postrequest.addMultipartData(data, withName: "media", type: "multipart/form-data", filename: "photo.png")
                
                
                
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
                        
                        completionHandler(result: true, details: nil)
                    }
                    
                    
                    print("ERROR: \(error)")
                })
            }
            else {
                print("ERROR: Twitter not setup")
                
                completionHandler(result: false, details: "Account not setup")
            }
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
        var sendTo = "laurenevabrown28@gmail.com"
        var sendName = "Lauren Brown"
        var message = "This is a test"
        
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