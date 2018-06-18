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

    
    @IBAction func logoutAction(_ sender: Any) {
        removeCredentials()
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
