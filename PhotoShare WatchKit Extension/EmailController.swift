//
//  EmailController.swift
//  PhotoShare
//
//  Created by Lauren Brown on 28/08/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import WatchKit
import Foundation


class EmailController: WKInterfaceController {

    @IBOutlet var emailTable: WKInterfaceTable!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        
        _ = (context as! NSDictionary)["segue"] as? String
        let data : [String : String] = ((context as! NSDictionary)["data"] as? [String:String])!
        
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
        
        emailTable.setNumberOfRows(data.count, withRowType: "Email Row")
        
        var i = 0
        
        //todo: sort result ofr better looking finish
        
        for (value, name) in (data) {
            if let row = emailTable.rowControllerAtIndex(i) as? EmailRowController {
                row.emailAddress.setText(value)
                row.referenceEmail = value
                
                row.nameLabel.setText(name)
            }
            
            i++
        }

        
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        
        if let row = table.rowControllerAtIndex(rowIndex) as? EmailRowController {
            ContactDetails.contactEmail = row.referenceEmail
        }

        pushControllerWithName("DictationController", context: ["segue" : "hierarchical", "data" : ""])
        
    }

}

class EmailRowController : NSObject {
    
    @IBOutlet var emailAddress: WKInterfaceLabel!
    @IBOutlet var nameLabel: WKInterfaceLabel!
    
    var referenceEmail : String?
    
}