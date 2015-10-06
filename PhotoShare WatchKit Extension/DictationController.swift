//
//  DictationController.swift
//  PhotoShare
//
//  Created by Lauren Brown on 27/08/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import WatchKit
import Foundation


class DictationController: WKInterfaceController {

    @IBOutlet var MessageText: WKInterfaceLabel!
    
    @IBOutlet var addMessageButton: WKInterfaceButton!
    @IBOutlet var sendButton: WKInterfaceButton!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func AddMessage() {
        
        presentTextInputControllerWithSuggestions(nil, allowedInputMode: WKTextInputMode.Plain) { (result : [AnyObject]?) -> Void in
            
            var stringMessage = ""
            if result?.count > 0 {
                for results in result! {
                    stringMessage = stringMessage + (results as! String)
                }
            }
            
            self.MessageText.setText(stringMessage)
            
            ContactDetails.message = (result as? [String]?)!
        }
    }
    @IBAction func SendMessage() {
        
        NSNotificationCenter.defaultCenter().postNotificationName(ContactDetails.readyToSend, object: self)
    }
}
