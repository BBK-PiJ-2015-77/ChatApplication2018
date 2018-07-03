//
//  XMPPControllerTests.swift
//  XMPPControllerTests
//
//  Created by Thomas McGarry on 02/07/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import XCTest
import XMPPFramework
@testable import ChatApplication2018

class XMPPControllerTests: XCTestCase {
    
    var classUnderTest: XMPPController!
    let userJID = "testuser2@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com"
    let userPassword = "password2"
    
    //try self.xmppController = XMPPController(userJIDString: userJID,
    //password: userPassword)
    //print("where am i?")
    //self.xmppController.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
    //print("got here9b")
    //self.xmppController.connect()
    
    override func setUp() {
        super.setUp()
        
        do {
            try classUnderTest = XMPPController(userJIDString: userJID, password: userPassword)
        } catch {
            print("Something went wrong")
        }
    }
    
    override func tearDown() {
        classUnderTest = nil
        super.tearDown()
    }
    
    func testXMPPStreamConfig() {

        let hostNameA = "ec2-35-177-34-255.eu-west-2.compute.amazonaws.com"
        let hostPortA = UInt16(5222)
        let myJIDA = XMPPJID(string: userJID)

        let hostName = classUnderTest.xmppStream.hostName
        let hostPort = classUnderTest.xmppStream.hostPort
        let myJID = classUnderTest.xmppStream.myJID
        
        XCTAssertEqual(hostNameA, hostName)
        XCTAssertEqual(hostPortA, hostPort)
        XCTAssertEqual(myJIDA, myJID)
    }
    
    
    
}
