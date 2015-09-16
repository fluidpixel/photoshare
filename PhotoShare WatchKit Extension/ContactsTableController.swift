//
//  ContactsTableController.swift
//  PhotoShare
//
//  Created by Lauren Brown on 26/08/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import Foundation
import WatchKit

class ContactsTableController : WKInterfaceController {
    
    @IBOutlet var ContactsTable: WKInterfaceTable!
    var filters : [String : String]?
    var phoneContacts : Bool?
    
    @IBOutlet var searchButton: WKInterfaceButton!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        _ = (context as! NSDictionary)["segue"] as? String
        let data : [String : String] = ((context as! NSDictionary)["data"] as? [String : String])!
        
        if (context as! NSDictionary)["media"] as! String == "phone" {
            phoneContacts = true
        } else if (context as! NSDictionary)["media"] as! String == "email" {
            phoneContacts = false
        }
        
        filters = data
        //filterResults()
        //loadTable(data)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func loadTable(result : [String]) {
        
        ContactsTable.setNumberOfRows(result.count, withRowType: "Contact Row")
        var validEntries = [String : String]()
        
        for (key, value) in filters! {
            
            for all in result {
                
                if all == value {
                    validEntries[key] = value
                }
            }
            
        }
        
        
        var i = 0
        
        let array : [String]? = (validEntries as NSDictionary).keysSortedByValueUsingSelector("compare:") as? [String]
        
        for (key) in array! {
            if let row = ContactsTable.rowControllerAtIndex(i) as? ContactsTableRow {
                row.ContactName.setText(validEntries[key])
                row.contactNumber.setText(key)
                row.referenceName = validEntries[key]
                row.referenceNumber = key
            }
            i++
        }
        
    }
    
    @IBAction func OnSearch() {
        
        filterResults()
    }
    
     func filterResults() {
        
        let names : [String] = Array(filters!.values)
        
        presentTextInputControllerWithSuggestions(names, allowedInputMode: WKTextInputMode.Plain) { (result : [AnyObject]?) -> Void in

            if result != nil {
                
                self.loadTable(result! as! [String])
                
                
            }
            
        }
        
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        
        //on tap for contacts
        
        //record details then move one to messaging
        if let row = table.rowControllerAtIndex(rowIndex) as? ContactsTableRow {
            if phoneContacts == true {
                ContactDetails.contactNumber = row.referenceNumber
                ContactDetails.contactName = row.referenceName
            } else if phoneContacts == false {
                ContactDetails.contactEmail = row.referenceNumber
                ContactDetails.contactName = row.referenceName
            }
            
        }

        pushControllerWithName("DictationController", context: ["segue" : "hierarchical", "data" : ""])
        
    }
    
    
}

class ContactsTableRow : NSObject {
    
    @IBOutlet var ContactName: WKInterfaceLabel!
    @IBOutlet var contactNumber: WKInterfaceLabel!
    
    var referenceNumber : String?
    var referenceName : String?
    
}