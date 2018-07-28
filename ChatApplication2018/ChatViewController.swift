//
//  ChatViewController.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 17/07/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import UIKit
import XMPPFramework

class ChatViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var chatInput: UITextField!
    
    var xmppController: XMPPController?
    var recipientJID: XMPPJID?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Shouldn't do this with the whole array
        userLabel.text = recipientJID?.user
        
        chatInput.delegate = self
        chatInput.returnKeyType = .send
        
        //will need a method to dismiss the keyboard without sending a message
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func chatInput(_ textFieldToChange: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        //an example of how to work with text field
        // limit to 4 characters
        let characterCountLimit = 4
        
        // We need to figure out how many characters would be in the string after the change happens
        let startingLength = textFieldToChange.text?.count ?? 0
        let lengthToAdd = string.count
        let lengthToReplace = range.length
        
        let newLength = startingLength + lengthToAdd - lengthToReplace
        
        return newLength <= characterCountLimit
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if chatInput.text != nil {
            sendMessage(message: chatInput.text!)
        }
        return true
    }
    
    func sendMessage(message: String) {
        let xmppMessage = XMPPMessage(type: "chat", to: recipientJID)
        xmppMessage.addBody(message)
        self.xmppController?.xmppStream?.send(xmppMessage)
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
