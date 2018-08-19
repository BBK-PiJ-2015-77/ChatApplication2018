//
//  XMPPRegister.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 04/08/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import Foundation
import XMPPFramework

import SwiftKeychainWrapper

enum XMPPRegisterError: Error {
    case wrongUserID
}

class XMPPRegister: NSObject {
    
    var xmppStream: XMPPStream?
    
    let hostName: String
    let userJID: XMPPJID
    let hostPort: UInt16
    let password: String
    
    private let server = Constants()
    
    //var loggedIn = false
    
    //var xmppRosterStorage: XMPPRosterStorage?
    //var xmppRoster: XMPPRoster?
    
    //var xmppMessageArchivingStorage: XMPPMessageArchivingCoreDataStorage?
    //var xmppMessageArchiving: XMPPMessageArchiving?
    
    //var presence: XMPPPresence?
    
    init(registerUserJIDString: String, hostPort: UInt16 = 5222, password: String) throws {
        guard let registerUserJID = XMPPJID(string: registerUserJIDString) else {
            throw XMPPControllerError.wrongUserID
        }
        
        self.hostName = server.getAddress()//Constants.Server.address
        self.userJID = registerUserJID
        self.hostPort = hostPort
        self.password = password
        
        //Stream Configuration
        self.xmppStream = XMPPStream()
        self.xmppStream?.hostName = hostName
        self.xmppStream?.hostPort = hostPort
        self.xmppStream?.startTLSPolicy = XMPPStreamStartTLSPolicy.allowed
        self.xmppStream?.myJID = userJID
        
        
        
        
        super.init()
        
        self.xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        

    }
    
    func connect() {
        if (self.xmppStream?.isConnected)!{
            return
        }
        try! self.xmppStream?.connect(withTimeout: XMPPStreamTimeoutNone)
    }
    
    func disconnect() {
        //goOffline()
        //self.xmppRoster!.deactivate()
        //self.xmppMessageArchiving!.deactivate()
        self.xmppStream?.disconnect()
        self.xmppStream = nil
        //self.xmppRoster = nil
        //self.xmppRosterStorage = nil
        //self.xmppMessageArchiving = nil
        //self.xmppMessageArchivingStorage = nil
    }
    
    //add autheticated login details to keychain
    /*
    func saveCredentials(userName: String, password: String) {
        var saveSuccessful: Bool = KeychainWrapper.standard.set(password, forKey: "userPassword")
        print("Password save was successful: \(saveSuccessful)")
        saveSuccessful = KeychainWrapper.standard.set(userName, forKey: "userName")
        print("Username save was successful: \(saveSuccessful)")
    }
 
    
    func goOnline() {
        presence = XMPPPresence(show: .chat)
        xmppStream?.send(presence!)
        print(self.xmppStream?.myPresence?.showType)
    }
    
    func goOffline() {
        presence = XMPPPresence(type: "unavailable")
        xmppStream?.send(presence!)
    }
    */
    
}








