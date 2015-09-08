//
//  TourInterfaceController.swift
//  PhotoShare
//
//  Created by Lauren Brown on 08/09/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import WatchKit
import Foundation


//Contains ALL the pages used for the first time tour

class TourInterfaceController: WKInterfaceController {

    @IBOutlet var TourTextLabel: WKInterfaceLabel!
    @IBOutlet var TourImage: WKInterfaceImage!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        fillContent()
        
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
    
    func fillContent() {
        //use this method to fill text and images for tour
        TourTextLabel.setText("PhotoShare stores the last 25 images and allows you to share them easily straight from your watch! Simply tap on the images to start sharing.")
    }

}

class TourInterfacePage2 : WKInterfaceController {
    
    @IBOutlet var Page2Image: WKInterfaceImage!
    
    @IBOutlet var Page2Label: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        fillContent()
        
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
    
    func fillContent() {
        //TODO : Add Image
        
        Page2Label.setText("Once selected, firm press to bring up the share menu, then press one of the options.")
        
        
    }

}

class TourInterfacePage3 : WKInterfaceController {
    
    @IBOutlet var Page3Label: WKInterfaceLabel!
    
    @IBOutlet var Page3Image: WKInterfaceImage!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        fillContent()
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
    
    func fillContent() {
        //TODO : Add Image
        
        Page3Label.setText("If you share by email or text, select the person you want to share to, and add an optional message.")
        
        
    }
    
}

class TourInterfacePage4 : WKInterfaceController {
    
    @IBOutlet var Page4Image: WKInterfaceImage!
    @IBOutlet var Page5Label: WKInterfaceLabel!
    
    @IBOutlet var Page5Button: WKInterfaceButton!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        fillContent()
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
    
    @IBAction func FinishedTour() {
        dismissController()
    }
    
    func fillContent() {
        Page5Label.setText("And then you're done! You'll get a message to tell you the result.")
    }
    
}