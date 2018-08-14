//
//  ChatViewControllerTests.swift
//  ChatApplication2018Tests
//
//  Created by Thomas McGarry on 13/08/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import XCTest
import XMPPFramework
@testable import ChatApplication2018

class ChatViewControllerTests: XCTestCase {
    
    var rootViewController: ChatViewController!
    var topLevelUIUtilities: TopLevelUIUtilities<ChatViewController>!
    var xmppController: XMPPController!
    var jid: XMPPJID!
    var expectation: XCTestExpectation? = nil
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        initiateXMPPController()
        //let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //let chatViewController = storyboard.instantiateInitialViewController() as! ChatViewController
        let chatViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chatVC") as! ChatViewController
        chatViewController.xmppController = self.xmppController
        jid = XMPPJID(string: "test2@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com")
        chatViewController.recipientJID = jid
        rootViewController = chatViewController
        topLevelUIUtilities = TopLevelUIUtilities<ChatViewController>()
        topLevelUIUtilities.setupTopLevelUI(withViewController: rootViewController)
    }
    
    override func tearDown() {
        xmppController.xmppStream?.disconnect()
        xmppController = nil
        jid = nil
        rootViewController = nil
        topLevelUIUtilities.tearDownTopLevelUI()
        topLevelUIUtilities = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func initiateXMPPController() {
        do {
            try xmppController = XMPPController(userJIDString: "test1@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com", password: "password1")
        } catch {
            print("Something went wrong")
        }
        self.xmppController?.xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
    }
    
    func testSendMessage() {
        expectation = expectation(description: "Message sent on stream")
        rootViewController.sendMessage(message: "Test Message")
        
        let xmlString = """
        <message xmlns='jabber:client'
        to='test2@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com'
        type='chat'>
        <body>Test Message Option2</body>
        </message>
        """
        let message = try! XMPPMessage(name: xmlString)
        rootViewController.xmppController?.xmppStream?.send(message)
        print("Test send message")
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    
    
}

extension ChatViewControllerTests: XMPPStreamDelegate {
    func xmppStream(_ sender: XMPPStream, didSend message: XMPPMessage) {
        print("Message sent")
        expectation?.fulfill()
    }
}


/**
 ChatViewController
 - Check all wired up correctly and data is passed to it
 - Presence and last known active are shown
 - Messages are sent/received and displayed
 - Message history retrieved from server
 **/
