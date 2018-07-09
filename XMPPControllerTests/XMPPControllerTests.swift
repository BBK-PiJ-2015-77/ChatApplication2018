//
//  XMPPControllerTests.swift
//  XMPPControllerTests
//
//  Created by Thomas McGarry on 02/07/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import XCTest
import XMPPFramework
import SwiftKeychainWrapper
@testable import ChatApplication2018

class XMPPControllerTests: XCTestCase {
    
    var classUnderTest: XMPPController!
    var mockXMPPController: MockXMPPController!
    var expectation: XCTestExpectation? = nil
    
    let userJID = "testuser2@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com"
    let userPassword = "password2"
    
    //try self.xmppController = XMPPController(userJIDString: userJID,
    //password: userPassword)
    //print("where am i?")
    //self.xmppController.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
    //print("got here9b")
    //self.xmppController.connect()
    
    class MockXMPPController: XMPPController {
        var didReceiveErrorCount = 0
        var receivedDidNotAuthenticateError = 0
        
        override func xmppStream(_ sender: XMPPStream!, didReceiveError error: DDXMLElement!) {
            super .xmppStream(sender, didNotAuthenticate: error)
            didReceiveErrorCount += 1
        }
        /*
        override func xmppStream(_ sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
            super .xmppStream(sender, didNotAuthenticate: error)
            receivedDidNotAuthenticateError += 1
        }
        */

    }
    
    
    /*
     func xmppStream(_ sender: XMPPStream!, didReceiveError error: DDXMLElement!) {
     print("username or resource is not allowed to create a session")
     }
     
     func xmppStream(_ sender: XMPPStream!, didNotAuthenticate error: DDXMLElement!) {
     print("Stream: Fail to Authenticate")
     }
     
     func xmppStreamDidDisconnect(_ sender: XMPPStream!, withError error: Error!) {
     print("Stream: Disonnected")
     }
 */
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        var removeSuccessful: Bool = KeychainWrapper.standard.removeObject(forKey: "userPassword")
        removeSuccessful = KeychainWrapper.standard.removeObject(forKey: "userName")
        if mockXMPPController != nil {
            disconnect()
        }
        mockXMPPController = nil
        super.tearDown()
    }
    
    
    func initiateMockXMPPController(id: String = "testuser2@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com", password: String = "password2") {
        do {
            try mockXMPPController = MockXMPPController(userJIDString: id, password: password)
        } catch {
            print("Something went wrong")
        }
    }
    
    func disconnect() {
        mockXMPPController.xmppRoster.deactivate()
        mockXMPPController.xmppRoster = nil
        if mockXMPPController.xmppStream.isConnected() {
            print("Disconnected!")
            mockXMPPController.disconnect()
        }
    }

    
    func testXMPPStreamConfig() {
        //given a userJID & userPassword
        
        //when stream created
        initiateMockXMPPController()
        
        //check credentials are as expected
        let hostNameA = "ec2-35-177-34-255.eu-west-2.compute.amazonaws.com"
        let hostPortA = UInt16(5222)
        let myJIDA = XMPPJID(string: userJID)

        let hostName = mockXMPPController.xmppStream.hostName
        let hostPort = mockXMPPController.xmppStream.hostPort
        let myJID = mockXMPPController.xmppStream.myJID
        
        XCTAssertEqual(hostNameA, hostName)
        XCTAssertEqual(hostPortA, hostPort)
        XCTAssertEqual(myJIDA, myJID)
    }

    
    func testXMPPStreamConnects() {
        //given valid credentials
        initiateMockXMPPController()
        mockXMPPController.connect()
        
        //XMPPStream connects successfully
        //Need to allow some time for connection before asserting whether connection is succesful or not
        
        expectation = expectation(description: "Stream connects")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            XCTAssertTrue(self.mockXMPPController.xmppStream.isConnected())
            self.expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    
    func testXMPPStreamAuthenticates() {
        //given valid credentials
        initiateMockXMPPController()
        mockXMPPController.connect()
        
        //XMPPStream authenticates successfully
        //Need to allow some time for connection before asserting whether connection authorises or not
        
        expectation = expectation(description: "Stream connects")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            XCTAssertTrue(self.mockXMPPController.xmppStream.isAuthenticated())
            self.expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    
    func testNoUserIDThrowsError() {
        //given no username
        let wrongUserID = ""
        
        //when an XMPPController is initiated
        //Throws an error
        XCTAssertThrowsError(try MockXMPPController(userJIDString: wrongUserID, password: userPassword))
    }
    
    
    func testWrongUserIDFailsAuthorization() {
        //given the wrong username
        let wrongUserID = "abc"
        
        //when an XMPPController is initiated
        initiateMockXMPPController(id: wrongUserID)
        mockXMPPController.connect()
        
        //Authentication fails
        
        expectation = expectation(description: "Stream connects")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            XCTAssertFalse(self.mockXMPPController.xmppStream.isAuthenticating() && self.mockXMPPController.xmppStream.isAuthenticated())
            self.expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testRosterActive() {
        //given a stream setup/connection
        initiateMockXMPPController()
        mockXMPPController.connect()
        
        //check roster is created
        XCTAssertTrue(mockXMPPController.xmppRoster.hasRoster)
        
    }
    
    
}

