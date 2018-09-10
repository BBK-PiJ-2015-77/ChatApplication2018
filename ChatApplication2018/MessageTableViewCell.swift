//
//  MessageTableViewCell.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 30/07/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import UIKit
import XMPPFramework

class MessageTableViewCell: UITableViewCell {

    @IBOutlet weak var messageLabel: UILabel!
    
    func setMessage(xmppMessage: XMPPMessage) {
        if xmppMessage.body != nil {
            messageLabel.text = xmppMessage.body
        }
    }

}
