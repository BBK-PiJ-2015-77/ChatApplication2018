//
//  ChatsViewController.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 03/06/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//
//  Key Resources:
//  https://www.youtube.com/watch?v=FgCIRMz_3dE
//  https://medium.com/ios-os-x-development/enable-slide-to-delete-in-uitableview-9311653dfe2

/**
 The ChatsViewController class provides a table showing all the contacts in the user's roster.
 Contacts can be added and removed from the roster from here, affecting what is displayed on screen. When a new message is received, there is a notification shown on screen.
 The user's own name and online status is also displayed
 Provides segues to:
    - AddChatViewController
    - ChatViewController
 **/

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
    private let server = Constants()
    
    // MARK: - Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Log.print("ChatsViewController viewDidLoad() is called", loggingVerbosity: .high)
        homeTabBarController = tabBarController as? HomeTabBarController
        
        // Display spinner to show the user the connection attempt
        waitingToConnect()
        
        initateObservers()
        
        //Create alert view for case if wrong username is entered when adding a contact
        createInvalidJIDAlertController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Log.print("ChatsViewController viewDidAppear() is called", loggingVerbosity: .high)
        
        if xmppController == nil {
            Log.print("ChatsViewController - stream not yet authenticated, no XMPPController pointer yet", loggingVerbosity: .high)
        }
    }
    
    // Used to display to the user that the stream has not yet conencted
    func waitingToConnect() {
        self.userTitle.text = "Connecting..."
        self.connectingIndicator.startAnimating()
    }
    
    func initateObservers() {
        // Only obtain access to the XMPPController once ther is an authenticated stream. This is critical due to the fact that the ChatsViewController is created when the app is launched - the functionality of the class is largely dependent on an authenticated stream. This Observer will create a pointer to the HomeTabBarController's XMPPController. The notification is broadcast by the HomeTabBarController
        NotificationCenter.default.addObserver(self, selector: #selector(connectToXMPPController(notfication:)), name: .streamAuthenticated, object: nil)
        
        // Once the user has logged out, the view will switch back to this ChatsViewController tab. This Observer makes sure that the LoginViewController view is presented. The notification is broadcast by SettingsViewController
        NotificationCenter.default.addObserver(self, selector: #selector(showLoginView(notfication:)), name: .loggedOut, object: nil)
    }
    
    // Creates an alert view if wrong username is entered when adding a contact
    func createInvalidJIDAlertController() {
        self.invalidJIDAlertController = UIAlertController(title: "Invalid username", message: "The username entered does not exist", preferredStyle: .alert)
        self.defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        invalidJIDAlertController?.addAction(defaultAction!)
    }

    // MARK: - UITableView setup
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return jidArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatsTableViewCell
        cell.nameLabel.text = jidArray[indexPath.row].user
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = chatsTableView.cellForRow(at: indexPath) as! ChatsTableViewCell
        cell.newMessage.text = ""
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
        // When a username is selected on the table, provide the ChatViewController with access to the selected JID and the XMPPController
        let destinationNavigationController = segue.destination as! UINavigationController
        let chatVC: ChatViewController = destinationNavigationController.topViewController as! ChatViewController
        chatVC.recipientJID = jidArray[(chatsTableView.indexPathForSelectedRow?.row)!]
        chatVC.xmppController = self.xmppController
    }
    
    // Creates an 'AddChatViewController' - effectively ahows a pop-up box for the user to enter a new user they wish to add to their roster
    @IBAction func addChat(_ sender: Any) {
        let addChatVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "addChatPopUp") as! AddChatViewController
        self.addChildViewController(addChatVC)
        addChatVC.view.frame = self.view.frame
        self.view.addSubview(addChatVC.view)
        addChatVC.delegate = self
        addChatVC.didMove(toParentViewController: self)
    }
    
    @objc func showLoginView(notfication: NSNotification) {
        jidArray = []
        homeTabBarController?.performSegue(withIdentifier: "loginView", sender: nil)
    }
    
    @objc func connectToXMPPController(notfication: NSNotification) {
        Log.print("ChatsViewController - observer initiated connectToXMPPController", loggingVerbosity: .high)
        connectToXMPPController()
    }
    
    func connectToXMPPController() {
        self.connectingIndicator.stopAnimating()
        xmppController = homeTabBarController?.xmppController
        Log.print("ChatsViewController - \(xmppController?.userJID.user)'s XMPPController connected", loggingVerbosity: .high)
        
        // Update username on display
        userTitle.text = xmppController?.xmppStream?.myJID?.user
        
        // Update user status on display
        if (self.xmppController?.xmppStream?.isConnected)! { //
            displayStatus.text = "online"
        } else {
            displayStatus.text = "offline"
        }
        
        self.xmppController?.xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppController?.xmppRoster?.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        // There is a delay when receiving the roster from the server. If it has been received, the table will update. If it has not yet been received, the table will be updated with the XMPPRoster delegate methods when the roster has finished populating
        if (self.xmppController?.xmppRoster?.hasRoster)! {
            Log.print("ChatsViewController - connectToXMPPController called updateChatsTable", loggingVerbosity: .high)
            updateChatsTable()
        }
        
    }
    
    // Adds all JIDs from roster storage to the tableview
    func updateChatsTable() {
        Log.print("Buddy IDs:", loggingVerbosity: .high)
        if self.xmppController != nil {
            let jids = xmppController?.xmppRosterStorage?.jids(for: (self.xmppController?.xmppStream)!)
            for jid in jids! {
                Log.print(jid.full, loggingVerbosity: .high)
                if !jidArray.contains(jid) {
                    jidArray.append(jid.bareJID)
                }
            }
            self.chatsTableView.reloadData()
        }
    }
    
    func newMessageAlert(fromUser: String) {
        Log.print("ChatsViewController - iterating through ChatsTableView\n\(fromUser)\n", loggingVerbosity: .high)
        for cell in self.chatsTableView.visibleCells as! [ChatsTableViewCell] {
            print("Cell: \(cell.nameLabel.text!), From: \(fromUser)")
            if cell.nameLabel.text! == fromUser {
                cell.newMessage.text = "New Message"
            }
        }
        Log.print("ChatsViewController - \(fromUser) called updateChatsTable", loggingVerbosity: .high)
        updateChatsTable()
    }
    
}

extension ChatsViewController: AddChatViewControllerDelegate {
    
    func addContact(contactJID: String) {

        let newContactString = contactJID + "@" + server.getAddress()
        
        guard let newContactJID = XMPPJID(string: newContactString) else {
            present(invalidJIDAlertController!, animated: true, completion: nil)
            return
        }
        
        self.xmppController?.xmppRoster?.addUser(newContactJID, withNickname: contactJID, groups: nil, subscribeToPresence: true)
        addUserToTable(user: newContactJID)
    }
    
    func addUserToTable(user: XMPPJID) {
        if !jidArray.contains(user) {
            self.jidArray.append(user)
            Log.print("ChatsViewController - adding \(user) to table", loggingVerbosity: .high)
            updateChatsTable()
        }
    }
    
}

extension ChatsViewController: XMPPStreamDelegate {
    
    
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        
        Log.print("ChatsViewController - message received from: \(message.from!.bareJID)", loggingVerbosity: .high)

        // The server can send messages to users (e.g. a welcome message), so the address needs to be checked it's not coming from the server
        if message.from?.bare != server.getAddress() {
            // add sender to the table. If the user already exists in the table, they will not be added. Unknown users will also be added to the roster, but this is handled by the XMPPController, to make sure that this occurs when the ChatsViewController is not active.
            addUserToTable(user: message.from!.bareJID)
            // display new message alert
            newMessageAlert(fromUser: (message.from?.user)!)
        }
        
    }

}

extension ChatsViewController: XMPPRosterDelegate {
    
    func xmppRosterDidEndPopulating(_ sender: XMPPRoster) {
        Log.print("XMPPRosterDelegate called updateChatsTable", loggingVerbosity: .high)
        updateChatsTable()
    }
    
}



