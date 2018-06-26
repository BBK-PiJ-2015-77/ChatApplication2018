//
//  LoginViewController.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 28/05/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import UIKit
import XMPPFramework

class LoginViewController: UIViewController {
    
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    //@IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    weak var delegate: LoginViewControllerDelegate?
    //var awsServer: String = "ec2-35-177-34-255.eu-west-2.compute.amazonaws.com"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func logInAction(_ sender: Any) {

        if (self.loginTextField.text?.isEmpty)!
        || (self.passwordTextField.text?.isEmpty)!{
            self.errorLabel.text = "Something is missing or wrong!"
            return
        }
        
        let jID: String = self.loginTextField.text! + "@" + Constants.Server.address
        //Test
        print(jID)
        
        guard let _ = XMPPJID(string: jID) else {
            self.errorLabel.text = "Username is not a jid!"
            return
        }
        
        self.delegate?.didTouchLogIn(sender: self, userJID: jID, userPassword: self.passwordTextField.text!)
        //Test
        print("got here4")

    }
    
    func showErrorMessage(message: String) {
        self.errorLabel.text = message
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

protocol LoginViewControllerDelegate: class {
    func didTouchLogIn(sender: LoginViewController, userJID: String, userPassword: String)
    //func autoLogIn(userJID: String, userPassword: String)
    //func checkLogin() -> Bool
}
