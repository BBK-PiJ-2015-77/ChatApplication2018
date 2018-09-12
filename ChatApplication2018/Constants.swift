//
//  Constants.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 18/06/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import Foundation

internal class Constants {
    private let address = "ec2-35-177-34-255.eu-west-2.compute.amazonaws.com"
    //private let address = "ec2-35-178-185-228.eu-west-2.compute.amazonaws.com"
    
    func getAddress() -> String {
        return self.address
    }
}
