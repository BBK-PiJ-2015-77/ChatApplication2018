//
//  XMPPControllerTestv2.swift
//  ChatApplication2018Tests
//
//  Created by Thomas McGarry on 13/08/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import XCTest
import XMPPFramework
import SwiftKeychainWrapper
@testable import ChatApplication2018


class XMPPControllerTestv2: XCTestCase {
    /**
    var xmppController: XMPPController?
    var expectation: XCTestExpectation?
    
    let userJIDTest = "test1@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com"
    let userPasswordTest = "password1"
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        do {
            try xmppController = XMPPController(userJIDString: userJID, password: userPassword)
        } catch {
            print("Something went wrong")
        }
        self.xmppController?.xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
    }
    
    override func tearDown() {
        if xmppController != nil {
            xmppController?.disconnect()
            print("Disconnected in teardown")
        }
        
        xmppController = nil
        super.tearDown()
    }
    
    class MockXMPPController: XMPPController {
        
    }
    
    func initiateXMPPController(id: String = "test1@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com", password: String = "password1") {
        do {
            try xmppController = XMPPController(userJIDString: id, password: password)
        } catch {
            print("Something went wrong")
        }
    }
    
    func testXMPPStreamConfig() {
        initiateXMPPController()
        expectation = expectation(description: "Connected and credentials are correct")
        //expectation is fulfilled in xmppStreamDidConnect()
        
        //check credentials are as expected
        let hostNameA = "ec2-35-177-34-255.eu-west-2.compute.amazonaws.com"
        let hostPortA = UInt16(5222)
        let myJIDA = XMPPJID(string: userJID)
        
        let hostName = xmppController?.xmppStream?.hostName
        let hostPort = xmppController?.xmppStream?.hostPort
        let myJID = xmppController?.xmppStream?.myJID
        
        XCTAssertEqual(hostNameA, hostName)
        XCTAssertEqual(hostPortA, hostPort)
        XCTAssertEqual(myJIDA, myJID)
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    
    
    
}

extension XMPPControllerTestv2: XMPPStreamDelegate {
    
    func xmppStreamDidConnect(_ sender: XMPPStream) {
        expectation?.fulfill()
    }
    **/
}
