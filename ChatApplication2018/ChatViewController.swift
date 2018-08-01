//
//  ChatViewController.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 17/07/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//
//  Adaptable scrollview/textfield comes from Dzung Nguyen's post from Medium.com
//  https://medium.com/@dzungnguyen.hcm/autolayout-for-scrollview-keyboard-handling-in-ios-5a47d73fd023
//  Also similar to Apple's documentation:
//  https://developer.apple.com/library/archive/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html

import UIKit
import XMPPFramework

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var chatInput: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    //@IBOutlet weak var chatText: UITextView!
    
    @IBOutlet weak var chatTableView: UITableView!
    
    //data
    var xmppController: XMPPController?
    //var xmppStream: XMPPStream?
    var recipientJID: XMPPJID?
    //var xmppMessageArchivingStorage: XMPPMessageArchivingCoreDataStorage?
    //var xmppMessageArchiving: XMPPMessageArchiving?
    var xmppMessages: [XMPPMessage] = []
    
    //used for adaptive scrolling
    var activeField: UITextField?
    var lastOffset: CGPoint!
    var keyboardHeight: CGFloat!
    // Constraints
    @IBOutlet weak var constraintContentHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = recipientJID?.user
        //self.xmppStream = xmppController?.xmppStream
        self.xmppController?.xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        //initialise archive
        //Maybe this should be done on the XMPPController?
        //setupMessageArchiving()
        retrieveMessages()
        
        
        //keybaord setup
        chatInput.delegate = self
        chatInput.returnKeyType = .send
        
        //will need a method to dismiss the keyboard without sending a message
        
        // Observe keyboard change
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func sendMessage(message: String) {
        let xmppMessage = XMPPMessage(type: "chat", to: recipientJID)
        xmppMessage.addBody(message)
        self.xmppController?.xmppStream?.send(xmppMessage)
    }
    
    /*
    func setupMessageArchiving() {
        xmppMessageArchivingStorage = XMPPMessageArchivingCoreDataStorage()
        xmppMessageArchiving = XMPPMessageArchiving(messageArchivingStorage: xmppMessageArchivingStorage)
        xmppMessageArchiving?.activate((xmppController?.xmppStream)!)
        xmppMessageArchiving?.addDelegate(self, delegateQueue: DispatchQueue.main)
    }
    */
    
    func retrieveMessages() {

        let storage = xmppController?.xmppMessageArchivingStorage
            //XMPPMessageArchivingCoreDataStorage.sharedInstance() as? XMPPMessageArchivingCoreDataStorage
        let moc: NSManagedObjectContext? = storage?.mainThreadManagedObjectContext
        var entityDescription: NSEntityDescription? = nil
        if let aMoc = moc {
            entityDescription = NSEntityDescription.entity(forEntityName: "XMPPMessageArchiving_Message_CoreDataObject", in: aMoc)
        }
        let request = NSFetchRequest<NSFetchRequestResult>()
        let predicateFrmt = "bareJidStr like %@ "
        let predicate = NSPredicate(format: predicateFrmt, recipientJID!.bare)
        request.predicate = predicate
        request.entity = entityDescription
        let messages_arc = try? moc?.fetch(request)
        
        printMessages(messages_arc as! [AnyHashable])

    }
    
    func printMessages(_ messages_arc: [AnyHashable]?) {
        var messageString = ""

        autoreleasepool {
            for message: XMPPMessageArchiving_Message_CoreDataObject? in messages_arc as? [XMPPMessageArchiving_Message_CoreDataObject?] ?? [XMPPMessageArchiving_Message_CoreDataObject?]() {
                let element = try? XMLElement(xmlString: message?.messageStr ?? "")
                xmppMessages.append(XMPPMessage(from: element!))
            }
            
            for message in xmppMessages {
                if message.body != nil {
                    messageString += message.body! + "\n"
                }
            }
            //chatText.text = messageString
            self.chatTableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("row count \(xmppMessages.count)")
        return xmppMessages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = xmppMessages[indexPath.row]
        let cell: MessageTableViewCell

        if message.to?.bare == recipientJID?.bare {
            cell = tableView.dequeueReusableCell(withIdentifier: "sentMessageCell") as! MessageTableViewCell
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "receivedMessageCell") as! MessageTableViewCell
        }
        
        cell.setMessage(xmppMessage: message)
        return cell
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


extension ChatViewController: XMPPStreamDelegate {
    
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        self.xmppMessages.append(message)
        self.chatTableView.reloadData()
        let index = IndexPath(row: xmppMessages.count-1, section: 0)
        self.chatTableView.scrollToRow(at: index, at: .bottom, animated: true)
    }
    
    func xmppStream(_ sender: XMPPStream, didSend message: XMPPMessage) {
        self.xmppMessages.append(message)
        self.chatTableView.reloadData()
        //scroll to bottom of table view
        let index = IndexPath(row: xmppMessages.count-1, section: 0)
        self.chatTableView.scrollToRow(at: index, at: .bottom, animated: true)
    }

}

extension ChatViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        activeField = textField
        lastOffset = self.scrollView.contentOffset
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if chatInput.text != nil || chatInput.text != "" {
            sendMessage(message: chatInput.text!)
        }
        chatInput.text = nil
        activeField = nil
        return true
    }
    
}

//  Keyboard Handling
extension ChatViewController {
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if keyboardHeight != nil {
            return
        }
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            keyboardHeight = keyboardSize.height
            //increase contentView's height by keyboard height
            /*
            UIView.animate(withDuration: 0.3, animations: {
                self.constraintContentHeight.constant += self.keyboardHeight
            })
            */
            
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
            //self.constraintContentHeight.constant -= self.keyboardHeight
            self.scrollView.contentOffset = self.lastOffset
        }
        keyboardHeight = nil
    }
    
}

