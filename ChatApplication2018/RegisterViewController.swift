//
//  RegisterViewController.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 04/08/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import UIKit
import XMPPFramework

class RegisterViewController: UIViewController {

    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var warningLabel: UILabel!
    
    var xmppRegister: XMPPRegister?
    var registrationAlertController: UIAlertController?
    var defaultAction: UIAlertAction?
    
    @IBAction func registerUser(_ sender: Any) {
        if (userNameField.text?.isEmpty)! || (passwordField.text?.isEmpty)! {
            warningLabel.text = "Please enter a username and password"
            return
        }
        
        let registerJID = userNameField.text! + "@" + Constants.Server.address
        print(registerJID)
        
        do {
            try self.xmppRegister = XMPPRegister(registerUserJIDString: registerJID, password: passwordField.text!)
            self.xmppRegister?.xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
            self.xmppRegister?.connect()
        } catch {
            print("something went wrong")
        }
    }
    
    @IBAction func backButton(_ sender: Any) {
        dismissRegisterVC()
    }
    
    func presentRegistrationSuccessAlert() {
        self.registrationAlertController = UIAlertController(title: "Registration succesful", message: "You can now login to ChatApplication2018", preferredStyle: .alert)
        self.defaultAction = UIAlertAction(title: "OK", style: .default, handler: { action in
            self.dismissRegisterVC()
        })
        registrationAlertController?.addAction(defaultAction!)
        present(registrationAlertController!, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if xmppRegister != nil {
            print("disconnecting")
            xmppRegister?.disconnect()
        }
    }
    
    func dismissRegisterVC() {
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }


}

extension RegisterViewController: XMPPStreamDelegate {
    
    func xmppStreamDidConnect(_ sender: XMPPStream) {
        print("Stream: Connected")
        try! sender.register(withPassword: (self.xmppRegister?.password)!)
    }
    
    func xmppStreamDidRegister(_ sender: XMPPStream) {
        print("\(sender.myJID?.user): Registered")
        try! sender.authenticate(withPassword: (self.xmppRegister?.password)!)
    }
    
    func xmppStream(_ sender: XMPPStream, didNotRegister error: DDXMLElement) {
        print("Unable to register")
        self.warningLabel.text = "Unable to register user"
    }
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        print("Stream: Authenticated")
        self.warningLabel.text = ""
        self.xmppRegister?.disconnect()
        presentRegistrationSuccessAlert()
    }
    
    func xmppStream(_ sender: XMPPStream, didReceiveError error: DDXMLElement) {
        print("username or resource is not allowed to create a session")
    }
    
    func xmppStream(_ sender: XMPPStream, didNotAuthenticate error: DDXMLElement) {
        print("Stream: Fail to Authenticate")
    }
    
    func xmppStreamDidDisconnect(_ sender: XMPPStream, withError error: Error?) {
        print("Stream: Disconnected")
    }
}
