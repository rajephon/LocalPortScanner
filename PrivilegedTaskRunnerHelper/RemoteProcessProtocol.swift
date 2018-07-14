//
//  RemoteProcessProtocol.swift
//  PortScanner
//
//  Created by Chanwoo Noh on 2018. 7. 12..
//  Copyright © 2018년 Chanwoo Noh. All rights reserved.
//

import Foundation

struct HelperConstants {
    static let machServiceName = "so.yoko.PrivilegedTaskRunnerHelper"
}

/// Protocol with inter process method invocation methods that ProcessHelper supports
/// Because communication over XPC is asynchronous, all methods in the protocol must have a return type of void
@objc(RemoteProcessProtocol)
protocol RemoteProcessProtocol {
    func getVersion(reply: (String) -> Void)
    func runCommand(path: String, authData: NSData?, reply: @escaping (String) -> Void)
    func runCommand(path: String, reply: @escaping (String) -> Void)
}
