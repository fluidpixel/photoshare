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

let kStoredImageList = "kStoredImageList"

struct ContactDetails {
    static var contactNumber : String?
    static var contactEmail : String?
    static var message : [String]?
    static var contactName : String?
    static let readyToSend = "messageIsReadyToSendKey"
}

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    @IBOutlet var imageTable: WKInterfaceTable!
    @IBOutlet weak var watchImage: WKInterfaceImage!
    @IBOutlet var WkButton: WKInterfaceButton!
    
    
    var assetCache = ImageCache()
    
    var session : WCSession!
    
    var selectedImage : [Int] = []
    var selectedLocalIdentifiers:[String] { return selectedImage.map { assetList[$0] } }
    
    var dictationResult = ""
    var contactsFromPhone = [String : String]()
    var contactsFromEmail = [String : String]()
    var mediumToSendWith = ""
    
    // Synced data from phone
    var assetList:[String] = ["NONE"] {
        
        didSet {
            if oldValue == ["NONE"] || oldValue != self.assetList {
                USER_DEFAULTS?.setObject(self.assetList, forKey: kStoredImageList)
                
                if self.assetList.count == 0 {
                    WkButton.setHidden(false)
                    WkButton.setTitle("No images found, tap to load them")
                }
                else {
                    WkButton.setHidden(true)    //loadTableData(), ShowDemo()
                }
                
                var requiredIDs:[String] = self.assetCache.cleanupAndRefresh(self.assetList)
                
                self.imageTable.setNumberOfRows(self.assetList.count, withRowType: "image row")
                
                for index in 0..<self.assetList.count {
                    let localID = self.assetList[index]
                    if let imageData = self.assetCache[localID],
                        let tableRow = self.imageTable.rowControllerAtIndex(index) as? ImageTableRowController {
                            tableRow.WKGroup.setBackgroundImageData(imageData)
                    }
                    else {
                        requiredIDs.append(localID)
                    }
                }
                
                // request images not in cache
                if requiredIDs.count > 0 {
                    requiredIDs = [String](Set<String>(requiredIDs))    // remove duplicates
                    if self.session.reachable {
                        self.session.sendMessage([kWPRequestImagesForLocalIdentifiers : requiredIDs], replyHandler: nil, errorHandler: nil)
                    }
                }
                
            }
        }
        
    }
    
    let pictureCountKey = "pictureCount"
    let lastUpdateKey = "DateLastModified"
    
    // MARK: WKInterfaceController overrides
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if WCSession.isSupported() {
            
            session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
            
            if session.reachable {
                // This will wake up the phone and request the latest phot library data
                session.sendMessage([kWPRequestImageData:true], replyHandler: nil, errorHandler: nil)
            }
            else {
                // Can't contact phone. Use last known asset list (if present)
                if let storedIDs = USER_DEFAULTS?.arrayForKey(kStoredImageList) as? [String] {
                    self.assetList = storedIDs
                }
                else {
                    self.assetList = []
                }
            }
        }
        
        self.setTitle("PhotoShare")
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "InfoGatherComplete", name: ContactDetails.readyToSend, object: nil)

    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        
        print("Selected image at row \(rowIndex)")
        //image filtering
        let row = table.rowControllerAtIndex(rowIndex) as! ImageTableRowController
        
        if selectedImage.contains(rowIndex) {
            let index = selectedImage.indexOf(rowIndex)
            
            selectedImage.removeAtIndex(index!)
            row.photo.setHidden(true)
            
            if selectedImage.count > 0 {
                self.setTitle("Share \(selectedImage.count) images")
            } else {
                self.setTitle("PhotoShare")
            }
            
            
        } else {
            
            row.photo.setHidden(false)
            selectedImage.append(rowIndex)
            self.setTitle("Share \(selectedImage.count) images")
        }
        
    }
    
    
    
    // MARK: WCSessionDelegate
    func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        if let localID = file.metadata?[kLocalIdentifier] as? String {
            
            print("Received File for: \(file.metadata)")

            if !(try! self.assetCache.insertItem(receivedFile: file)) {
                print("Image already cached - using cahced version instead")
            }
            
            if let index = self.assetList.indexOf(localID),
                let tableRow = self.imageTable.rowControllerAtIndex(index) as? ImageTableRowController,
                let imageData = self.assetCache[localID] {
                    tableRow.WKGroup.setBackgroundImageData(imageData)
            }
            
        }
        else {
            print("Unknown File Metadata: \(file.metadata)")
        }
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        print("Unknown Message \(message)")
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        var received = false
        
        if let newAssetList = message[kLocalIdentifierList] as? [String] {
            self.assetList = newAssetList
            received = true
        }
        
        if let modifiedDates = message[kAssetsLastModifiedDates] as? [String:NSDate] {
            let ref = self.assetCache.imagesRequiringRefresh(modifiedDates)
            if self.session.reachable {
                self.session.sendMessage([kWPRequestImagesForLocalIdentifiers : ref], replyHandler: nil, errorHandler: nil)
            }
            
            received = true
        }
        
        if !received {
            print("Unknown Message \(message)")
        }
    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        
        print("Recevied reply from phone - result : \(userInfo.values.first)")
        
        let alert = WKAlertAction(title: "Okay", style: WKAlertActionStyle.Default) { () -> Void in
            
        }
        
        var errormsg : String? = nil
        
        if userInfo["Result"] as! String == "Success" {
            clearSentPictures()
        } else {
            errormsg = userInfo["detail"] as? String
        }
        
        let title = (userInfo["Result"] as! String == "Success") ? "Message Sent!" : "Message Failed to Send!"
        
        
        
        presentAlertControllerWithTitle(title, message: errormsg, preferredStyle: WKAlertControllerStyle.Alert, actions: [alert])
        
    }
    
    
    // MARK: Utility Functions
    
     func ShowDemo() {
        
        let defaults = NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")
        
        if defaults?.boolForKey("hasPerformedFirstLaunch") == false {
            
            //set to true
            defaults?.setBool(false, forKey: "hasPerformedFirstLaunch")
            
            let tourAction : WKAlertAction = WKAlertAction(title: "Sure!", style: WKAlertActionStyle.Default) { () -> Void in
                print("Tour wanted")
                
                 self.presentControllerWithNames(["StartTourController", "TourPage2", "TourPage3", "TourPage4"], contexts: nil)
            }
            
            let ignoreAction : WKAlertAction = WKAlertAction(title: "No thanks", style: WKAlertActionStyle.Default) { () -> Void in
                print("No tour wanted")
            }
            
            presentAlertControllerWithTitle("Hello!", message: "Thank you for using PhotoShare, would you like the quick tour on using this app?", preferredStyle: WKAlertControllerStyle.SideBySideButtonsAlert, actions: [tourAction, ignoreAction])
            
        }
    }
    

    

    
    func clearSentPictures(){
        
        for var i = 0; i < imageTable.numberOfRows; i++ {
            let row = imageTable.rowControllerAtIndex(i) as! ImageTableRowController
            
            row.photo.setHidden(true)
        }
        selectedImage.removeAll()
        self.setTitle("PhotoShare")
    }

    @IBAction func WkButtonPressed() {
        
        if NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")?.integerForKey(pictureCountKey) > 0 {
        
//            if images.count > 0 {
//                pageNumber = (pageNumber + 1) % NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")!.integerForKey(pictureCountKey) //fix crash here
//                
//                WkButton.setHidden(true)
//                loadTableData()
//            }
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
            ShowDemo()
        }
        
        
    }

    @IBAction func SendTweet() {
        if selectedImage.count == 1 {
            mediumToSendWith = "Twitter"
            pushControllerWithName("DictationController", context: ["segue" : "hierarchical", "data" : ""])
            
        }else {
            showAlert("Twitter", numberOfImages: 1)
        }
    }
    
    
    @IBAction func ShareOnFB() {
        
        //facebook doesn't have a limit
         mediumToSendWith = "Facebook"
        pushControllerWithName("DictationController", context: ["segue" : "hierarchical", "data" : ""])
        
    }
    
    @IBAction func SendText() {
        
        if selectedImage.count <= 20 {
            GrabContacts()
            mediumToSendWith = "Text"
            //SendData("Text")
        } else {
            showAlert("Text", numberOfImages: 20)
        }
        
    }
    
    @IBAction func SendEmail() {
        
        if selectedImage.count <= 5 {
            mediumToSendWith = "Email"
            GrabEmails()
            
        } else {
            showAlert("Email", numberOfImages: 5)
        }
        
    }
    
    func InfoGatherComplete() {
        SendData(mediumToSendWith)
    }
    
    func showAlert( identifier : String, numberOfImages : Int) {
        
        let action : WKAlertAction = WKAlertAction(title: "Okay", style: WKAlertActionStyle.Default) { () -> Void in
            print("Action hit")
        }
        
        presentAlertControllerWithTitle("Share Messages Error", message: "Image limit exceeded for \(identifier), please only select up to \(numberOfImages) image(s)", preferredStyle: WKAlertControllerStyle.Alert, actions: [action])
        
    }
    
    func GrabContacts() {
        
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
            pushControllerWithName("ContactsTableController", context: ["segue" : "hierarchical", "data" : contactsFromPhone, "media" : "phone"])
            
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
            pushControllerWithName("ContactsTableController", context: ["segue" : "hierarchical", "data" : contactsFromEmail, "media" : "email"])
            
        }
        
    }
    
    
    
    func SendData(identifier: String) {

        //dictionary - imagenumbers
        //to do - allow the sharing of multiples and messages
        
        var contact : [String: String] = ["" : ""]
        
        if ContactDetails.message == nil {
            ContactDetails.message = [""]
        }
        
        if identifier == "Email" {
            if ContactDetails.contactEmail != nil {
                contact["Address"] = ContactDetails.contactEmail!
                contact["Name"] = ContactDetails.contactName
        
            } else {
                return
            }
            
        } else if identifier == "Text" {
            contact["Address"] = ContactDetails.contactNumber!
        }
        
        let metaData : [String : AnyObject] = [kSelectedImagesLocalIdentifiers : self.selectedLocalIdentifiers,
            "Media" : identifier,
            "Message" : ContactDetails.message! as [AnyObject],
            "Contact" : contact]
        
        session.transferUserInfo(metaData)
        
    }

}
