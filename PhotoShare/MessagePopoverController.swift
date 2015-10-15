//
//  MessagePopoverController.swift
//  PhotoShare
//
//  Created by Lauren Brown on 05/10/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import UIKit
import Social

class MessagePopoverController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var Message: UITextView!
    @IBOutlet weak var PostButton: UIButton!
    @IBOutlet weak var CancelButton: UIButton!
    @IBOutlet weak var Image: UIImageView!
    @IBOutlet weak var Image2: UIImageView!
    @IBOutlet weak var Image3: UIImageView!
    @IBOutlet weak var Media: UILabel!
    @IBOutlet weak var CharactersLeftTwitter: UILabel!
    
    
    var imagesToShare = [UIImage]()
    var shareType: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Message.text = PlaceholderText
        Message.textColor = UIColor.lightGrayColor()
        
        if shareType == SLServiceTypeTwitter {
            CharactersLeftTwitter.hidden == false
            Media.text = "Twitter"
        } else {
            CharactersLeftTwitter.hidden = true
            Media.text = "Facebook"
        }
        
        CharactersLeftTwitter.text = "0"
        Message.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    func textViewDidBeginEditing(textView: UITextView) {
        if textView.text == PlaceholderText {
            textView.text = ""
            textView.textColor = UIColor.blackColor()
        }
    }
    func textViewDidChange(textView: UITextView) {
        CharactersLeftTwitter.text = "\(textView.text.characters.count)"
        if textView.text.characters.count > 140 && Media.text == "Twitter"{
            CharactersLeftTwitter.textColor = UIColor.redColor()
            PostButton.enabled = false
        } else if Media.text == "Twitter"{
            CharactersLeftTwitter.textColor = UIColor.lightGrayColor()
            PostButton.enabled = true
        }
    }

    @IBAction func Post(sender: UIButton) {
        if Media.text == "Facebook" {
            if imagesToShare.count > 0 {
                Classes.shareClass.SendToFB(imagesToShare, message: [Message.text]) { (result, detail) -> () in
                    if result == true {

                       print("INFO: Photo shared - Facebook")
                       Observer.Message[0] = "Complete"
                       Observer.Message[1] = detail as? String
                       NSNotificationCenter.defaultCenter().postNotificationName(Observer.MessageReceived, object: nil)


                    } else if detail as? String == "Account"{

                       Observer.Message[0] = "Login"
                       Observer.Message[1] = "Facebook"
                        NSNotificationCenter.defaultCenter().postNotificationName(Observer.MessageReceived, object: nil)

                    } else if result == false {


                       Observer.Message[0] = "Error"
                       Observer.Message[1] = detail as? String
                        NSNotificationCenter.defaultCenter().postNotificationName(Observer.MessageReceived, object: nil)
                    }
                }
            }
        } else if Media.text == "Twitter" {
            if imagesToShare.count == 1 {
                
                Classes.shareClass.SendTweet(imagesToShare[0], message: [Message.text]) { (result, detail) -> () in
                    if result == true {

                        print("INFO: Photo shared - Twitter")
                        
                        Observer.Message[0] = "Complete"
                        Observer.Message[1] = detail as? String
                        NSNotificationCenter.defaultCenter().postNotificationName(Observer.MessageReceived, object: nil)


                    } else if detail as? String == "Account"{

                        Observer.Message[0] = "Login"
                        Observer.Message[1] = "Twitter"
                        NSNotificationCenter.defaultCenter().postNotificationName(Observer.MessageReceived, object: nil)

                    } else if result == false {
                        
                        Observer.Message[0] = "Error"
                        Observer.Message[1] = detail as? String
                        NSNotificationCenter.defaultCenter().postNotificationName(Observer.MessageReceived, object: nil)
                    }
                }
            }
            else {
            }

        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func Cancel(sender: UIButton) {
        NSNotificationCenter.defaultCenter().postNotificationName(Observer.PopoverDismissed, object: nil)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
