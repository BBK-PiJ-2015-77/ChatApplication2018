//
//  ChatsViewController.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 03/06/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import UIKit
import XMPPFramework

class ChatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var userTitle: UILabel!
    @IBOutlet weak var displayStatus: UILabel!
    @IBOutlet weak var chatsTableView: UITableView!
    @IBOutlet weak var connectingIndicator: UIActivityIndicatorView!
    
    var xmppController: XMPPController?
    var homeTabBarController: HomeTabBarController?
    var jidArray: [XMPPJID] = []
    
    var invalidJIDAlertController: UIAlertController?
    var defaultAction: UIAlertAction?
    
    //Computed property used to verify there is an authorised connection before attempting to populate the view. Wasn't sure how else to make sure everything was wired up before it was ready
    var authenticated = false {
        didSet {
            if authenticated == true {
                connectToXMPPController()
            }
        }
    }
    
    // MARK: - Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()

        homeTabBarController = tabBarController as? HomeTabBarController
        waitingToConnect()
        
        //Create alert view if wrong username is entered when adding a contact
        self.invalidJIDAlertController = UIAlertController(title: "Invalid username", message: "The username entered does not exist", preferredStyle: .alert)
        self.defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        invalidJIDAlertController?.addAction(defaultAction!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear is called")
        
        //if we are logged in and haven't yet connected to the XMPPController
        if (homeTabBarController?.loggedIn)! && self.xmppController == nil {
            print("viewDidAppear initialisation")
            connectToXMPPController()
        }
        
    }
    
    func waitingToConnect() {
        self.userTitle.text = "Connecting..."
        self.connectingIndicator.startAnimating()
    }

    // MARK: - UITableView setup
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("Number of rows in table: \(jidArray.count)")
        return jidArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatsTableViewCell
        cell.nameLabel.text = jidArray[indexPath.row].user
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "chatsToChat", sender: self)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            self.xmppController?.xmppRoster?.removeUser(self.jidArray[indexPath.row])
            self.jidArray.remove(at: indexPath.row)
            self.chatsTableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        return [delete]
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Send data to ChatViewController
        let destinationNavigationController = segue.destination as! UINavigationController
        let chatVC: ChatViewController = destinationNavigationController.topViewController as! ChatViewController
        chatVC.recipientJID = jidArray[(chatsTableView.indexPathForSelectedRow?.row)!]
        chatVC.xmppController = self.xmppController
    }
    
    @IBAction func addChat(_ sender: Any) {
        //tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        let addChatVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "addChatPopUp") as! AddChatViewController
        self.addChildViewController(addChatVC)
        addChatVC.view.frame = self.view.frame
        self.view.addSubview(addChatVC.view)
        addChatVC.delegate = self
        addChatVC.didMove(toParentViewController: self)
    }
    
    func connectToXMPPController() {
        
        self.connectingIndicator.stopAnimating()
        xmppController = homeTabBarController?.xmppController

        userTitle.text = xmppController?.xmppStream?.myJID?.user
        
        if (self.xmppController?.xmppStream?.isConnected)! {
            displayStatus.text = "online"
        } else {
            displayStatus.text = "offline"
        }
        
        self.xmppController?.xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppController?.xmppRoster?.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        
        
        //If roster has not yet been received - we should not attempt to update the table view. This can be achieved with the XMPPRoster delegate methods when the roster has finished populating
        if (self.xmppController?.xmppRoster?.hasRoster)! {
            print("connectToXMPPController called updateChatsTable")
            updateChatsTable()
        }
        
    }
    
    func updateChatsTable() {
        print("Buddy IDs:")
        if self.xmppController != nil {
            let jids = xmppController?.xmppRosterStorage?.jids(for: (self.xmppController?.xmppStream)!)
            
            if xmppController?.xmppRosterStorage == nil {
                print("We have a problem where there is no roster storage")
            }
            if jids?.count == 0 {
                print("We have a problem where there are no buddys on the list")
            }
            
            for jid in jids! {
                //print(jid.user ?? "None yet")
                print(jid.bare)
                if !jidArray.contains(jid) {
                    jidArray.append(jid)
                }
            }
            self.chatsTableView.reloadData()
        }
    }

}

extension ChatsViewController: AddChatViewControllerDelegate {
    
    func addContact(contactJID: String, contactNickName: String) {

        let newContactString = contactJID + "@" + Constants.Server.address
        
        //This doesn't really add anything
        guard let newContactJID = XMPPJID(string: newContactString) else {
            present(invalidJIDAlertController!, animated: true, completion: nil)
            return
        }
        
        self.xmppController?.xmppRoster?.addUser(newContactJID, withNickname: contactNickName)
    }
}

extension ChatsViewController: XMPPStreamDelegate {
    
    func xmppStream(_ sender: XMPPStream, didReceive iq: XMPPIQ) -> Bool {
        if iq.type == "result" && (self.xmppController?.xmppRoster?.hasRoster)! {
            print("XMPPStreamDelegate called updateChatsTable")
            updateChatsTable()
        }
        //should respond to a 'get' or 'set' iq with a 'result' or 'error' iq?
        return true
    }

}

extension ChatsViewController: XMPPRosterDelegate {
    func xmppRosterDidEndPopulating(_ sender: XMPPRoster) {
        print("XMPPRosterDelegate called updateChatsTable")
        updateChatsTable()
    }
}

