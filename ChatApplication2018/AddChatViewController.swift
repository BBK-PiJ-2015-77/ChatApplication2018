//
//  AddChatViewController.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 02/08/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import UIKit

class AddChatViewController: UIViewController {

    weak var delegate: AddChatViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
    }

    @IBOutlet weak var jidTextField: UITextField!
    //@IBOutlet weak var nickNameTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addUser(_ sender: Any) {
        
        if (self.jidTextField.text?.isEmpty)!{
            self.errorLabel.text = "Please enter an address"
            return
        }
        
        let jidString = jidTextField.text!
        
        /**
        let nickNameString: String
        if (nickNameTextField.text?.isEmpty)! {
            nickNameString = jidString
        } else {
            nickNameString = nickNameTextField.text!
        }
        **/
        
        self.delegate?.addContact(contactJID: jidString)
        self.view.removeFromSuperview()
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.view.removeFromSuperview()
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*
         if segue.identifier == "loginView" {
         let viewController = segue.destination as! LoginViewController
         viewController.delegate = self
         }
        */
    }

}

protocol AddChatViewControllerDelegate: class {
    func addContact(contactJID: String)
}
