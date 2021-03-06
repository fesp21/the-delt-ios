//
//  AlertDetailTableViewCell.swift
//  XCHAT
//
//  Created by Mateo Garcia on 12/25/16.
//  Copyright © 2016 Mateo Garcia. All rights reserved.
//

import UIKit
import Parse
import ParseUI

@objc protocol AlertDetailTableViewCellDelegate {
    func alertDetailTableViewCell(updateFaved faved: Bool)
    func alertDetailTableViewCellReplyToAlert()
    func alertDetailTableViewCell(updateFlagged flagged: Bool)
}

class AlertDetailTableViewCell: UITableViewCell {
    
    @IBOutlet weak var profileImageView: ProfileImageView!
    @IBOutlet weak var nameLabel: UsernameLabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var usernameLabel: UsernameLabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoImageViewTopSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var photoImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var photoImageViewLeadingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var photoImageViewTrailingSpaceConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var faveButton: UIButton!
    @IBOutlet weak var faveCountLabel: UILabel!
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var replyCountLabel: UILabel!
    @IBOutlet weak var flagButton: UIButton!
    
    weak var delegate: AlertDetailTableViewCellDelegate?
    var alert: PFObject?
    var faved = false
    var flagged = false
    
    let kPhotoImageViewHeight: CGFloat = 8
    let kPhotoImageViewTopSpace: CGFloat = 200
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.profileImageView.layer.cornerRadius = 3
        self.profileImageView.clipsToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        self.faved = false
        self.flagged = false
        self.profileImageView.image = nil
        self.photoImageView.image = nil
        self.photoImageView.isHidden = false
        self.photoImageViewHeightConstraint.constant = self.kPhotoImageViewHeight
        self.photoImageViewTopSpaceConstraint.constant = self.kPhotoImageViewTopSpace
    }
}


// MARK: - Setup

extension AlertDetailTableViewCell {
    func setUpCell(alert: PFObject) {
        self.alert = alert
        
        // Name, username and profile picture.
        if let author = alert["author"] as? PFUser {
            self.profileImageView.user = author
            author.fetchIfNeededInBackground(block: { (fetchedAuthor: PFObject?, error: Error?) in
                if let usableAuthor = fetchedAuthor as? PFUser {
                    if let profilePhoto = usableAuthor["photo"] as? PFFile {
                        let pfImageView = PFImageView()
                        pfImageView.file = profilePhoto
                        pfImageView.load { (image: UIImage?, error: Error?) -> Void in
                            if let error = error {
                                // Log details of the failure
                                print("Error: \(error) \(error.localizedDescription)")
                                
                            } else {
                                self.profileImageView.image = image
                            }
                        }
                    }
                    self.nameLabel.user = author
                    self.nameLabel.text = author["name"] as? String
                    self.usernameLabel.user = author
                    if let username = author.username {
                        self.usernameLabel.text = "@" + username
                    }
                }
            })
        }
        
        if let postedAt = alert.createdAt {
            let dateFormatter = DateFormatter()
            let calendar = Calendar.current
            //        dateFormatter.dateFormat = "M/d"
            //        self.dateLabel.text = dateFormatter.string(from: postedAt)
            
            dateFormatter.amSymbol = "a"
            dateFormatter.pmSymbol = "p"
            var comp = (calendar as NSCalendar).components([.hour, .minute], from: postedAt)
            dateFormatter.dateFormat = "M/d h:mma"
            if comp.minute == 0 {
                dateFormatter.dateFormat = "ha"
            }
            self.dateLabel.text = dateFormatter.string(from: postedAt)
        }
        
        self.subjectLabel.text = alert["subject"] as? String
        self.messageLabel.text = alert["message"] as? String
        
        if let photo = alert["photo"] as? PFFile {
            print("ALERT PHOTO URL:", photo.url)
            
            let pfImageView = PFImageView()
            pfImageView.file = photo
            pfImageView.load { (image: UIImage?, error: Error?) -> Void in
                if let error = error {
                    // Log details of the failure
                    print("Error: \(error) \(error.localizedDescription)")
                } else if let image = image {
                    let aspectRatio = image.size.width / image.size.height
                    let newHeight = (UIScreen.main.bounds.width - (self.photoImageViewLeadingSpaceConstraint.constant + self.photoImageViewTrailingSpaceConstraint.constant)) / aspectRatio
                    UIView.animate(withDuration: 1, animations: {
                        self.photoImageView.image = image
                        self.photoImageViewHeightConstraint.constant = newHeight
                    })
                }
            }
        } else {
            self.photoImageView.isHidden = true
            self.photoImageViewTopSpaceConstraint.constant = 0
        }
        
        // Faves.
        if let favedBy = alert["favedBy"] as? [String] {
            if let username = PFUser.current()?.username {
                self.faved = favedBy.contains(username)
            }
        }
        self.faveButton.isSelected = self.faved
        if let faveCount = alert["faveCount"] as? Int {
            if faveCount > 0 {
                self.faveCountLabel.text = String(faveCount)
            } else {
                self.faveCountLabel.text = ""
            }
        } else {
            self.faveCountLabel.text = ""
        }
        
        // Replies.
        if let replyCount = alert["replyCount"] as? Int {
            if replyCount > 0 {
                self.replyCountLabel.text = String(replyCount)
            } else {
                self.replyCountLabel.text = ""
            }
        } else {
            self.replyCountLabel.text = ""
        }
        
        // Flagged.
        if let flaggedBy = alert["flaggedBy"] as? [String] {
            if let username = PFUser.current()?.username {
                self.flagged = flaggedBy.contains(username)
            }
        }
        self.flagButton.isSelected = self.flagged
    }
}


// MARK: - Actions

extension AlertDetailTableViewCell {
    @IBAction func onFaveButtonTapped(_ sender: Any) {
        // Prevent double updating.
        if self.faveButton.isSelected == self.faved {
            self.faveButton.isSelected = !self.faved
            self.delegate?.alertDetailTableViewCell(updateFaved: !self.faved)
        }
    }
    
    @IBAction func onReplyButtonTapped(_ sender: Any) {
        self.delegate?.alertDetailTableViewCellReplyToAlert()
    }
    
    @IBAction func onFlagButtonTapped(_ sender: Any) {
        // Prevent double updating.
        if self.flagButton.isSelected == self.flagged {
            self.flagButton.isSelected = !self.flagged
            self.delegate?.alertDetailTableViewCell(updateFlagged: !self.flagged)
        }
    }
}
