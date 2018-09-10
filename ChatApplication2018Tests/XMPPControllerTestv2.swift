//
//  XMPPControllerTestv2.swift
//  ChatApplication2018Tests
//
//  Created by Thomas McGarry on 13/08/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

/**
 The following tests are to make sure that the implementation of the XMPPFramework is working correctly and that communication with the server is working correctly, not to necessarily test the framework itself.
 **/

import XCTest
import XMPPFramework
import SwiftKeychainWrapper

@testable import ChatApplication2018

class XMPPControllerTestsv2: XCTestCase, XMPPStreamDelegate, XMPPRosterDelegate {
    
    var xmppController: XMPPController!
    var expectation: XCTestExpectation? = nil
    
    let userJID = "testuser2@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com"
    let userPassword = "password2"
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        //delete username and password
        var removeSuccessful: Bool = KeychainWrapper.standard.removeObject(forKey: "userPassword")
        removeSuccessful = KeychainWrapper.standard.removeObject(forKey: "userName")
        
        if xmppController != nil {
            xmppController.disconnect()
            print("Disconnected in teardown")
        }
        
        xmppController = nil
        usleep(200000)
        super.tearDown()
    }
    
    
    func initiateXMPPController(id: String = "testuser2@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com", password: String = "password2", addDelegate: Bool = false) {
        do {
            try xmppController = XMPPController(userJIDString: id, password: password)
        } catch {
            print("Something went wrong")
        }
        
        if addDelegate {
            self.xmppController.xmppStream?.addDelegate(self, delegateQueue: DispatchQueue.main)
            self.xmppController.xmppRoster?.addDelegate(self, delegateQueue: DispatchQueue.main)
        }
    }
    
    // MARK: - XMPPController Tests
    
    func testXMPPStreamConfig() {
        //given a valid userJID & userPassword
        
        //when stream created
        initiateXMPPController()
        
        //check credentials are as expected
        let hostNameA = "ec2-35-177-34-255.eu-west-2.compute.amazonaws.com"
        let hostPortA = UInt16(5222)
        let myJIDA = XMPPJID(string: userJID)
        
        let hostName = xmppController.xmppStream?.hostName
        let hostPort = xmppController.xmppStream?.hostPort
        let myJID = xmppController.xmppStream?.myJID
        
        XCTAssertEqual(hostNameA, hostName)
        XCTAssertEqual(hostPortA, hostPort)
        XCTAssertEqual(myJIDA, myJID)
    }
    
    func testNoUserIDThrowsError() {
        //given no username
        let wrongUserID = ""
        
        //when an XMPPController is initiated
        //Throws an error
        XCTAssertThrowsError(try XMPPController(userJIDString: wrongUserID, password: userPassword))
    }
    
    func testBadFormatIDThrowsError() {
        //given bad username, i.e. will not conform to JID format
        let wrongUserID = "@"
        
        //when an XMPPController is initiated
        //Throws an error
        XCTAssertThrowsError(try XMPPController(userJIDString: wrongUserID, password: userPassword))
    }
    
    var authenticationExpectation: XCTestExpectation? = nil
    
    func testXMPPStreamAuthenticates() {
        self.authenticationExpectation = expectation(description: "Stream authenticates")
        print("Initiating XMPPController")
        initiateXMPPController(addDelegate: true)
        
        self.xmppController.connect()
        
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertTrue((self.xmppController.xmppStream?.isAuthenticated)!)
    }
    
    var failAuthenticationExpectation: XCTestExpectation? = nil
    
    func testWrongUserIDFailsAuthorization() {
        //given the wrong username
        let wrongUserID = "abc"
        
        //when an XMPPController is initiated
        initiateXMPPController(id: wrongUserID, addDelegate: true)
        self.xmppController.connect()
        
        //Authentication fails
        self.failAuthenticationExpectation = expectation(description: "Authorisation fails")
        
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertFalse((self.xmppController.xmppStream?.isAuthenticating)! && (self.xmppController.xmppStream?.isAuthenticated)!)
    }
    
    // MARK: - Roster Tests
    
    var activeRosterExpectation: XCTestExpectation? = nil
    
    func testRosterActive() {
        //given a stream setup/connection
        initiateXMPPController(addDelegate: true)
        xmppController.connect()
        
        //check roster is created
        self.activeRosterExpectation = expectation(description: "Active roster")
        
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertTrue((self.xmppController.xmppRoster?.hasRoster)!)
    }
    
    /**
    var userAddedExpectation: XCTestExpectation? = nil
    
    func testUserAdded() {
        //given a stream setup/connection
        initiateXMPPController(addDelegate: true)
        xmppController.connect()
        
        //make sure there is an active roster before testing
        self.activeRosterExpectation = expectation(description: "Active roster")
        
        
        //check user is added to roster
        let newUser = XMPPJID(string: "abc1@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com")
        self.xmppController.xmppRoster?.addUser(newUser!, withNickname: "abc1")
        print("add user to roster")
        self.userAddedExpectation = expectation(description: "User added to roster")
        
        waitForExpectations(timeout: 5, handler: nil)
        let jids = self.xmppController.xmppRosterStorage?.jids(for: self.xmppController.xmppStream!)
        XCTAssertTrue((jids?.contains(newUser!))!)
    }
    **/
    
    // MARK: - Delegate Implementations
    
    /**
     The following are implementations of the XMPPStreamDelegate & XMPPRosterDelegate. These are required to verify that various asynchronous tasks have completed.
    **/
    
    func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        print("Test Stream: Authenticated")
        self.authenticationExpectation?.fulfill()
    }
    
    func xmppStream(_ sender: XMPPStream, didReceiveError error: DDXMLElement) {
        print("Test Stream: Error received")
        
        if error.children != nil {
            //Unable to autheticate
            if error.child(at: 0)?.name! == "host-unknown" {
                self.failAuthenticationExpectation?.fulfill()
            }
        }
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive iq: XMPPIQ) -> Bool {
        print("Test Stream: IQ received")
        /**
         If a result IQ is received with a 'jabber:iq:roster' query, then there is an active Roster
        **/
        if iq.isResultIQ && iq.child(at: 0)?.name! == "query" {
            if iq.child(at: 0)?.description.range(of: "jabber:iq:roster") != nil {
                self.activeRosterExpectation?.fulfill()
                print("activeRosterExpectation fulfilled")
            }
        }
        return true
    }
    
    func xmppRoster(_ sender: XMPPRoster, didReceiveRosterItem item: DDXMLElement) {
        print("Received roster item")
        
        for attribute in item.attributesAsDictionary() {
            print(attribute)
        }
        //userAddedExpectation?.fulfill()
    }
    
}

