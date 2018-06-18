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
    var logInPresented = false
    var xmppController: XMPPController!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "loginView" {
            let viewController = segue.destination as! LoginViewController
            viewController.delegate = self
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let retrievedPassword: String? = KeychainWrapper.standard.string(forKey: "userPassword")
        let retrievedUserName: String? = KeychainWrapper.standard.string(forKey: "userName")
        
        if retrievedPassword != nil && retrievedUserName != nil {
            //login with stored credentials
            autoLogIn(userJID: retrievedUserName!, userPassword: retrievedPassword!, server: "ec2-35-177-34-255.eu-west-2.compute.amazonaws.com")
        } else //bring up log in page
        {
            self.logInPresented = true
            self.performSegue(withIdentifier: "loginView", sender: nil)
        }
    }

}

extension HomeTabBarController: LoginViewControllerDelegate {
    
    func didTouchLogIn(sender: LoginViewController, userJID: String, userPassword: String, server: String) {
        //Test
        print("got here5")
        self.loginViewController = sender
        
        do {
            try self.xmppController = XMPPController(hostName: server,
                                                     userJIDString: userJID,
                                                     password: userPassword)
            self.xmppController.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
            self.xmppController.connect()
        } catch {
            sender.showErrorMessage(message: "Something went wrong")
        }
    }
    
    func autoLogIn(userJID: String, userPassword: String, server: String) {
        do {
            //need to reconfigure so that I am not sending the host name every time
            //May also be issues with userJID - full or with domain?
            //Also, duplicated code
            try self.xmppController = XMPPController(hostName: server,
                                                     userJIDString: userJID,
                                                     password: userPassword)
            //init(hostName: String, userJIDString: String, hostPort: UInt16 = 5222, password: String)
            self.xmppController.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
            self.xmppController.connect()
        } catch {
            //need to show an error message to the user, below is just for testing
            print("something went wrong")
        }
    }
    
}

extension HomeTabBarController: XMPPStreamDelegate {
    
    //if login details are authenticated, the modal view is dismissed
    func xmppStreamDidAuthenticate(_ sender: XMPPStream!) {
        self.loginViewController?.dismiss(animated: true, completion: nil)
    }
    
    func xmppStream(_ sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        self.loginViewController?.showErrorMessage(message: "Wrong password or username")
    }
    
}
