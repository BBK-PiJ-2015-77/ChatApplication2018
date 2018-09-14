//
//  XMPPMessageTests.swift
//  ChatApplication2018Tests
//
//  Created by Thomas McGarry on 14/09/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import XCTest
import XMPPFramework
import SwiftKeychainWrapper
@testable import ChatApplication2018

class XMPPMessageTests: XCTestCase, XMPPStreamDelegate {
    
    var xmppController: XMPPController?
    let validJID = "testuser2@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com"
    let validPassword = "password2"
    
    override func setUp() {
        super.setUp()
        initiateXMPPController()
    }
    
    override func tearDown() {
        //delete username and password
        var removeSuccessful: Bool = KeychainWrapper.standard.removeObject(forKey: "userPassword")
        removeSuccessful = KeychainWrapper.standard.removeObject(forKey: "userName")
        
        if xmppController != nil {
            xmppController?.disconnect()
            print("Disconnected in teardown")
        }
        xmppController = nil
        usleep(200000)
        super.tearDown()
    }
    

    func initiateXMPPController() {
        do {
            try xmppController = XMPPController(userJIDString: validJID, password: validPassword)
        } catch {
            print("Something went wrong")
        }
        
        self.xmppController?.xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
        //self.xmppController.xmppRoster?.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppController?.connect()
    }
    
    var messageSentExpectation: XCTestExpectation? = nil
    var xmppMessage: XMPPMessage? = nil
    var messageSent: String? = nil
    
    func testSendMessage() {
        let recipient = XMPPJID(string: "abc1@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com")
        self.xmppMessage = XMPPMessage(type: "chat", to: recipient)
        let message = "Test message"
        xmppMessage?.addBody(message)
        
        self.messageSentExpectation = expectation(description: "Message Sent")
        waitForExpectations(timeout: 5, handler: nil)
        //print("messages sent \(messageSent)")
        XCTAssertTrue(messageSent == message)
    }
    
    // MARK: - Delegate Implementations
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        self.xmppController?.xmppStream?.send(xmppMessage!)
    }
    
    func xmppStream(_ sender: XMPPStream, didSend message: XMPPMessage) {
        self.messageSent = message.body!
        self.messageSentExpectation?.fulfill()
    }
    
}
