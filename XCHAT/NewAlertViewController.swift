//
//  NewAlertViewController.swift
//  XCHAT
//
//  Created by Mateo Garcia on 12/23/16.
//  Copyright © 2016 Mateo Garcia. All rights reserved.
//

import UIKit
import MBProgressHUD
import MediaPlayer
import MobileCoreServices
import Parse

@objc protocol NewAlertViewControllerDelegate {
    func refreshData(completion: @escaping (() -> ()))
}

class NewAlertViewController: AlertComposeViewController {
    
    @IBOutlet weak var subjectTextView: UITextView!
    @IBOutlet weak var messageTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


// MARK: - Helpers

extension NewAlertViewController {
    func postAlert() {
        print("POSTING")
        
        // User forgets to enter alert subject.
        if self.subjectTextView.text == "" {
            let alert = UIAlertController(title: "Add Alert Subject", message: "Whatchu tryna say bro.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        } else {
            let alert = PFObject(className: "Alert")
            
            alert["subject"] = self.subjectTextView.text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if self.messageTextView.text.characters.count > 0 {
                alert["message"] = self.messageTextView.text
            }
            // alert["createdBy"] = PFUser.current()!.username!
            alert["author"] = PFUser.current()!
            alert["authorName"] = PFUser.current()!["name"]
            
            if self.photo != nil {
                let imageData = UIImageJPEGRepresentation(self.photo!, 100)
                let imageFile = PFFile(name: "image.jpeg", data: imageData!)
                alert["image"] = imageFile
                
                if self.video != nil {
                    alert["video"] = self.video
                }
            }
            
            let currentHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
            currentHUD.label.text = "Posting Alert..."
            alert.saveInBackground { (result: Bool, error: Error?) -> Void in
                if error != nil {
                    currentHUD.hide(animated: true)
                    print(error!.localizedDescription)
                    let alertVC = UIAlertController(title: "Unable to Post Alert", message: "Please try again.", preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alertVC, animated: true, completion: nil)
                } else {
                    self.delegate?.refreshData(completion: {
                        currentHUD.hide(animated: true)
                        self.dismiss(animated: true, completion: nil)
                    })
                }
            }
        }
    }
}


// MARK: - Actions

extension NewAlertViewController {
    @IBAction func onPostButtonTapped(_ sender: Any) {
        self.postAlert()
    }
}
