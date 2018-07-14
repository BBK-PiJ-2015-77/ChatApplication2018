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
    //let presence: XMPPPresence
    
    var loggedIn = false
    
    var xmppRosterStorage: XMPPRosterStorage?
    var xmppRoster: XMPPRoster?
    
    var presence: XMPPPresence?
    
    init(userJIDString: String, hostPort: UInt16 = 5222, password: String) throws {
        guard let userJID = XMPPJID(string: userJIDString) else {
            throw XMPPControllerError.wrongUserID
        }
        
        //Roster Configuration
        //xmppRosterStorage = XMPPRosterCoreDataStorage()
        //xmppRoster = XMPPRoster(rosterStorage: xmppRosterStorage)
        //print(xmppRosterStorage.databaseFileName)
        
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
        self.xmppRoster = XMPPRoster(rosterStorage: xmppRosterStorage)
        self.xmppRoster?.activate(xmppStream)
        self.xmppRoster?.autoFetchRoster = true
        
        //there is a problem when logging out
        
        super.init()
        
        //Test
        print("got here7")
        
        self.xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppRoster?.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        //Test
        print("got here8")
    }
    
    func connect() {
        if !(self.xmppStream?.isDisconnected())!{
            return
        }
        print("got here9T")
        try! self.xmppStream?.connect(withTimeout: XMPPStreamTimeoutNone)
    }
    
    func disconnect() {
        goOffline()
        self.xmppRoster!.deactivate()
        self.xmppStream?.disconnect()
        self.xmppStream = nil
        self.xmppRoster = nil
        self.xmppRosterStorage = nil
    }
    
    //add autheticated login details to keychain
    func saveCredentials(userName: String, password: String) {
        var saveSuccessful: Bool = KeychainWrapper.standard.set(password, forKey: "userPassword")
        print("Password save was successful: \(saveSuccessful)")
        saveSuccessful = KeychainWrapper.standard.set(userName, forKey: "userName")
        print("Username save was successful: \(saveSuccessful)")
    }
    
    func goOnline() {
        presence = XMPPPresence()
        xmppStream?.send(presence)
    }
    
    func goOffline() {
        presence = XMPPPresence(type: "unavailable")
        xmppStream?.send(presence)
    }
    
}

extension XMPPController: XMPPStreamDelegate {
    
    func xmppStreamDidConnect(_ stream: XMPPStream!) {
        print("Stream: Connected")
        try! stream.authenticate(withPassword: self.password)
    }
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream!) {
        print("Stream: Authenticated")
        saveCredentials(userName: self.userJID.user, password: self.password)
        //print(self.xmppRoster.description)
        goOnline()
    }
    
    func xmppStream(_ sender: XMPPStream!, didReceiveError error: DDXMLElement!) {
        print("username or resource is not allowed to create a session")
    }
    
    func xmppStream(_ sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        print("Stream: Fail to Authenticate")
    }
    
    func xmppStreamDidDisconnect(_ sender: XMPPStream!, withError error: Error!) {
        print("Stream: Disconnected")
    }
    
}







