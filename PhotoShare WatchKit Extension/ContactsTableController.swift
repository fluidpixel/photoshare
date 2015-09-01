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
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        _ = (context as! NSDictionary)["segue"] as? String
        let data : [String : String] = ((context as! NSDictionary)["data"] as? [String : String])!
        
        loadTable(data)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func loadTable(data : [String : String]) {
        
        ContactsTable.setNumberOfRows(data.count, withRowType: "Contact Row")
        var i = 0
        for (number, name) in data {
            if let row = ContactsTable.rowControllerAtIndex(i) as? ContactsTableRow {
                row.ContactName.setText(name)
                row.contactNumber.setText(number)
                
                row.referenceNumber = number
            }
            i++
        }
        
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        
        //on tap for contacts
        
        //record details then move one to messaging
        if let row = table.rowControllerAtIndex(rowIndex) as? ContactsTableRow {
            ContactDetails.contactNumber = row.referenceNumber
        }
        
        
        
        
        pushControllerWithName("DictationController", context: ["segue" : "hierarchical", "data" : ""])
        
    }
    
    
}

class ContactsTableRow : NSObject {
    
    @IBOutlet var ContactName: WKInterfaceLabel!
    @IBOutlet var contactNumber: WKInterfaceLabel!
    
    var referenceNumber : String?
    
}