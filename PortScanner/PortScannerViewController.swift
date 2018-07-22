//
//  PortMapperViewController.swift
//  PortMapper
//
//  Created by Chanwoo Noh on 2018. 7. 4..
//  Copyright © 2018년 Chanwoo Noh. All rights reserved.
//

import Cocoa
import Security
import ServiceManagement

class PortScannerViewController: NSViewController {
    var aboutWindow: NSWindow? = nil
    var preferenceWindow: NSWindow? = nil
    @IBOutlet var resultTextView: NSTextView!
    
    // NSXPC
    var connection: NSXPCConnection?
    var authRef: AuthorizationRef?
    
    var logArchive: String = ""
    
    /// Initialize AuthorizationRef, as we need to manage it's lifecycle
    func initAuthorizationRef() {
        // Create an empty AuthorizationRef
        let status = AuthorizationCreate(nil, nil, AuthorizationFlags(), &authRef)
        if (status != OSStatus(errAuthorizationSuccess)) {
            printLog("AppviewController: AuthorizationCreate failed")
            return
        }
    }
    
    func printLog(_ message:String) -> Void {
        NSLog(message)
        if self.resultTextView != nil {
            DispatchQueue.main.async {
                self.resultTextView.string += "\n" + message
            }
        }else {
            logArchive += "\n" + message
        }
    }
    
    /// Free AuthorizationRef, as we need to manage it's lifecycle
    func freeAuthorizationRef() {
        AuthorizationFree(authRef!, AuthorizationFlags.destroyRights)
    }
    
    /// Check if Helper daemon exists
    func checkIfHelperDaemonExists() -> Bool {
        
        var foundAlreadyInstalledDaemon = false
        
        // Daemon path, if it is already installed
        let helperURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/LaunchServices/\(HelperConstants.machServiceName)")
        let helperBundleInfo = CFBundleCopyInfoDictionaryForURL(helperURL as CFURL?)
        if helperBundleInfo != nil {
            foundAlreadyInstalledDaemon = true
        }
        
        return foundAlreadyInstalledDaemon
    }
    
    func installHelperDaemon() {
        // Create authorization reference for the user
        var authRef: AuthorizationRef?
        var authStatus = AuthorizationCreate(nil, nil, [], &authRef)
        
        // Check if the reference is valid
        guard authStatus == errAuthorizationSuccess else {
            printLog("AppviewController: Authorization failed: \(authStatus)")
            return
        }
        
        // Ask user for the admin privileges to install the
        var authItem = AuthorizationItem(name: kSMRightBlessPrivilegedHelper, valueLength: 0, value: nil, flags: 0)
        var authRights = AuthorizationRights(count: 1, items: &authItem)
        let flags: AuthorizationFlags = [[], .interactionAllowed, .extendRights, .preAuthorize]
        authStatus = AuthorizationCreate(&authRights, nil, flags, &authRef)
        
        // Check if the authorization went succesfully
        guard authStatus == errAuthorizationSuccess else {
            printLog("AppviewController: Couldn't obtain admin privileges: \(authStatus)")
            return
        }
        
        // Launch the privileged helper using SMJobBless tool
        var error: Unmanaged<CFError>? = nil
        
        if(SMJobBless(kSMDomainSystemLaunchd, HelperConstants.machServiceName as CFString, authRef, &error) == false) {
            let blessError = error!.takeRetainedValue() as Error
            printLog("AppviewController: Bless Error: \(blessError)")
        } else {
            printLog("AppviewController: \(HelperConstants.machServiceName) installed successfully")
        }
        
        // Release the Authorization Reference
        AuthorizationFree(authRef!, [])
    }
    
    /// Prepare XPC connection for inter process call
    ///
    /// - returns: A reference to the prepared instance variable
    func prepareXPC() -> NSXPCConnection? {
        
        // Check that the connection is valid before trying to do an inter process call to helper
        if(connection==nil) {
            connection = NSXPCConnection(machServiceName: HelperConstants.machServiceName, options: NSXPCConnection.Options.privileged)
            connection?.remoteObjectInterface = NSXPCInterface(with: RemoteProcessProtocol.self)
            connection?.invalidationHandler = {
                self.connection?.invalidationHandler = nil
                OperationQueue.main.addOperation() {
                    self.connection = nil
                    self.printLog("AppviewController: XPC Connection Invalidated")
                }
            }
            connection?.resume()
        }
        
        return connection
    }
    
    /// Compare app's helper version to installed daemon's version and update if necessary
    func checkHelperVersionAndUpdateIfNecessary(callback: @escaping (Bool) -> Void) {
        // Daemon path
        let helperURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/LaunchServices/\(HelperConstants.machServiceName)")
        let helperBundleInfo = CFBundleCopyInfoDictionaryForURL(helperURL as CFURL)
        if helperBundleInfo != nil {
            let helperInfo = helperBundleInfo! as NSDictionary
            let helperVersion = helperInfo["CFBundleVersion"] as! String
            
            printLog("AppviewController: PrivilegedTaskRunner Bundle Version => \(helperVersion)")
            
            // When the connection is valid, do the actual inter process call
//            let xpcService = prepareXPC()?.remoteObjectProxyWithErrorHandler() { error -> Void in
//                NSLog("XPC error: \(error)")
//                } as? RemoteProcessProtocol
            let xpcService = prepareXPC()?.remoteObjectProxyWithErrorHandler() { error -> Void in
                callback(false)
            } as? RemoteProcessProtocol
            
            xpcService?.getVersion(reply: {
                installedVersion in
                printLog("AppviewController: PrivilegedTaskRunner Helper Installed Version => \(installedVersion)")
                callback(installedVersion == helperVersion)
            })
        }else {
            callback(false)
        }
    }
    
    /// Call Helper using XPC with authorization
    func callHelperWithAuthorization() {
        var authRefExtForm = AuthorizationExternalForm()
        let timeout:Int = 5
        
        // Make an external form of the AuthorizationRef
        var status = AuthorizationMakeExternalForm(authRef!, &authRefExtForm)
        if (status != OSStatus(errAuthorizationSuccess)) {
            printLog("AppviewController: AuthorizationMakeExternalForm failed")
            return
        }
        
        // Add all or update required authorization right definition to the authorization database
        var currentRight:CFDictionary?
        
        // Try to get the authorization right definition from the database
        status = AuthorizationRightGet(AppAuthorizationRights.shellRightName.utf8String!, &currentRight)

        if (status == errAuthorizationDenied) {
            print("errAuthorizationDenied")
            var defaultRules = AppAuthorizationRights.shellRightDefaultRule
            defaultRules.updateValue(timeout as AnyObject, forKey: "timeout")
            status = AuthorizationRightSet(authRef!, AppAuthorizationRights.shellRightName.utf8String!, defaultRules as CFDictionary, AppAuthorizationRights.shellRightDescription, nil, "Common" as CFString)
            printLog("AppviewController: : Adding authorization right to the security database")
        }
        
        // We need to put the AuthorizationRef to a form that can be passed through inter process call
        let authData = NSData.init(bytes: &authRefExtForm, length:kAuthorizationExternalFormLength)
        
        // When the connection is valid, do the actual inter process call
        let xpcService = prepareXPC()?.remoteObjectProxyWithErrorHandler() { error -> Void in
            self.printLog("AppviewController: XPC error: \(error)")
            } as? RemoteProcessProtocol
        xpcService?.runCommand(path: "ls", authData: authData, reply: {
            reply in
            // Let's update GUI asynchronously
            DispatchQueue.global(qos: .background).async {
                // Background Thread
                DispatchQueue.main.async {
                    // Run UI Updates
//                    NSLog("lsof -iTCP -sTCP:LISTEN -n -Pwh\n" + reply + "\n>_")
                    print("lsof -iTCP -sTCP:LISTEN -n -P\n\(reply)\n>-")
                    self.printToResult(data: reply)
                }
            }
        })
    }
    
    func clearSecurity() {
        // Remove this app's specific authorization information from the security database
        let status = AuthorizationRightRemove(authRef!, AppAuthorizationRights.shellRightName.utf8String!)
        
        if(status == errAuthorizationSuccess) {
            NSLog("AppviewController: AuthorizationRightRemove was successful")
        }
        else {
            NSLog("AppviewController: AuthorizationRightRemove failed")
        }
    }
    
    // MARK: - api
    func printToResult(data:String) {
        resultTextView.string = "\(data)"
    }
    
    func closePopoverView() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.closePopover(sender: self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultTextView.string += logArchive
    }
    
    // MARK: - IBAction
    @IBAction func clickScanBtn(_ sender: Any) {
        callHelperWithAuthorization()
    }
    
    
    @IBAction func clickAboutBtn(_ sender: Any) {
        closePopoverView()
        
        if aboutWindow == nil {
            let mainStoryboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
            let aboutViewController = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("AboutViewController")) as? AboutViewController
            aboutWindow = NSWindow(contentViewController: aboutViewController!)
        }
        aboutWindow!.makeKeyAndOrderFront(self)
        if !aboutWindow!.isVisible {
            let windowController = NSWindowController(window: aboutWindow)
            windowController.showWindow(self)
        }
        
    }
    
    @IBAction func clickPreferenceBtn(_ sender: Any) {
        // PreferenceViewController
        closePopoverView()
        
        if preferenceWindow == nil {
            let mainStoryboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
            let preferenceViewController = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("PreferenceViewController")) as? PreferenceViewController
            preferenceWindow = NSWindow(contentViewController: preferenceViewController!)
        }
        preferenceWindow!.makeKeyAndOrderFront(self)
        if !preferenceWindow!.isVisible {
            let windowController = NSWindowController(window: preferenceWindow)
            windowController.showWindow(self)
        }
    }
    
    @IBAction func clickCloseBtn(_ sender: Any) {
        closePopoverView()
    }
    
    @IBAction func clickQuitBtn(_ sender: Any) {
//        clearSecurity()
        NSApplication.shared.terminate(self)
    }
}

extension PortScannerViewController {
    // MARK: Storyboard instantiation
    static func freshController() -> PortScannerViewController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "PortMapperViewController")
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? PortScannerViewController else {
            fatalError("Why cant i find PortMapperViewController? - Check Main.storyboard")
        }
        return viewcontroller
    }
}
