//
//  SettingsViewController.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 03/06/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

/**
 The SettingsViewController currently provides a method for th user to logout of the application.
 Any further functionality that can be considered as a 'setting' should be added here.
 **/

import UIKit
import SwiftKeychainWrapper

class SettingsViewController: UIViewController {
    
    @IBAction func logoutAction(_ sender: Any) {
        removeCredentials()
        NotificationCenter.default.post(name: .loggedOut, object: nil)
        //return to homescreen
        self.tabBarController?.selectedIndex = 0
    }
    
    func removeCredentials() {
        var removeSuccessful: Bool = KeychainWrapper.standard.removeObject(forKey: "userPassword")
        print("Password removal was successful: \(removeSuccessful)")
        removeSuccessful = KeychainWrapper.standard.removeObject(forKey: "userName")
        print("Username removal was successful: \(removeSuccessful)")
    }

}





