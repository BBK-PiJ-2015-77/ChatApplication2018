//
//  LoginViewController.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 28/05/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//
//  Key Resources:
//  https://www.erlang-solutions.com/blog/build-a-complete-ios-messaging-app-using-xmppframework-part-2.html

/**
 This class controls the login view, and therefore how the user is able to login to the server. The loogin function, didTouchLogIn, to be implemented by a LoginViewController delegate
 **/

import UIKit
import XMPPFramework

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    weak var delegate: LoginViewControllerDelegate?
    
    private let server = Constants()
    
    // MARK: - Navigation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add text fields as delegates and change default 'return' button to 'done'
        loginTextField.delegate = self
        passwordTextField.delegate = self
        loginTextField.returnKeyType = .done
        passwordTextField.returnKeyType = .done
    }
    
    // MARK: - @IBAction methods
    
    //Login a user on the server with the username and password they have entered
    @IBAction func logInAction(_ sender: Any) {

        if (self.loginTextField.text?.isEmpty)!
        || (self.passwordTextField.text?.isEmpty)!{
            showErrorMessage(message: "Please enter a username and password")
            return
        }
        
        let jID: String = self.loginTextField.text! + "@" + server.getAddress()
        Log.print("LoginViewController: Log in JID: \(jID)", loggingVerbosity: .high)
        
        //Make sure the username conforms to JID convention
        guard let _ = XMPPJID(string: jID) else {
            showErrorMessage(message: "Username is not valid")
            return
        }
        
        self.delegate?.didTouchLogIn(sender: self, userJID: jID, userPassword: self.passwordTextField.text!)
        Log.print("LoginViewController didTouchLogIn method called", loggingVerbosity: .high)
    }
    
    //Need the following as a function to give other classess access to the errorLabel
    func showErrorMessage(message: String) {
        self.errorLabel.text = message
    }
    
    //Make sure the keyboard is dismissed when a given UITextField is finished editing
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}

// MARK: - LoginViewControllerDelegate protocol

protocol LoginViewControllerDelegate: class {
    func didTouchLogIn(sender: LoginViewController, userJID: String, userPassword: String)
}
