//
//  XMPPMockStream.swift
//  ChatApplication2018Tests
//
//  Created by Thomas McGarry on 14/07/2018.
//  Refactored from the Obj C XMPPMockStream file from Andres Canal on the XMPPFramework
//  https://github.com/robbiehanson/XMPPFramework/blob/157bcd1d595b284b1765ea607eddc3d5d4127d84/Xcode/Testing-Shared/XMPPMockStream.m
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import Foundation
import XMPPFramework

/**
 * This class is used so you can more easily test your XMPPModules
 * to mock responses to received elements.
 */
class XMPPMockStream: XMPPStream {
    
    var elementReceived: ((_ element: XMPPElement?) -> Void)?
    
    override init() {
        super.init()
        //super["state"] = XMPPStreamState.STATE_XMPP_CONNECTED
        //super["state"] = STATE_XMPP_CONNECTED
    }

    /*
    override func isAuthenticated() -> Bool {
        return true
    }
    
    func fakeResponse(_ element: XMLElement?) {
        inject(element)
    }
    
    func fakeMessageResponse(_ message: XMPPMessage?) {
        inject(message)
    }
    
    func fakeIQResponse(_ iq: XMPPIQ?) {
        inject(iq)
    }
    
    
    
    func send(_ element: XMPPElement?) {
        super.send(element)
        elementReceived!(element)
    }
    */
    
}
