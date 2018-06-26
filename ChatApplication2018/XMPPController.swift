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
    
    var xmppStream: XMPPStream
    
    let hostName: String
    let userJID: XMPPJID
    let hostPort: UInt16
    let password: String
    //let presence: XMPPPresence
    
    let xmppRosterStorage: XMPPRosterCoreDataStorage // see framework wiki for coredata details
    var xmppRoster: XMPPRoster!
    
    init(userJIDString: String, hostPort: UInt16 = 5222, password: String) throws {
        guard let userJID = XMPPJID(string: userJIDString) else {
            throw XMPPControllerError.wrongUserID
        }
        
        //Roster Configuration
        xmppRosterStorage = XMPPRosterCoreDataStorage()
        xmppRoster = XMPPRoster(rosterStorage: xmppRosterStorage)
        print(xmppRosterStorage.databaseFileName)
        
        self.hostName = Constants.Server.address
        self.userJID = userJID
        self.hostPort = hostPort
        self.password = password
        
        //Stream Configuration
        self.xmppStream = XMPPStream()
        self.xmppStream.hostName = hostName
        self.xmppStream.hostPort = hostPort
        self.xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicy.allowed
        self.xmppStream.myJID = userJID
        

        //MARK testing presence
        /*
        presence = XMPPPresence()
        self.xmppStream.send(presence)
        //self.xmppStream.myPresence =
        print("Presence: \(presence.intShow) -end-")
        */
        
        super.init()
        
        self.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        //Test
        print("got here7")
        xmppRoster.activate(xmppStream)
        
        //Test
        print("got here8")
    }
    
    func connect() {
        if !self.xmppStream.isDisconnected() {
            return
        }
        
        try! self.xmppStream.connect(withTimeout: XMPPStreamTimeoutNone)
    }
    
    func disconnect() {
        self.xmppStream.disconnect()
    }
    
    //add autheticated login details to keychain
    func saveCredentials(userName: String, password: String) {
        var saveSuccessful: Bool = KeychainWrapper.standard.set(password, forKey: "userPassword")
        print("Password save was successful: \(saveSuccessful)")
        saveSuccessful = KeychainWrapper.standard.set(userName, forKey: "userName")
        print("Username save was successful: \(saveSuccessful)")
    }
    
    /*
    func setPresenceOnline() {
        let presence = XMPPPresence()
        xmppStream.send(presence)
        print("Presence: \(String(describing: presence?.status())) -end-")
    }
    */
}

extension XMPPController: XMPPStreamDelegate {
    
    func xmppStreamDidConnect(_ stream: XMPPStream!) {
        print("Stream: Connected")
        try! stream.authenticate(withPassword: self.password)
    }
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream!) {
        print("Stream: Authenticated")
        saveCredentials(userName: self.userJID.user, password: self.password)
        //MARK testing presence v2
        //setPresenceOnline()
    }
    
    func xmppStream(_ sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
        print("Stream: Fail to Authenticate")
    }
    
    func xmppStreamDidDisconnect(_ sender: XMPPStream!, withError error: Error!) {
        print("Stream: Disonnected")
    }
    
}







