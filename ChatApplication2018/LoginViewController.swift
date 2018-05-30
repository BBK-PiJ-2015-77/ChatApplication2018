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
    var awsServer: String = "ec2-35-177-34-255.eu-west-2.compute.amazonaws.com"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func logInAction(_ sender: Any) {
        //First commit
        //Test
        print("got here1")
        if (self.loginTextField.text?.isEmpty)!
        || (self.passwordTextField.text?.isEmpty)!{
            self.errorLabel.text = "Something is missing or wrong!"
            return
        }
        //Test
        print("got here2")
        
        let jID: String = self.loginTextField.text! + "@" + awsServer
        //Test
        print(jID)
        
        guard let _ = XMPPJID(string: jID) else {
            self.errorLabel.text = "Username is not a jid!"
            return
        }
        //Test
        print("got here3")
        
        self.delegate?.didTouchLogIn(sender: self, userJID: jID, userPassword: self.passwordTextField.text!, server: awsServer)
        //Test
        print("got here4")
        
        //something fundamentally wrong here:
        /*
        if self.delegate?.checkLogin() == true {
            print("got here5")
            let controllerId = (self.delegate?.checkLogin())! ? "Welcome" : "Login";
            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let initViewController: UIViewController = storyboard.instantiateViewController(withIdentifier: controllerId) as UIViewController
            self.present(initViewController, animated: true, completion: nil)
        }
        */
        //let controllerId = (self.delegate?.checkLogin())! ? "Welcome" : "Login";
        
 
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
    func didTouchLogIn(sender: LoginViewController, userJID: String, userPassword: String, server: String)
    //func checkLogin() -> Bool
}
