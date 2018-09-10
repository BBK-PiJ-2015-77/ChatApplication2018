//
//  ChatViewController.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 17/07/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//
//  Key Resources:
//  https://medium.com/@dzungnguyen.hcm/autolayout-for-scrollview-keyboard-handling-in-ios-5a47d73fd023
//  https://developer.apple.com/library/archive/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html
//  https://stackoverflow.com/questions/14173251/xmppframework-retrieving-openfire-message-archives
//  https://stackoverflow.com/questions/38626004/add-subtitle-under-the-title-in-navigation-bar-controller-in-xcode?noredirect=1&lq=1

/**
 The ChatViewController class provides a table showing all the messages sent/received with another user
 Provides a means to send messages
 **/

import UIKit
import XMPPFramework

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var chatInput: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var chatTableView: UITableView!
    
    var xmppController: XMPPController?
    var recipientJID: XMPPJID?
    var xmppMessages: [XMPPMessage] = []
    var userPresence: String = "offline"
    
    // The following are required for adaptive scrolling
    var activeField: UITextField?
    var lastOffset: CGPoint!
    var keyboardHeight: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Log.print("ChatViewController did load", loggingVerbosity: .high)
        self.xmppController?.xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        //Following makes sure the keyboard can be dismissed by interacting with the table view
        self.chatTableView.keyboardDismissMode = .onDrag
        
        // Size the table size appropriately
        setTableConstraints()
        
        // Retrieve and display messages
        retrieveMessages()
        
        // Keyboard setup
        chatInput.delegate = self
        chatInput.returnKeyType = .send
        
        initateObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        presenceProbe()
        setTitle()
    }
    
    func initateObservers() {
        // Observe keyboard changes
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func presenceProbe() {
        // Request presence from recipient
        let probe = DDXMLElement.element(withName: "presence") as! DDXMLElement
        probe.addAttribute(withName: "to", stringValue: (self.recipientJID?.bare)!)
        probe.addAttribute(withName: "type", stringValue: "probe")
        self.xmppController?.xmppStream?.send(probe)
        
        // As per XEP-0012 - request last time the user was active
        let lastActiveQuery = DDXMLElement.element(withName: "iq") as! DDXMLElement
        lastActiveQuery.addAttribute(withName: "id", stringValue: "last1")
        lastActiveQuery.addAttribute(withName: "to", stringValue: (self.recipientJID?.bare)!)
        lastActiveQuery.addAttribute(withName: "type", stringValue: "get")
        
        let query = DDXMLElement.element(withName: "query") as! DDXMLElement
        query.addAttribute(withName: "xmlns", stringValue: "jabber:iq:last")
        
        lastActiveQuery.addChild(query)
        self.xmppController?.xmppStream?.send(lastActiveQuery)
    }
    
    func setTitle() {
        // Set the other user's username as the main title
        let titleLabel = UILabel(frame: CGRect(x: 0, y: -2, width: 0, height: 0))
        titleLabel.backgroundColor = .clear
        titleLabel.textColor = .black
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.text = self.recipientJID?.user!
        titleLabel.sizeToFit()
        
        // Set the other user's presence
        let subtitleLabel = UILabel(frame: CGRect(x: 0, y: 18, width: 0, height: 0))
        subtitleLabel.backgroundColor = .clear
        subtitleLabel.textColor = .gray
        subtitleLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        subtitleLabel.text = self.userPresence
        subtitleLabel.sizeToFit()
        
        let titleView = UIView(frame:  CGRect(x: 0, y: 0, width: max(titleLabel.frame.size.width, subtitleLabel.frame.size.width), height: 30))
        titleView.addSubview(titleLabel)
        titleView.addSubview(subtitleLabel)
        
        let widthDiff = subtitleLabel.frame.size.width - titleLabel.frame.size.width
        if widthDiff < 0 {
            let newX = widthDiff / 2
            subtitleLabel.frame.origin.x = abs(newX)
        } else {
            let newX = widthDiff / 2
            titleLabel.frame.origin.x = newX
        }
        
        self.navigationItem.titleView = titleView
    }
    
    // Send a 'chat' type message on the XMPP stream
    func sendMessage(message: String) {
        let xmppMessage = XMPPMessage(type: "chat", to: recipientJID)
        xmppMessage.addBody(message)
        self.xmppController?.xmppStream?.send(xmppMessage)
    }
    
    // Retrieve messages from core data
    func retrieveMessages() {

        let storage = xmppController?.xmppMessageArchivingStorage
        let moc: NSManagedObjectContext? = storage?.mainThreadManagedObjectContext
        var entityDescription: NSEntityDescription? = nil
        
        if let aMoc = moc {
            entityDescription = NSEntityDescription.entity(forEntityName: "XMPPMessageArchiving_Message_CoreDataObject", in: aMoc)
        }
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        
        let predicateFormat = "bareJidStr like %@ "
        let predicateFormat2 = "streamBareJidStr like %@ "
        /**
         predicate1 matches "bareJidStr" (the other chat participant's JID) with the JID of the other chat participant in this ChatViewController AND  matches "streamBareJidStr" with the current user's JID. Consider an example with 2 users, user1 & user2 - this predicate retrieves all messages sent and received between user1 and user2 on user1's stream.
         **/
        let predicate1 = NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: predicateFormat, recipientJID!.bare),NSPredicate(format: predicateFormat2, (self.xmppController?.userJID.bare)!)])
        
        // Similarly to predicate1 above, this predicate retrieves all messages sent and received between user1 and user2 on user2's stream
        let predicate2 = NSCompoundPredicate(type: .and, subpredicates: [NSPredicate(format: predicateFormat, (self.xmppController?.userJID.bare)!),NSPredicate(format: predicateFormat2, recipientJID!.bare)])
        
        // The final predicate ensures only messages between user1 and user2 are retrieved from the core data, regardless of which user's stream the messages were sent
        let andOrPredicate = NSCompoundPredicate(type: .or, subpredicates: [predicate1,predicate2])
        request.predicate = andOrPredicate
        
        request.entity = entityDescription
        let messages_arc = try? moc?.fetch(request)
        printMessages((messages_arc as! [AnyHashable]))
    }
    
    // Add messages to the array xmppMessages, then load this data into the table view
    func printMessages(_ messages_arc: [AnyHashable]?) {
        autoreleasepool {
            for message: XMPPMessageArchiving_Message_CoreDataObject? in messages_arc as? [XMPPMessageArchiving_Message_CoreDataObject?] ?? [XMPPMessageArchiving_Message_CoreDataObject?]() {
                let element = try? XMLElement(xmlString: message?.messageStr ?? "")
                let message = XMPPMessage(from: element!)
                xmppMessages.append(message)
            }
            
            self.chatTableView.reloadData()
            scrollToBottom()
        }
    }
    
    // MARK: - Scroll to bottom
    
    // Called to make sure the most recent messages at the bottom of the table are showing
    func scrollToBottom() {
        if xmppMessages.count != 0 {
            let index = IndexPath(row: xmppMessages.count-1, section: 0)
            self.chatTableView.scrollToRow(at: index, at: .bottom, animated: true)
        }
    }
    
    // MARK: - TableView setup
    
    func setTableConstraints() {
        chatTableView.rowHeight = UITableViewAutomaticDimension
        chatTableView.estimatedRowHeight = 140
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return xmppMessages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = xmppMessages[indexPath.row]
        let cell: MessageTableViewCell

        // Check whether the message should be contained within a "sentMessageCell" or a "receivedMessageCell - affecting whether the message is aligned right (for sent messages) or left (for recieved messages)
        switch message.to?.bare {
        case  recipientJID?.bare:
            cell = tableView.dequeueReusableCell(withIdentifier: "sentMessageCell") as! MessageTableViewCell
        default :
            cell = tableView.dequeueReusableCell(withIdentifier: "receivedMessageCell") as! MessageTableViewCell
        }
        
        cell.setMessage(xmppMessage: message)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chatTableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Returns a String, stating that the other user is offline and when they were last online
    func getTimeLastActive(seconds: Double = 0) -> String {
        let formatter = DateFormatter()
        
        //If the user was last active withing 24hrs, just show time, otherwise, show both date and time
        if seconds < (86400) {
            formatter.dateFormat = "HH:mm a"
        } else {
            formatter.dateFormat = "dd/MM/YYYY HH:mm a"
        }
        
        let timeLastActive = formatter.string(from: Date() - seconds)
        return "offline, last active \(timeLastActive)"
    }

}


extension ChatViewController: XMPPStreamDelegate {
    
    // If a message is received, add it to the xmppMessages array and reload the table
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        if message.isChatMessage {
            self.xmppMessages.append(message)
            self.chatTableView.reloadData()
            scrollToBottom()
        }
    }
    
    // If a message is sent, add it to the xmppMessages array and reload the table
    func xmppStream(_ sender: XMPPStream, didSend message: XMPPMessage) {
        if message.isMessageWithBody {
            self.xmppMessages.append(message)
            self.chatTableView.reloadData()
            scrollToBottom()
        }
    }
    
    // Handles received presence stanzas
    func xmppStream(_ sender: XMPPStream, didReceive presence: XMPPPresence) {
        print("ChatViewController XMPPStreamDelegate did receive presence")
        if presence.isErrorPresence {
            Log.print("ChatViewController - Error presence received from \((presence.from?.bare)!)", loggingVerbosity: .high)
        }
        
        // Check that the presence received is from the other user
        if presence.from?.bare == self.recipientJID?.bare {
            switch presence.type {
            case "available" :
                userPresence = "online"
                setTitle()
            case "unavailable":
                userPresence = getTimeLastActive()
                setTitle()
            default:
                userPresence = "offline"
                setTitle()
            }
        }
    }
    
    // Handles received iq stanzas with time last active information
    func xmppStream(_ sender: XMPPStream, didReceive iq: XMPPIQ) -> Bool {
        if iq.elementID == "last1" && iq.type == "result" {
            let sec = iq.childElement?.attributeDoubleValue(forName: "seconds") as! Double
            if userPresence == "offline" {
                self.userPresence = getTimeLastActive(seconds: sec)
                setTitle()
            }
        }
        return true
    }

}


// These UITextFieldDelegate functions have been seperated to an extension for clarity.
extension ChatViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        activeField = textField
        lastOffset = self.scrollView.contentOffset
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if chatInput.text != nil && chatInput.text != "" {
            sendMessage(message: chatInput.text!)
        }
        chatInput.text = nil
        activeField = nil
        return true
    }
    
}

// MARK: - Keyboard Handling

extension ChatViewController {
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if keyboardHeight != nil {
            return
        }
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
            //increase contentView's height by keyboard height
            
            // move if keyboard hides input field
            let distanceToBottom = self.scrollView.frame.size.height - (activeField?.frame.origin.y)! - (activeField?.frame.size.height)!
            let collapseSpace = keyboardHeight - distanceToBottom
            if collapseSpace < 0 {
                //no collapse
                return
            }
            
            // set new offset for scroll view
            UIView.animate(withDuration: 0.3, animations: {
                // scroll to the position above keyboard 10 points
                self.scrollView.contentOffset = CGPoint(x: self.lastOffset.x, y: collapseSpace + 10)
            })               
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.scrollView.contentOffset = self.lastOffset
        }
        keyboardHeight = nil
    }
    
}

