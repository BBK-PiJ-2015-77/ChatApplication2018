//
//  RegisterViewController.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 04/08/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

/**
 This class controls the register view, and therefore how the user is able to register on the server, by creating an instance of XMPPRegister
 **/

import UIKit
import XMPPFramework

class RegisterViewController: UIViewController {

    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var passwordValidate: UITextField!
    @IBOutlet weak var warningLabel: UILabel!
    
    var xmppRegister: XMPPRegister?
    var registrationAlertController: UIAlertController?
    var defaultAction: UIAlertAction?
    
    private let server = Constants()
    
    // MARK: - Navigation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if xmppRegister != nil {
            print("disconnecting")
            xmppRegister?.disconnect()
        }
    }
    
    // MARK: - @IBAction methods
    
    //Register a user on the server with the username they have entered
    @IBAction func registerUser(_ sender: Any) {
        if (userNameField.text?.isEmpty)! || (passwordField.text?.isEmpty)! {
            warningLabel.text = "Please enter a username and password"
            return
        }
        if !(passwordField.text?.isEmpty)! && (passwordValidate.text?.isEmpty)! {
            warningLabel.text = "Please enter password twice"
            return
        }
        if passwordField.text != passwordValidate.text {
            warningLabel.text = "Passwords do not match"
        } else {
            
            let registerJID = userNameField.text! + "@" + server.getAddress()
            print(registerJID)
            
            //Make sure the username conforms to JID convention
            guard let _ = XMPPJID(string: registerJID) else {
                warningLabel.text = "Username is not valid"
                return
            }
            
            do {
                try self.xmppRegister = XMPPRegister(registerUserJIDString: registerJID, password: passwordField.text!)
                self.xmppRegister?.xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
                self.xmppRegister?.connect()
            } catch {
                Log.print("RegisterViewController: Unable to initiate XMPPRegister object", loggingVerbosity: .high)
            }
            
        }
    }
    
    //Remove the view when the 'Back' button is pressed
    @IBAction func backButton(_ sender: Any) {
        dismissRegisterVC()
    }
    
    // MARK: - Registration complete / dismiss VC
    
    //A UIAlert is dispalyed to the user when registration is successful
    func presentRegistrationSuccessAlert() {
        self.registrationAlertController = UIAlertController(title: "Registration succesful", message: "You can now login to ChatApplication2018", preferredStyle: .alert)
        self.defaultAction = UIAlertAction(title: "OK", style: .default, handler: { action in
            self.dismissRegisterVC()
        })
        registrationAlertController?.addAction(defaultAction!)
        present(registrationAlertController!, animated: true, completion: nil)
    }
    
    //Method for removing this ViewController
    func dismissRegisterVC() {
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }

}

// MARK: - XMPPStreamDelegate methods

extension RegisterViewController: XMPPStreamDelegate {
    
    func xmppStreamDidConnect(_ sender: XMPPStream) {
        print("Register Stream: Connected")
        try! sender.register(withPassword: (self.xmppRegister?.password)!)
    }
    
    func xmppStreamDidRegister(_ sender: XMPPStream) {
        Log.print("User registered: \(String(describing: sender.myJID?.user))", loggingVerbosity: .high)
        try! sender.authenticate(withPassword: (self.xmppRegister?.password)!)
    }
    
    func xmppStream(_ sender: XMPPStream, didNotRegister error: DDXMLElement) {
        Log.print("RegisterViewController: Unable to register", loggingVerbosity: .high)
        let childNodes = error.children
        
        //Check what errors are received, to update the user on what is causing the error
        var errorCodeCheck = 0
        for node in childNodes! {
            if node.name == "error" {
                if node.description.contains("code=\"409\" type=\"cancel\"") {
                    self.warningLabel.text = "Username is already registered"
                    errorCodeCheck = 1
                } else if node.description.contains("code=\"500\" type=\"wait\"") {
                    self.warningLabel.text = "You can not register another user so quickly"
                    errorCodeCheck = 1
                }
            }
        }
        
        //If any other type of error is received, apart from the ones listed above, give a generic warning
        if errorCodeCheck == 0 {
            self.warningLabel.text = "Unable to register user"
        }
    }
    
    //Once the stream has sucesfully authenticated, it is disconnected, and a UIAlert is presented to the user
    func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        Log.print("Register Stream: Authenticated", loggingVerbosity: .high)
        self.warningLabel.text = ""
        self.xmppRegister?.disconnect()
        presentRegistrationSuccessAlert()
    }
    
    func xmppStream(_ sender: XMPPStream, didReceiveError error: DDXMLElement) {
        Log.print("RegisterViewController: username or resource is not allowed to create a session", loggingVerbosity: .high)
    }
    
    func xmppStream(_ sender: XMPPStream, didNotAuthenticate error: DDXMLElement) {
        Log.print("Register Stream: Fail to Authenticate", loggingVerbosity: .high)
    }
    
    func xmppStreamDidDisconnect(_ sender: XMPPStream, withError error: Error?) {
        Log.print("Register Stream: Disconnected", loggingVerbosity: .high)
    }
}

