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
        newUser = nil
        jids = nil
        xmppController = nil
        usleep(200000)
        //sleep(5)
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
    
    var removeUser = false
    
    func testUserRemoved() {
        //given a stream setup & connection
        initiateXMPPController(addDelegate: true)
        xmppController.connect()
        
        //add user to roster. If 'newUser' != nil, then user will be added
        self.newUser = XMPPJID(string: "abc2@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com")
        
        self.removeUser = true
        
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
    
    func xmppRosterDidEndPopulating(_ sender: XMPPRoster) {
        if newUser != nil {
            print("XMPPRosterDelegate: user added")
            self.xmppController.xmppRoster?.addUser(newUser!, withNickname: "abc1")
        }
    }
    
    func xmppRoster(_ sender: XMPPRoster, didReceiveRosterPush iq: XMPPIQ) {
        self.userAddedExpectation?.fulfill()
        self.jids = self.xmppController.xmppRosterStorage?.jids(for: self.xmppController.xmppStream!)
        if removeUser {
            self.xmppController.xmppRoster?.removeUser(self.newUser)
        }
    }
    
    /**
    
    var xmppController: XMPPController!
    var expectation: XCTestExpectation? = nil


    
    override func setUp() {
        super.setUp()
        initiateXMPPController()
        xmppController.connect()
    }
    
    override func tearDown() {
        var removeSuccessful: Bool = KeychainWrapper.standard.removeObject(forKey: "userPassword")
        removeSuccessful = KeychainWrapper.standard.removeObject(forKey: "userName")
        if xmppController != nil {
            xmppController.disconnect()
            print("Disconnected in teardown")
        }
        xmppController = nil
        super.tearDown()
    }
    
    func initiateXMPPController() {
        do {
            try xmppController = XMPPController(userJIDString: "testuser2@ec2-35-177-34-255.eu-west-2.compute.amazonaws.com", password: "password2")
        } catch {
            print("Something went wrong initiating the XMPPController")
        }
    }
    
    func performServerOperations(using closure: @escaping () -> Void) {
        // If we are already on the main thread, execute the closure directly
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async(execute: closure)
        }
    }

    
    func testHasRoster() {
        //given valid login connection and connection
        //there is an XMPPRoster
        expectation = expectation(description: "Has Roster")
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            XCTAssertTrue((self.xmppController.xmppRoster?.hasRoster)!)
            self.expectation?.fulfill()
        })
       
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUserAdded() {
        //given this test user
        let jid = XMPPJID(string: "test@example")!
        
        //when added to the roster
        //test user can be accessed
        expectation = expectation(description: "User added")

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            self.xmppController.xmppRoster?.addUser(jid, withNickname: "Test User")
            XCTAssertTrue((self.xmppController.xmppRosterStorage?.userExists(with: jid, xmppStream: self.xmppController.xmppStream!))!)
            self.expectation?.fulfill()
        })
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testUserRemoved() {
        //given this test user
        let jid = XMPPJID(string: "test@example")!
        expectation = expectation(description: "User removed")
        
        
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {

            //check user exists
            XCTAssertTrue((self.xmppController.xmppRosterStorage?.userExists(with: jid, xmppStream: self.xmppController.xmppStream!))!)
            
            self.xmppController.xmppRoster?.removeUser(jid)
            sleep(2)
            //then check user has been removed
            XCTAssertFalse((self.xmppController.xmppRosterStorage?.userExists(with: jid, xmppStream: self.xmppController.xmppStream!))!)
            self.expectation?.fulfill()
        })
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    
    func testUserRemoved2() {
        /*
        let jid = XMPPJID(string: "test@example")
        
        let defaultSession = URLSession(configuation: .default)
        var dataTask: URLSessionDataTask?
        
        if var urlComponents = URLComponents(string: "https://itunes.apple.com/search") {
            urlComponents.query = "media=music&entity=song&term=\(searchTerm)"
            
            guard
        }
        */
    }
 
    **/
}




/**
 Things to test
    - more bits have been added to XMPPControllerTests
    - can I add tests as delegates to get completion notifications?
    HTBC
    - automatic login
    - changing presence
    LoginViewController (already handled I think)
    RegisterViewController methods
    - Roster is added to chatlist and names appear on cell
    - Can add and delete users from list
    - New messages from unknown contacts are shown
    - New messages are labelled as such (only works when on the home screen)
    ChatViewController
    - Check all wired up correctly and data is passed to it
    - Presence and last known active are shown
    - Messages are sent/received and displayed
    - Message history retrieved from server
    
 
 **/
