//
//  HomeTabBarController.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 03/06/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

/**
 The HomeTabBarController class inherits UITabBarController and is a container for the ChatsViewController and SettingsViewController objects. The LoginViewController is initiated from here also. The HomeTabBarController is responsible for the creation of the XMPPController and all logging in/out, or changes of presence should be communicated through the HomeTabBarController
 **/

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
        initateObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let retrievedPassword: String? = KeychainWrapper.standard.string(forKey: "userPassword")
        let retrievedUserName: String? = KeychainWrapper.standard.string(forKey: "userName")
        
        // Check if there is a saved username or password on the device
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
        //print("HTBC will disappear")
        Log.print("HomeTabBarController viewWillDisappear() is called", loggingVerbosity: .high)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        Log.print("HomeTabBarController: viewDidDisappear() is called", loggingVerbosity: .high)
    }
    
    // MARK: - Login methods
    
    func autoLogIn(userJID: String, userPassword: String) {
        do {
            try logIn(userJID: userJID, userPassword: userPassword)
            Log.print("HomeTabBarController: Automatically logged in with saved credentials", loggingVerbosity: .high)
            loggedIn = true
        } catch {
            Log.print("HomeTabBarController: Unable to login with saved credentials", loggingVerbosity: .high)
        }
    }
    
    func logIn(userJID: String, userPassword: String) throws {
            try self.xmppController = XMPPController(userJIDString: userJID, password: userPassword)
            self.xmppController?.xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
            self.xmppController?.connect()
    }
    
    @objc func logOut(notfication: NSNotification) {
        logOut()
    }
    
    func logOut() {
        self.xmppController?.disconnect()
        self.loggedIn = false
        self.xmppController = nil
    }
    
    // MARK: - Change presence
    
    @objc func setPresenceUnavailable(notfication: NSNotification) {
        if self.xmppController?.presence?.type != "unavailable" {
           self.xmppController?.goOffline()
        }
    }
    
    @objc func setPresenceAvailable(notfication: NSNotification) {
        if self.xmppController?.presence?.type != "available" {
          self.xmppController?.goOnline()
        }
    }
    
    func initateObservers() {
        // Once the user has logged out, change variable 'loggedIn' to false, disconnect XMPPController and remove pointer. Broadcast by SettingsViewController
        NotificationCenter.default.addObserver(self, selector: #selector(logOut(notfication:)), name: .loggedOut, object: nil)
        
        //Want to set presence type to "unavailable" when app enters background and "available" when it re-enters the foreground
        NotificationCenter.default.addObserver(self, selector: #selector(setPresenceUnavailable(notfication:)), name: .presenceUnavailable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setPresenceAvailable(notfication:)), name: .presenceAvailable, object: nil)
    }

}

// MARK: - LoginViewControllerDelegate implementation

extension HomeTabBarController: LoginViewControllerDelegate {
    func didTouchLogIn(sender: LoginViewController, userJID: String, userPassword: String) {
        self.loginViewController = sender
        do {
            try logIn(userJID: userJID, userPassword: userPassword)
            Log.print("HomeTabBarController: Logged in with new credentials", loggingVerbosity: .high)
            loggedIn = true
        } catch {
            sender.showErrorMessage(message: "Error logging in")
        }
    }
}

// MARK: - XMPPStreamDelegate methods

extension HomeTabBarController: XMPPStreamDelegate {
    
    //if login details are authenticated, the LoginViewController view is dismissed - if it exists
    func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        self.loginViewController?.dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: .streamAuthenticated, object: nil)
    }
    
    func xmppStream(_ sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        self.loginViewController?.showErrorMessage(message: "Wrong password or username")
        logOut()
    }
    
}

