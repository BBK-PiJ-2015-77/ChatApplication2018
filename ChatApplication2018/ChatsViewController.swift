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
    
    /*
    var authenticated = false {
        didSet {
            if authenticated == true {
                connectToXMPPController()
            }
        }
    }
    */
    
    // MARK: - Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("CVC viewdidload")
        homeTabBarController = tabBarController as? HomeTabBarController
        
        // Display spinner to show the user that is something is happening in the background
        waitingToConnect()
        
        //Create alert view if wrong username is entered when adding a contact
        self.invalidJIDAlertController = UIAlertController(title: "Invalid username", message: "The username entered does not exist", preferredStyle: .alert)
        self.defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        invalidJIDAlertController?.addAction(defaultAction!)
        
        // Only obtain access to the XMPPController once we know we have an autheticated stream connected. This Observer will create a pointer to the HomeTabBarController's XMPPController. Broadcast by HomeTabBarController
        NotificationCenter.default.addObserver(self, selector: #selector(connectToXMPPController(notfication:)), name: .streamAuthenticated, object: nil)
        
        // Once the user has logged out, the view will switch back to this ChatsViewController tab. This Observer makes sure that the LoginViewController view is presented. Broadcast by SettingsViewController
        NotificationCenter.default.addObserver(self, selector: #selector(showLoginView(notfication:)), name: .loggedOut, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear is called")
        
        if xmppController == nil {
            print("No HTBC!")
        }
    }
    
    // Used to display to the user that the stream has not yet conencted
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
        cell.dateOfLastMessage.text = "00/00/1900"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "chatsToChat", sender: self)
        chatsTableView.deselectRow(at: indexPath, animated: true)
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
    
    // Creates a pop-up box for the user to enter a new user they wish to add to their list
    
    @IBAction func addChat(_ sender: Any) {
        let addChatVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "addChatPopUp") as! AddChatViewController
        self.addChildViewController(addChatVC)
        addChatVC.view.frame = self.view.frame
        self.view.addSubview(addChatVC.view)
        addChatVC.delegate = self
        addChatVC.didMove(toParentViewController: self)
    }
    
    @objc func showLoginView(notfication: NSNotification) {
        //homeTabBarController = nil
        //print("HTBC is nil as logged out")
        
        //Delete contents of existing jidArray
        jidArray = []
        homeTabBarController?.performSegue(withIdentifier: "loginView", sender: nil)
    }
    
    @objc func connectToXMPPController(notfication: NSNotification) {
        print("Observer initiated connectToXMPPController")
        connectToXMPPController()
    }
    
    func connectToXMPPController() {
        
        self.connectingIndicator.stopAnimating()
        xmppController = homeTabBarController?.xmppController

        if homeTabBarController == nil {
            print("HTBC is nil sow hat can we do")
        }
        print("XMPPController: \(xmppController?.userJID.user)")
        
        userTitle.text = xmppController?.xmppStream?.myJID?.user
        
        if (self.xmppController?.xmppStream?.isConnected)! { //
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
            //let user: XMPPUserCoreDataStorageObject
            
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
        
        //self.xmppController?.xmppRoster?.addUser(newContactJID, withNickname: contactNickName)
        self.xmppController?.xmppRoster?.addUser(newContactJID, withNickname: contactNickName, groups: nil, subscribeToPresence: true)
    }
}

extension ChatsViewController: XMPPStreamDelegate {
    
    
    //Do I need to do this?
    func xmppStream(_ sender: XMPPStream, didReceive iq: XMPPIQ) -> Bool {
        if iq.type == "result" && (self.xmppController?.xmppRoster?.hasRoster)! {
            print("XMPPStreamDelegate called updateChatsTable")
            updateChatsTable()
        }
        //should respond to a 'get' or 'set' iq with a 'result' or 'error' iq?
        return true
    }
    
    //Automatically accept presence requests
    func xmppStream(_ sender: XMPPStream, didReceive presence: XMPPPresence) {
        if presence.type == "subscribe" {
            self.xmppController?.xmppRoster?.acceptPresenceSubscriptionRequest(from: presence.from!, andAddToRoster: false)
        }
    }
    
    //Automatically add user to roster if message received
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        if !jidArray.contains(message.from!) {
            addContact(contactJID: (message.from?.user!)!, contactNickName: (message.from?.user!)!)
        }
        updateChatsTable()
    }

}

extension ChatsViewController: XMPPRosterDelegate {
    func xmppRosterDidEndPopulating(_ sender: XMPPRoster) {
        print("XMPPRosterDelegate called updateChatsTable")
        updateChatsTable()
    }
}



