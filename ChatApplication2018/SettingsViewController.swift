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
    
    //var xmppController: XMPPController?
    //var homeTabBarController: HomeTabBarController?
    
    
    @IBAction func logoutAction(_ sender: Any) {
        
        //xmppController?.disconnect()
        removeCredentials()
        
        //change this to a notification
        //homeTabBarController?.loggedIn = false
        //homeTabBarController?.xmppController = nil
        
        //return to homescreen
        NotificationCenter.default.post(name: .loggedOut, object: nil)
        
        
        self.tabBarController?.selectedIndex = 0
       
    }
    
    func removeCredentials() {
        var removeSuccessful: Bool = KeychainWrapper.standard.removeObject(forKey: "userPassword")
        print("Password removal was successful: \(removeSuccessful)")
        removeSuccessful = KeychainWrapper.standard.removeObject(forKey: "userName")
        print("Username removal was successful: \(removeSuccessful)")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //homeTabBarController = tabBarController as? HomeTabBarController
        //xmppController = homeTabBarController?.xmppController
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
        /*
        let htbvc = tabBarController as! HomeTabBarController
        xmppController = htbvc.xmppController // this is how to share data between tab controllers - but do I need access to it?
        loggedIn = htbvc.loggedIn
        print("Settings view - Logged in? - \(loggedIn)")
 */
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





