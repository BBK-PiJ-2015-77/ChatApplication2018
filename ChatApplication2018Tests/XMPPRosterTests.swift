//
//  XMPPRosterTests.swift
//  XMPPControllerTests
//
//  Created by Thomas McGarry on 13/07/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import XCTest
import XMPPFramework
import SwiftKeychainWrapper
@testable import ChatApplication2018

class XMPPRosterTests: XCTestCase, XMPPStreamDelegate, XMPPRosterDelegate {
    
    var xmppController: XMPPController!
    
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
        newUser = nil
        jids = nil
        xmppController = nil
        removeUser = false
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

    var userAddedExpectation: XCTestExpectation? = nil
    var newUser: XMPPJID? = nil
    var jids: [XMPPJID]? = nil
 
    func testUserAdded() {
        
        //given a stream setup & connection
        initiateXMPPController(addDelegate: true)
        xmppController.connect()
        
        //check user is added to roster
        self.newUser = XMPPJID(string: "abc1@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com")
        //user is added in delegate method
        
        self.userAddedExpectation = expectation(description: "User added to roster")
        
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertTrue((jids?.contains(newUser!))!)
    }
    
    var userRemovedExpectation: XCTestExpectation? = nil
    var removeUser = false
    
    func testUserRemoved() {
        //given a stream setup & connection
        initiateXMPPController(addDelegate: true)
        xmppController.connect()
        self.removeUser = true
        
        //add user to roster. If 'newUser' != nil, then user will be added when roster ends populating
        self.newUser = XMPPJID(string: "abc2@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com")
        
        self.userRemovedExpectation = expectation(description: "User removed from roster")
        
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertFalse((jids?.contains(newUser!))!)
    }
    
    // MARK: - Delegate Implementations
    
    /**
     The following are implementations of the XMPPStreamDelegate & XMPPRosterDelegate. These are required to verify that various asynchronous tasks have completed.
     **/
    
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
    
    
    func xmppStream(_ sender: XMPPStream, didSend iq: XMPPIQ) {
        if iq.isSetIQ && iq.child(at: 0)?.name! == "query"
            && (iq.child(at: 0)?.description.range(of: "jabber:iq:roster") != nil) {
                //self.activeRosterExpectation?.fulfill()
                //print("activeRosterExpectation fulfilled")
            self.jids = self.xmppController.xmppRosterStorage?.jids(for: self.xmppController.xmppStream!)
            self.userRemovedExpectation?.fulfill()
        }
    }
    
    
    func xmppRosterDidEndPopulating(_ sender: XMPPRoster) {
        if newUser != nil {
            print("XMPPRosterDelegate: user added")
            self.xmppController.xmppRoster?.addUser(newUser!, withNickname: "abc1")
        }
    }
    
    func xmppRoster(_ sender: XMPPRoster, didReceiveRosterPush iq: XMPPIQ) {
        if !removeUser {
            self.userAddedExpectation?.fulfill()
            self.jids = self.xmppController.xmppRosterStorage?.jids(for: self.xmppController.xmppStream!)
        } else {
            self.xmppController.xmppRoster?.removeUser(self.newUser!)
            
        }
    }
    
}
