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
        //cell.newMessage.text = ""
        //cell.setChatsCellLabels(name: jidArray[indexPath.row].user!, newMessage: false)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatsTableViewCell
        //cell.newMessage.text = ""
        let cell = chatsTableView.cellForRow(at: indexPath) as! ChatsTableViewCell
        cell.newMessage.text = ""
        performSegue(withIdentifier: "chatsToChat", sender: self)
        chatsTableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            self.xmppController?.xmppRoster?.removeUser(self.jidArray[indexPath.row])
            //self.xmppController?.xmppRoster.remove
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
                print(jid.full)
                
                
                
                if !jidArray.contains(jid) {
                    jidArray.append(jid.bareJID)
                }
            }
            self.chatsTableView.reloadData()
        }
    }
    
    func newMessageAlert(fromUser: String, sender: String) {
        print("Iterating through ChatsTableView\n\(fromUser)\n")
        for cell in self.chatsTableView.visibleCells as! [ChatsTableViewCell] {
            //cell as! ChatsTableViewCell
            print("Cell: \(cell.nameLabel.text!), From: \(fromUser)")
            if cell.nameLabel.text! == fromUser {
                print("there should be a new message notification!!!!")
                cell.newMessage.text = "New Message"
            }
        }
        print("\(sender) called updateChatsTable")
        updateChatsTable()
    }

}

extension ChatsViewController: AddChatViewControllerDelegate {
    
    func addContact(contactJID: String) {

        let newContactString = contactJID + "@" + Constants.Server.address
        
        //This doesn't really add anything
        guard let newContactJID = XMPPJID(string: newContactString) else {
            present(invalidJIDAlertController!, animated: true, completion: nil)
            return
        }
        
        //self.xmppController?.xmppRoster?.addUser(newContactJID, withNickname: contactNickName)
        self.xmppController?.xmppRoster?.addUser(newContactJID, withNickname: contactJID, groups: nil, subscribeToPresence: true)
        addUserToTable(user: newContactJID)
    }
    
    func addUserToTable(user: XMPPJID) {
        if !jidArray.contains(user) {
            self.jidArray.append(user)
            print("Adding \(user)")
            updateChatsTable()
        }
    }
}

extension ChatsViewController: XMPPStreamDelegate {
    
    
    //Do I need to do this?
    /**
    func xmppStream(_ sender: XMPPStream, didReceive iq: XMPPIQ) -> Bool {
        if iq.type == "result" && (self.xmppController?.xmppRoster?.hasRoster)! {
            print("XMPPStreamDelegate called updateChatsTable")
            print("\(iq.childElement)")
            updateChatsTable()
        }
        //should respond to a 'get' or 'set' iq with a 'result' or 'error' iq?
        return true
    }
    **/
    
    //Automatically accept presence requests. Move to XMPPController
    /**
    func xmppStream(_ sender: XMPPStream, didReceive presence: XMPPPresence) {
        //Need to move to XMPPController
        print("ChatsView Controller XMPPStreamDelegate didReceieve presence")
        
        
        if presence.type == "subscribe" {
            self.xmppController?.xmppRoster?.acceptPresenceSubscriptionRequest(from: presence.from!, andAddToRoster: false)
        }
        
    }
    **/
    
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        
        //The following process is done for new messages both from known & unknown users
        /*
        print("Iterating through ChatsTableView")
        for cell in self.chatsTableView.visibleCells as! [ChatsTableViewCell] {
            //cell as! ChatsTableViewCell
            print("Cell: \(cell.nameLabel.text!), From: \(message.from!.user!)")
            if cell.nameLabel.text! == message.from!.user! {
                cell.newMessage.text = "New Message"
            }
        }
        updateChatsTable()
        */
        
        
        // When a message is received from an unknown user, the XMPPController is responsible for adding the new JID to the Roster, so whenever the roster is loaded going forward, the new user will be included. To add the user to the immediate session, it is added directly to jidArray
        addUserToTable(user: message.from!.bareJID)
        newMessageAlert(fromUser: (message.from?.user)!, sender: "didReceiveMessage")
    }

}

extension ChatsViewController: XMPPRosterDelegate {
    func xmppRosterDidEndPopulating(_ sender: XMPPRoster) {
        print("XMPPRosterDelegate called updateChatsTable")
        updateChatsTable()
    }
    
    // When a new message is received from an unknown JID, the XMPPController will add the user to the Roster and request presence subscription. The below will make sure that the chatsTable is updated to show the new user in this circumstance.
    /**
    func xmppRoster(_ sender: XMPPRoster, didReceiveRosterItem item: DDXMLElement) {
        print("didReceiveRosterItem called updateChatsTable")
        updateChatsTable()
        //This is overkill as received too often. also doesn't allow new message to be displayed
        //updateChatsTable()
        print("Received roster item")
        print("item attribute? \(item.attributeBoolValue(forName: "item"))")
        print("iq attribute? \(item.attributeBoolValue(forName: "iq"))")
        print("name attribute? \(item.attributeStringValue(forName: "name"))")
        
        let subscription: String? = item.attributeStringValue(forName: "subscription")
        let user: String? = item.attributeStringValue(forName: "name")
        if subscription == "to" {
            print("received roster item from: \(user!)")
            newMessageAlert(fromUser: user!, sender: "didReceiveRosterItem")
        }
        /*
         <iq xmlns="jabber:client"
            from="test1@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com"
            to="test1@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com/1768755405915782382635304709474747540955648445274620593355"
            id="push10676426508913265979" type="set">
            <query xmlns="jabber:iq:roster">
                <item ask="subscribe" subscription="none" name="test2" jid="test2@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com"/>
            </query>
         </iq>
        */
        
    }
    **/
    
    
}



