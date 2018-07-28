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
    @IBOutlet weak var chatTableView: UITableView!
    
    var xmppController: XMPPController?
    var homeTabBarController: HomeTabBarController?
    var jidArray: [XMPPJID] = []
    var chatSelectionIndex = 0

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return jidArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatTableViewCell
        cell.nameLabel.text = jidArray[indexPath.row].user
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //this is how you send data to the segue destination
        
        let chatVC: ChatViewController = segue.destination as! ChatViewController
        chatVC.recipientJID = jidArray[(chatTableView.indexPathForSelectedRow?.row)!]
        chatVC.xmppController = self.xmppController
        
        /*
        if segue.identifier == "chatsToChat",
        let destination = segue.destination as? ChatViewController,
            chatIndex = chatTableView.indexPathForSelectedRow?.row {
            destination.xmppController = self.xmppController
            destination
        }
        */
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "chatsToChat", sender: self)
    }
    
    @IBAction func addChat(_ sender: Any) {
        //tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    
    //MARK: - CollectionViewDataSource

    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //the model isn't set up when this view first loads
        //homeTabBarController = tabBarController as? HomeTabBarController
        //xmppController = homeTabBarController?.xmppController
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.xmppController == nil {
            homeTabBarController = tabBarController as? HomeTabBarController
            xmppController = homeTabBarController?.xmppController
        }
        //print("JID: \(xmppController?.xmppStream?.myJID.description)")
        let defaultUsername = "Username"
        let defaultStatus = "Status"
        
        userTitle.text = xmppController?.xmppStream?.myJID?.user
        displayStatus.text = "online"
        
        print("Chats view controller's xmppcontroller jid: \(xmppController?.xmppStream?.myJID?.user! ?? defaultUsername)")
        print("Chats view controller's xmppcontroller status: \(xmppController?.xmppStream?.myPresence?.description ?? defaultStatus)")
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
            self.chatTableView.reloadData()
        }
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

