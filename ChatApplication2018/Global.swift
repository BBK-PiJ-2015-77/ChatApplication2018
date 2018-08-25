//
//  Global.swift
//  ChatApplication2018
//
//  Created by Thomas McGarry on 25/08/2018.
//  Copyright © 2018 Thomas McGarry. All rights reserved.
//

import Foundation

struct Global {
    /**
     Set the verbosity level of the logging. See 'Log.swift'
        0:    none - No logging, except for crash reports
        1:    low - Low verbosity. All XMPP stanzas are written to the console (XMPPFramework logging)
        2:    high - Highest verbosity. All XMPP stanzas and additional ‘program flow’ comments are written to the console

     If any other integer is used, except for 0, 1, or 2, the logging will be effectively set at level 0.
     **/
    static let verbosity: Int = 2
}
