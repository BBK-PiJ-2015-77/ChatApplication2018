//
//  SettingsViewController.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 03/06/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper

class SettingsViewController: UIViewController {

    //Use viewWillAppear to have something update everytime the view is switched
    //viewDidLoad only happens once for each child view
    
    //weak var delegate: SettingsViewControllerDelegate?
    var xmppController: XMPPController!
    
    @IBAction func logoutAction(_ sender: Any) {
        
        //elf.delegate?.didTouchLogIn(sender: self, userJID: jID, userPassword: self.passwordTextField.text!)
        xmppController.xmppStream.disconnect()
        removeCredentials()
        Variables.OnlineStatus.loggedIn = false
        //return to homescreen
        self.performSegue(withIdentifier: "logoutToHome", sender: nil)
    }
    
    func removeCredentials() {
        var removeSuccessful: Bool = KeychainWrapper.standard.removeObject(forKey: "userPassword")
        print("Password removal was successful: \(removeSuccessful)")
        removeSuccessful = KeychainWrapper.standard.removeObject(forKey: "userName")
        print("Username removal was successful: \(removeSuccessful)")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        let htbvc = tabBarController as! HomeTabBarController
        xmppController = htbvc.xmppController // this is how to share data between tab controllers - but do I need access to it?
        // Do any additional setup after loading the view.
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

/*
protocol SettingsViewControllerDelegate: class {
    func didTouchLogout()
    //func didTouchLogIn(sender: LoginViewController, userJID: String, userPassword: String)
}
 */






