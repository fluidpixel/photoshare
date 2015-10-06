//
//  MessagePopoverController.swift
//  PhotoShare
//
//  Created by Lauren Brown on 05/10/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import UIKit

class MessagePopoverController: UIViewController {

    @IBOutlet weak var Message: UITextView!
    @IBOutlet weak var PostButton: UIButton!
    @IBOutlet weak var CancelButton: UIButton!
    @IBOutlet weak var Image: UIImageView!
    @IBOutlet weak var Image2: UIImageView!
    @IBOutlet weak var Image3: UIImageView!
    @IBOutlet weak var Media: UILabel!
    @IBOutlet weak var CharactersLeftTwitter: UILabel!
    
    var imagesToShare = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Message.text = "Message text goes here"
        if Media.text == "Facebook" {
            CharactersLeftTwitter.hidden = true
        } else {
            CharactersLeftTwitter.hidden = false
        }
    }
    

    @IBAction func Post(sender: UIButton) {
        if Media.text == "Facebook" {
            if imagesToShare.count > 0 {
                Classes.shareClass.SendToFB(imagesToShare, message: [Message.text]) { (result, detail) -> () in
                    if result == true {

                        print("INFO: Photo shared - Facebook")
                        //self.ShareMessage("Complete", message: detail as! String)

                    } else if detail as? String == "Account"{

                       // self.showLoginAlert("Facebook")

                    } else if result == false {

                       // self.ShareMessage("Error", message: detail as! String)
                    }
                }
            }
        } else if Media.text == "Twitter" {
            if imagesToShare.count == 1 {
                Classes.shareClass.SendTweet(imagesToShare[0], message: [Message.text]) { (result, detail) -> () in
                    if result == true {

                        print("INFO: Photo shared - Twitter")
                        //self.ShareMessage("Complete", message: detail as! String)

                    } else if detail as? String == "Account"{

                        //self.showLoginAlert("Facebook")

                    } else if result == false {

                       // self.ShareMessage("Error", message: detail as! String)
                    }
                }
            }
            else {
                //self.ShareMessage("Error", message: "You haven't selected any images")
            }

        }
    }
    
    
    @IBAction func Cancel(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
