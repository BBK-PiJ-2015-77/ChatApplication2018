//
//  XMPPController.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 28/05/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import Foundation
import XMPPFramework
import SwiftKeychainWrapper

enum XMPPControllerError: Error {
    case wrongUserID
}

class XMPPController: NSObject {
    
    var xmppStream: XMPPStream?
    
    let hostName: String
    let userJID: XMPPJID
    let hostPort: UInt16
    let password: String
    
    var loggedIn = false
    
    var xmppRosterStorage: XMPPRosterStorage?
    var xmppRoster: XMPPRoster?
    
    var xmppMessageArchivingStorage: XMPPMessageArchivingCoreDataStorage?
    var xmppMessageArchiving: XMPPMessageArchiving?
    
    var xmppReconnect: XMPPReconnect?
    
    var presence: XMPPPresence?
    
    init(userJIDString: String, hostPort: UInt16 = 5222, password: String) throws {
        guard let userJID = XMPPJID(string: userJIDString) else {
            throw XMPPControllerError.wrongUserID
        }
        
        self.hostName = Constants.Server.address
        self.userJID = userJID
        self.hostPort = hostPort
        self.password = password
        
        //Stream Configuration
        self.xmppStream = XMPPStream()
        self.xmppStream?.hostName = hostName
        self.xmppStream?.hostPort = hostPort
        self.xmppStream?.startTLSPolicy = XMPPStreamStartTLSPolicy.allowed
        self.xmppStream?.myJID = userJID
        
        //Roster Configuration
        self.xmppRosterStorage = XMPPRosterCoreDataStorage()
        self.xmppRoster = XMPPRoster(rosterStorage: xmppRosterStorage!)
        self.xmppRoster?.activate(xmppStream!)
        self.xmppRoster?.autoFetchRoster = true
        
        //Will accept all subscription requests instead
        //self.xmppRoster?.autoAcceptKnownPresenceSubscriptionRequests
        
        //Message Archive Configuration
        self.xmppMessageArchivingStorage = XMPPMessageArchivingCoreDataStorage()
        self.xmppMessageArchiving = XMPPMessageArchiving(messageArchivingStorage: xmppMessageArchivingStorage)
        self.xmppMessageArchiving?.activate(xmppStream!)
        
        //Reconnection configuration - enables automatic reconnection to xmpp server when there are accidental disconnections
        self.xmppReconnect = XMPPReconnect()
        self.xmppReconnect?.activate(xmppStream!)
        
        super.init()
        
        //Test
        print("got here7")
        
        self.xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppRoster?.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppMessageArchiving?.addDelegate(self, delegateQueue: DispatchQueue.main)
        //self.xmppReconnect?.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        //Test
        print("got here8")
    }
    
    func connect() {
        if (self.xmppStream?.isConnected)!{
            return
        }
        print("got here9T")
        try! self.xmppStream?.connect(withTimeout: XMPPStreamTimeoutNone)
    }
    
    func disconnect() {
        goOffline()
        self.xmppRoster?.deactivate()
        self.xmppMessageArchiving?.deactivate()
        self.xmppReconnect?.deactivate()
        self.xmppStream?.disconnect()
        self.xmppStream = nil
        self.xmppRoster = nil
        self.xmppRosterStorage = nil
        self.xmppMessageArchiving = nil
        self.xmppMessageArchivingStorage = nil
        self.xmppReconnect = nil
    }
    
    //add autheticated login details to keychain
    func saveCredentials(userName: String, password: String) {
        var saveSuccessful: Bool = KeychainWrapper.standard.set(password, forKey: "userPassword")
        print("Password save was successful: \(saveSuccessful)")
        saveSuccessful = KeychainWrapper.standard.set(userName, forKey: "userName")
        print("Username save was successful: \(saveSuccessful)")
    }
    
    func goOnline() {
        //From framework: After establishing a session, a client SHOULD send initial presence to the server in order to signal its availability for communications. As defined herein, the initial presence stanza (1) MUST possess no 'to' address (signalling that it is meant to be broadcasted by the server on behalf of the client) and (2) MUST possess no 'type' attribute (signalling the user's availability). After sending initial presence, an active resource is said to be an "available resource".
        
        //need to send presence so that the server sends back presence of users on roster who are subscribed
        //Presence type is optional - the mere act of sending a presence stanza infroms that you are online
        presence = XMPPPresence(type: "available")
        xmppStream?.send(presence!)
        print("Presence: \(self.xmppStream?.myPresence?.showType)")
    }
    
    func goOffline() {
        presence = XMPPPresence(type: "unavailable")
        xmppStream?.send(presence!)
    }
    
}

extension XMPPController: XMPPStreamDelegate {
    
    func xmppStreamDidConnect(_ stream: XMPPStream) {
        print("Stream: Connected")
        try! stream.authenticate(withPassword: self.password)
    }
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        print("Stream: Authenticated")
        
        let retrievedPassword: String? = KeychainWrapper.standard.string(forKey: "userPassword")
        let retrievedUserName: String? = KeychainWrapper.standard.string(forKey: "userName")
        let enteredPassword: String? = self.password
        let enteredUserName: String? = self.userJID.bare
        
        //If authenticated with new credentials, overwrite the existing ones
        if enteredUserName != retrievedUserName || enteredPassword != retrievedPassword {
            saveCredentials(userName: self.userJID.bare, password: self.password)
        }
        goOnline()
        
    }
    
    func xmppStream(_ sender: XMPPStream, didReceiveError error: DDXMLElement) {
        print("username or resource is not allowed to create a session")
    }
    
    func xmppStream(_ sender: XMPPStream, didNotAuthenticate error: DDXMLElement) {
        print("Stream: Fail to Authenticate")
    }
    
    func xmppStreamDidDisconnect(_ sender: XMPPStream, withError error: Error?) {
        print("Stream: Disconnected")
    }
    
    //Automatically accept presence requests.
    func xmppStream(_ sender: XMPPStream, didReceive presence: XMPPPresence) {
        print("XMPPController XMPPStreamDelegate didReceieve presence")
        if presence.type == "subscribe" {
            self.xmppRoster?.acceptPresenceSubscriptionRequest(from: presence.from!, andAddToRoster: false)
            if !(self.xmppRosterStorage?.jids(for: self.xmppStream!).contains(presence.from!))! {
                self.xmppRoster?.subscribePresence(toUser: presence.from!)
            }
        }
        
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        // Doesn't work when offline
        // if receive a message from an unkonw ser, automatically add them to roster
        print("XMPPController didReceive XMPPMessage")
        if !(self.xmppRosterStorage?.jids(for: self.xmppStream!).contains(message.from!))! {
            print("XMPPController XMPPMessage JID not on roster")
            self.xmppRoster?.addUser(message.from!, withNickname: message.from?.user, groups: nil, subscribeToPresence: true)
        }
        
        /**
        if !jidArray.contains(message.from!.bareJID) {
            print("Adding new user to chatsTableView")
            addContact(contactJID: (message.from?.user!)!)
            updateChatsTable()
        }
        **/
    }
    
    /*
    func xmppStream(_ sender: XMPPStream, didSend message: XMPPMessage) {
        print("XMPPMessage sent")
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        print("XMPPMessage received")
    }
    */
    
}

extension Notification.Name {
    static let streamAuthenticated = Notification.Name("streamAuthenticated")
    static let loggedIn = Notification.Name("loggedIn")
    static let loggedOut = Notification.Name("loggedOut")
    static let presenceUnavailable = Notification.Name("presenceUnavailable")
    static let presenceAvailable = Notification.Name("presenceAvailable")
    static let newMessage = Notification.Name("newMessage")
}






