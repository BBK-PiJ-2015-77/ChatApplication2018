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
    
    var xmppController: XMPPController?
    var homeTabBarController: HomeTabBarController?
    var jidArray: [XMPPJID] = []
    var chatSelectionIndex = 0
    

    // MARK: - UITableView setup
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //this is how you send data to the segue destination
        let destinationNavigationController = segue.destination as! UINavigationController
        let chatVC: ChatViewController = destinationNavigationController.topViewController as! ChatViewController
        chatVC.recipientJID = jidArray[(chatsTableView.indexPathForSelectedRow?.row)!]
        chatVC.xmppController = self.xmppController
    }
    
    @IBAction func addChat(_ sender: Any) {
        //tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //the model isn't set up when this view first loads
        //why not?
        //homeTabBarController = tabBarController as? HomeTabBarController
        //xmppController = homeTabBarController?.xmppController
        
        // Need to move the data set up out of viewDidAppear and into viewDidLoad so that it is not retrieving this data each time the view appears. Can a buffer be set up while establishing a connection?
        
        homeTabBarController = tabBarController as? HomeTabBarController
        if (homeTabBarController?.loggedIn)! {
            print("logged in: \(homeTabBarController?.loggedIn)")
            connectToXMPPController()
        }
        
        //try and load from viewdidappear. have a method in viwdidload that checks if connected. if not, tries to connect
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //if we are logged in and haven't yet connected to the XMPPController
        if (homeTabBarController?.loggedIn)! && self.xmppController == nil {
            connectToXMPPController()
        }
        
    }
    
    func connectToXMPPController() {
        //if self.xmppController == nil {
        xmppController = homeTabBarController?.xmppController
        //}
        userTitle.text = xmppController?.xmppStream?.myJID?.user
        
        if (self.xmppController?.xmppStream?.isConnected)! {
            displayStatus.text = "online"
        } else {
            displayStatus.text = "offline"
        }
        
        loadChatsTable()
    }
    
    func loadChatsTable() {
        print("Buddy IDs:")
        if self.xmppController != nil {
            let jids = xmppController?.xmppRosterStorage?.jids(for: (xmppController?.xmppStream)!)
            
            //guard let x = y, else
            for jid in jids! {
                print(jid.user ?? "None yet")
                if !jidArray.contains(jid) {
                    jidArray.append(jid)
                }
            }
            self.chatsTableView.reloadData()
        }
    }

}

