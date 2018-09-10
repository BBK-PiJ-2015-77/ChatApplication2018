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
    @IBOutlet weak var jidTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
    }
    
    @IBAction func addUser(_ sender: Any) {
        
        if (self.jidTextField.text?.isEmpty)!{
            self.errorLabel.text = "Please enter an address"
            return
        }
        
        let jidString = jidTextField.text!
        self.delegate?.addContact(contactJID: jidString)
        self.view.removeFromSuperview()
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.view.removeFromSuperview()
    }

}

protocol AddChatViewControllerDelegate: class {
    func addContact(contactJID: String)
}
