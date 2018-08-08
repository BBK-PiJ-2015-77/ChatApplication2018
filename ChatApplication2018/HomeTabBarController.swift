//
//  HomeTabBarController.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 03/06/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import UIKit
import XMPPFramework
import SwiftKeychainWrapper

class HomeTabBarController: UITabBarController {
    
    weak var loginViewController: LoginViewController?
    var xmppController: XMPPController?
    var loggedIn = false
    
    // MARK: - Navigation

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Once the user has logged out, change variable 'loggedIn' to false, disconnect XMPPController and remove pointer. Broadcast by SettingsViewController
        NotificationCenter.default.addObserver(self, selector: #selector(logOut(notfication:)), name: .loggedOut, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let retrievedPassword: String? = KeychainWrapper.standard.string(forKey: "userPassword")
        let retrievedUserName: String? = KeychainWrapper.standard.string(forKey: "userName")
        
        if retrievedPassword == nil && retrievedUserName == nil && !loggedIn {
            // Segue to LoginViewController for user to login
            self.performSegue(withIdentifier: "loginView", sender: nil)
        } else if !loggedIn {
            // Otherwise, login with the credentials that are saved on the system
            autoLogIn(userJID: retrievedUserName!, userPassword: retrievedPassword!)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "loginView" {
            let viewController = segue.destination as! LoginViewController
            viewController.delegate = self
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("HTBC will disappear")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("HTBC did disappear")
    }
    
    func autoLogIn(userJID: String, userPassword: String) {
        do {
            try logIn(userJID: userJID, userPassword: userPassword)
            print("Automatically logged in with saved credentials")
            loggedIn = true
        } catch {
            //need to show an error message to the user, below is just for testing
            print("something went wrong")
        }
    }
    
    func logIn(userJID: String, userPassword: String) throws {
            try self.xmppController = XMPPController(userJIDString: userJID,
                                                     password: userPassword)
            self.xmppController?.xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
            self.xmppController?.connect()
    }
    
    @objc func logOut(notfication: NSNotification) {
        self.xmppController?.disconnect()
        self.loggedIn = false
        self.xmppController = nil
    }

}

extension HomeTabBarController: LoginViewControllerDelegate {
    func didTouchLogIn(sender: LoginViewController, userJID: String, userPassword: String) {
        self.loginViewController = sender
        do {
            try logIn(userJID: userJID, userPassword: userPassword)
            print("Logged in with new credentials")
            loggedIn = true
        } catch {
            sender.showErrorMessage(message: "Something went wrong")
        }
    }
}

extension HomeTabBarController: XMPPStreamDelegate {
    
    //if login details are authenticated, the LoginViewController view is dismissed - if it exists
    func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        self.loginViewController?.dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: .streamAuthenticated, object: nil)
    }
    
    func xmppStream(_ sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        self.loginViewController?.showErrorMessage(message: "Wrong password or username")
    }
    
}

protocol HomeTabBarControllerDelegate: class {
    func didTouchLogIn(sender: LoginViewController, userJID: String, userPassword: String)

}

