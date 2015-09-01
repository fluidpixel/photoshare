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
import Contacts

struct ContactDetails {
    static var contactNumber : String?
    static var contactEmail : String?
    static var message : [String]?
}

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    @IBOutlet var imageTable: WKInterfaceTable!
    @IBOutlet weak var watchImage: WKInterfaceImage!
    @IBOutlet var WkButton: WKInterfaceButton!
    
    //stored variables
    var pageNumber = 0
    var arraySize = 0
    var storedImages = [Int : AnyObject]()
    var storedIDs : [String : NSDate]?
    var images = [UIImage]()
    var session : WCSession!
    var selectedImage : [Int] = []
    var dictationResult = ""
    var contactsFromPhone = [String : String]()
    var contactsFromEmail = [String : String]()
    
    let maxPictureCount = 25
    let pictureCountKey = "pictureCount"
    let lastUpdateKey = "DateLastModified"
    let pictureArrayKey = "photoAddresses"
    let IDsArrayKey = "StoredIDs"
    let latestImageKey = "NewestImage"

    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        let defaults = NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")
        
        var dateLastModified : NSDate? = defaults?.objectForKey(lastUpdateKey) as? NSDate
        
        if dateLastModified == nil {
            dateLastModified = NSDate.distantPast()
        }
        
        if let tempStoredIDs = NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")?.dictionaryForKey(IDsArrayKey) as? [String : NSDate] {
            
            storedIDs = tempStoredIDs
            
        }else {
            storedIDs = [String : NSDate]()
        }
        
        //load in currently stored pictures
        
        let pictureCounter = NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")?.integerForKey(pictureCountKey)
        
        var wasImageSet = false
        
        for var i = 0; i < pictureCounter; i++ {
            
            let filename = "PhotoGallery\(i).jpg"
            var dir : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
            dir = dir.stringByAppendingPathComponent(filename)
            
            let image = UIImage(contentsOfFile: dir as String)
            
            if image != nil {
                if i == 0 {
                    wasImageSet = true
                }
                images.append(image!)
            }
            
        }
        
        if !wasImageSet {
            WkButton.setHidden(false)
            WkButton.setTitle("No images found, tap to load them")
        } else {
            WkButton.setHidden(true)
            loadTableData()
        }
        
        if (WCSession.isSupported()) {
            
            session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
            
            let requestData = NSDateFormatter().stringFromDate(dateLastModified!).dataUsingEncoding(NSUTF8StringEncoding)
            session.sendMessageData(requestData!, replyHandler: { (response: NSData) -> Void in
                
                print("response GOT")
            },
                  errorHandler: { (error: NSError) -> Void in
                    
                    print("ERROR : \(error)")
            })
        }

    }
    
    func loadTableData() {
        imageTable.setNumberOfRows(images.count, withRowType: "image row")
        
        for (index, image) in images.enumerate() {
            if let row = imageTable.rowControllerAtIndex(index) as? ImageTableRowController {
                row.WKGroup.setBackgroundImage(image)
                //row.photo.setImage(image)
            }
        }
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        
        print("Selected image at row \(rowIndex)")
        
        //image filtering
        let row = table.rowControllerAtIndex(rowIndex) as! ImageTableRowController
        
        if selectedImage.contains(rowIndex) {
            let index = selectedImage.indexOf(rowIndex)
            
            selectedImage.removeAtIndex(index!)
            row.photo.setHidden(true)
            
        } else {
    
            row.photo.setHidden(false)
            selectedImage.append(rowIndex)
        }
        
        
    }
    
    
    // SESSIONS
    func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        
        print("received a file at : \(file.fileURL.relativePath!)")
        
        let identifier = file.metadata
        
        let creationDate = identifier!["creationDate"] as! NSDate
        
        if let data = NSData(contentsOfURL: file.fileURL) {
            if let image = UIImage(data: data) {
                
                let userdefaults = NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")
                
                if images.count >= maxPictureCount {
                    //push out oldest image from array
                    
                    let newestImageIndex  = userdefaults?.integerForKey(pictureCountKey)
                    
                    let oldestImageIndex = (newestImageIndex! + 1) % maxPictureCount
                    
                    userdefaults?.setValue(oldestImageIndex, forKey: pictureCountKey)
                    
                    
                } else {
                    //update newest image and carry on
                    userdefaults?.setValue((images.count), forKey: pictureCountKey)
                    
                    images.append(image)

                }
                
                
                
                var url : NSString = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
                
                
                
                let fileName = "PhotoGallery\(userdefaults!.integerForKey(pictureCountKey)).jpg"
                
                if let tempStoredIDs = userdefaults?.dictionaryForKey(IDsArrayKey) as? [String : NSDate] {
                    
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
                
                if let defaults = NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare") {
                
                if var arrayCurrent = defaults.arrayForKey(pictureArrayKey) {
                    
                    arrayCurrent.append(url)
                    
                    defaults.setObject(arrayCurrent, forKey: pictureArrayKey)
                    
                } else {
                    var newArray = [String]()
                    
                    newArray.append(url as String)
                    
                    defaults.setObject(newArray, forKey: pictureArrayKey)
                }
                
//                var pictureCount = defaults.integerForKey(pictureCountKey)
//                
//                pictureCount++
//                
//                defaults.setValue(pictureCount, forKey: pictureCountKey)
                
                let updatedDate = NSDate()

                defaults.setObject(updatedDate, forKey: lastUpdateKey)
                defaults.setObject(storedIDs, forKey: IDsArrayKey)
                }
                
                WkButton.setHidden(true)
                loadTableData()
            }
        }

    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        
        print("Recevied reply from phone - result : \(userInfo.values.first)")
        
        let alert = WKAlertAction(title: "Okay", style: WKAlertActionStyle.Default) { () -> Void in
            
        }
        
        let title = (userInfo.values.first as! String == "Success") ? "Message Sent!" : "Message Failed to Send!"
        
        presentAlertControllerWithTitle(title, message: nil, preferredStyle: WKAlertControllerStyle.Alert, actions: [alert])
        
    }
    //END SESSIONS

    @IBAction func WkButtonPressed() {
        
        if NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")?.integerForKey(pictureCountKey) > 0 {
        
            if images.count > 0 {
                pageNumber = (pageNumber + 1) % NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")!.integerForKey(pictureCountKey) //fix crash here
                
                WkButton.setHidden(true)
                loadTableData()
            }
        } else {
            
            var dateLastModified : NSDate? = NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")?.objectForKey(lastUpdateKey) as? NSDate
            
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

    @IBAction func SendTweet() {

        SendData("Twitter")
    }
    
    
    @IBAction func ShareOnFB() {
        
        SendData("Facebook")
    }
    
    @IBAction func SendText() {
        
        GrabContacts()
        //SendData("Text")
    }
    
    @IBAction func SendEmail() {
        
        GrabEmails()
        //SendData("Email")
    }
    
    func GrabContacts() {
        
        //do I actually /need/ this?
        let store = CNContactStore()
        
        do {
            try store.enumerateContactsWithFetchRequest(CNContactFetchRequest(keysToFetch: [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]), usingBlock: { (contact, status) -> Void in
                
                for numbers in contact.phoneNumbers {
                    
                    if numbers.label.rangeOfString("Mobile") != nil {
                        
                        let no  = numbers.value as? CNPhoneNumber
                        
                        print(no!.stringValue)
                        
                        self.contactsFromPhone[no!.stringValue] = "\(contact.givenName) \(contact.familyName)"
                    }
                }
                
                
                print("name: \(contact.givenName) \(contact.familyName)")
                
                print("Status - \(status)")
                
                
            })
        } catch {
            print("Could not grab contacts, do they have any?")
        }
        
        
        
        if contactsFromPhone.count > 0 {
            
            //display the list of available contacts to pick
            pushControllerWithName("ContactsTableController", context: ["segue" : "hierarchical", "data" : contactsFromPhone])
            
        }
        
        
    }
    
    func GrabEmails() {
        
        let store = CNContactStore()
        
        do {
            try store.enumerateContactsWithFetchRequest(CNContactFetchRequest(keysToFetch: [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey]), usingBlock: { (contact, status) -> Void in
                
                for mail in contact.emailAddresses {
                    
                    if mail.label.rangeOfString("Work") != nil || mail.label.rangeOfString("Home") != nil {
                        
                        let no  = mail.value as? String
                        
                        print(no)
                        
                        self.contactsFromEmail[no!] = "\(contact.givenName) \(contact.familyName)"
                    }
                }
                
                
                print("name: \(contact.givenName) \(contact.familyName)")
                
                print("Status - \(status)")
                
                
            })
                
        } catch {
            
        }
        
        if contactsFromEmail.count > 0 {
            
            //display the list of available contacts to pick
            pushControllerWithName("EmailController", context: ["segue" : "hierarchical", "data" : contactsFromEmail])
            
        }
        
    }
    
    
    
    func SendData(identifier: String) {

        //dictionary - imagenumbers
        
        let metaData : [String : AnyObject] = ["ID" : storedIDs!["\(selectedImage[0])"] as! AnyObject,
                                                "Media" : identifier]
        
        
        _ = session.transferUserInfo(metaData)
        
    }

}
