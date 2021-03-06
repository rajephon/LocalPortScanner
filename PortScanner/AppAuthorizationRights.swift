//
//  AppAuthorizationRights.swift
//  PortScanner
//
//  Created by Chanwoo Noh on 2018. 7. 13..
//  Copyright © 2018년 Chanwoo Noh. All rights reserved.
//

import Foundation

struct AppAuthorizationRights {
    
    // Define all authorization right definitions this application will use (only one for this app)
    static let shellRightName: NSString = "so.yoko.portscanner.runCommand"
    static let shellRightDefaultRule: Dictionary = shellAdminRightsRule
    static let shellRightDescription: CFString = "PrivilegedTaskRunner wants to run the command 'lsof -iTCP -sTCP:LISTEN -n -P'" as CFString
    
    // Set up authorization rules (only one for this app)
    static var shellAdminRightsRule: [String:Any] = ["class" : "user",
                                                     "group" : "admin",
                                                     "timeout" : 0,
                                                     "version" : 1]
}
