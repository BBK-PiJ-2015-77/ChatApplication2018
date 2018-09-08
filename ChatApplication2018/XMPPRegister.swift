//
//  XMPPRegister.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 04/08/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//
//  Key Resources:
//  https://www.erlang-solutions.com/blog/build-a-complete-ios-messaging-app-using-xmppframework-part-2.html

/**
 This class is a more restricted version of the XMPPController.swift class. It allows an XMPPStream to be created and for a user to register on the server. The server supports in-band registration.
 **/

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
    
    init(registerUserJIDString: String, hostPort: UInt16 = 5222, password: String) throws {
        guard let registerUserJID = XMPPJID(string: registerUserJIDString) else {
            throw XMPPControllerError.wrongUserID
        }
        
        self.hostName = server.getAddress()
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
        self.xmppStream?.disconnect()
        self.xmppStream = nil
    }
    
}








