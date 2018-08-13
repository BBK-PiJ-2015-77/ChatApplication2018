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

class XMPPRosterTests: XCTestCase {
    
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
 
}


/**
 Things to test
    - more bits have been added to XMPPControllerTests
    HTBC
    - automatic login
    - changing presence
    LoginViewController (already handled I think)
    RegisterViewController methods
    - Roster is added to chatlist and names appear on cell
    - Can add and delete users from list
    - New messages from new contacts are shown
    
    
 
 **/
