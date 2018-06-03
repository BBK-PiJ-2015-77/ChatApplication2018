//
//  HomeTabBarController.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 03/06/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import UIKit
import XMPPFramework

class HomeTabBarController: UITabBarController {

    weak var loginViewController: LoginViewController?
    var logInPresented = false
    var xmppController: XMPPController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !self.logInPresented {
            self.logInPresented = true
            self.performSegue(withIdentifier: "loginView", sender: nil)
        }
    }
    
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
    
}

extension HomeTabBarController: XMPPStreamDelegate {
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream!) {
        self.loginViewController?.dismiss(animated: true, completion: nil)
    }
    
    func xmppStream(_ sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        self.loginViewController?.showErrorMessage(message: "Wrong password or username")
    }
    
}
