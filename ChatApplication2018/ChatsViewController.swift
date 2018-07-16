//
//  ChatsViewController.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 03/06/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import UIKit

class ChatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var userTitle: UILabel!
    @IBOutlet weak var displayStatus: UILabel!
    
    var xmppController: XMPPController?
    var homeTabBarController: HomeTabBarController?
    var chatArray = ["Tom", "Dick", "Harry"]

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! ChatTableViewCell
        cell.nameLabel.text = chatArray[indexPath.row]
        return cell
    }
    
    @IBAction func addChat(_ sender: Any) {
        //tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    func chatList() {
        
        let jids = xmppController?.xmppRosterStorage?.jids(for: xmppController?.xmppStream)
        print("JID list: \(jids)")
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
        
        userTitle.text = xmppController?.xmppStream?.myJID.user
        displayStatus.text = "online"
        
        print("Chats view controller's xmppcontroller jid: \(xmppController?.xmppStream?.myJID.full() ?? defaultUsername)")
        print("Chats view controller's xmppcontroller status: \(xmppController?.xmppStream?.myPresence.description ?? defaultStatus)")
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

