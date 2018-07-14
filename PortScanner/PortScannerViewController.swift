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
    let scanner = PortScannerWrapper()!
    let queue = DispatchQueue(label: "scaningTask")
    let scanResultsTableViewDelegate = ScanResultsTableViewDelegate()
    
    var aboutWindow: NSWindow? = nil
    var preferenceWindow: NSWindow? = nil
    
    // MARK: - ScanFormView
    @IBOutlet weak var scanFormView: NSView!
    @IBOutlet weak var textPortScanStart: PortRangeField!
    @IBOutlet weak var textPortScanEnd: PortRangeField!
    @IBOutlet weak var labelErrorMessgae: NSTextField!
    
    // MARK: - ScanLoadingView
    @IBOutlet weak var loadingProgressBar: NSProgressIndicator!
    @IBOutlet weak var cancelScanningBtn: NSButton!
    @IBOutlet weak var goBackBtn: NSButton!
    @IBOutlet weak var reScanBtn: NSButton!
    
    @IBOutlet weak var scanResultView: NSView!
    @IBOutlet weak var scanResultsTableView: NSTableView!
    
    @IBOutlet var menuView: NSMenu!
    
    
    var scanSize:UInt16 = 0
    var scanResult:Dictionary = [UInt16: PortState]()
    
    var connection: NSXPCConnection?
    var authRef: AuthorizationRef?
    
    /// Initialize AuthorizationRef, as we need to manage it's lifecycle
    func initAuthorizationRef() {
        // Create an empty AuthorizationRef
        let status = AuthorizationCreate(nil, nil, AuthorizationFlags(), &authRef)
        if (status != OSStatus(errAuthorizationSuccess)) {
            NSLog("AppviewController: AuthorizationCreate failed")
            return
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
        let helperBundleInfo = CFBundleCopyInfoDictionaryForURL(helperURL as CFURL!)
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
            NSLog("AppviewController: Authorization failed: \(authStatus)")
            return
        }
        
        // Ask user for the admin privileges to install the
        var authItem = AuthorizationItem(name: kSMRightBlessPrivilegedHelper, valueLength: 0, value: nil, flags: 0)
        var authRights = AuthorizationRights(count: 1, items: &authItem)
        let flags: AuthorizationFlags = [[], .interactionAllowed, .extendRights, .preAuthorize]
        authStatus = AuthorizationCreate(&authRights, nil, flags, &authRef)
        
        // Check if the authorization went succesfully
        guard authStatus == errAuthorizationSuccess else {
            NSLog("AppviewController: Couldn't obtain admin privileges: \(authStatus)")
            return
        }
        
        // Launch the privileged helper using SMJobBless tool
        var error: Unmanaged<CFError>? = nil
        
        if(SMJobBless(kSMDomainSystemLaunchd, HelperConstants.machServiceName as CFString, authRef, &error) == false) {
            let blessError = error!.takeRetainedValue() as Error
            NSLog("AppviewController: Bless Error: \(blessError)")
        } else {
            NSLog("AppviewController: \(HelperConstants.machServiceName) installed successfully")
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
                    NSLog("AppviewController: XPC Connection Invalidated")
                }
            }
            connection?.resume()
        }
        
        return connection
    }
    
    /// Compare app's helper version to installed daemon's version and update if necessary
    func checkHelperVersionAndUpdateIfNecessary() {
        // Daemon path
        let helperURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/LaunchServices/\(HelperConstants.machServiceName)")
        let helperBundleInfo = CFBundleCopyInfoDictionaryForURL(helperURL as CFURL)
        let helperInfo = helperBundleInfo! as NSDictionary
        let helperVersion = helperInfo["CFBundleVersion"] as! String
        
        NSLog("AppviewController: PrivilegedTaskRunner Bundle Version => \(helperVersion)")
        
        // When the connection is valid, do the actual inter process call
        let xpcService = prepareXPC()?.remoteObjectProxyWithErrorHandler() { error -> Void in
            NSLog("XPC error: \(error)")
            } as? RemoteProcessProtocol
        
        xpcService?.getVersion(reply: {
            installedVersion in
            NSLog("AppviewController: PrivilegedTaskRunner Helper Installed Version => \(installedVersion)")
            if(installedVersion != helperVersion) {
                installHelperDaemon()
            }
        })
    }
    
    /// Call Helper using XPC with authorization
    func callHelperWithAuthorization() {
        var authRefExtForm = AuthorizationExternalForm()
        let timeout:Int = 5
        
        // Make an external form of the AuthorizationRef
        var status = AuthorizationMakeExternalForm(authRef!, &authRefExtForm)
        if (status != OSStatus(errAuthorizationSuccess)) {
            NSLog("AppviewController: AuthorizationMakeExternalForm failed")
            return
        }
        
        // Add all or update required authorization right definition to the authorization database
        var currentRight:CFDictionary?
        
        // Try to get the authorization right definition from the database
        status = AuthorizationRightGet(AppAuthorizationRights.shellRightName.utf8String!, &currentRight)
        
        if (status == errAuthorizationDenied) {
            
            var defaultRules = AppAuthorizationRights.shellRightDefaultRule
            defaultRules.updateValue(timeout as AnyObject, forKey: "timeout")
            status = AuthorizationRightSet(authRef!, AppAuthorizationRights.shellRightName.utf8String!, defaultRules as CFDictionary, AppAuthorizationRights.shellRightDescription, nil, "Common" as CFString)
            NSLog("AppviewController: : Adding authorization right to the security database")
        }
        
        // We need to put the AuthorizationRef to a form that can be passed through inter process call
        let authData = NSData.init(bytes: &authRefExtForm, length:kAuthorizationExternalFormLength)
        
        // When the connection is valid, do the actual inter process call
        let xpcService = prepareXPC()?.remoteObjectProxyWithErrorHandler() { error -> Void in
            NSLog("AppviewController: XPC error: \(error)")
            } as? RemoteProcessProtocol
        
        xpcService?.runCommand(path: "ls", authData: authData, reply: {
            reply in
            // Let's update GUI asynchronously
            DispatchQueue.global(qos: .background).async {
                // Background Thread
                DispatchQueue.main.async {
                    // Run UI Updates
                    NSLog("ls /var/db/sudo\n" + reply + "\n>_")
                }
            }
        })
    }
    
    // MARK: - api
    
    func portScanStartWithRange(start:UInt16, end:UInt16) -> Void {
        scanFormView.isHidden = true
        scanResultView.isHidden = false
        setEnableScanningUI(isScanningState: true)
        
        scanResult.removeAll()
        updateTableView(scanResult)
        
        scanSize = end - start + 1
        loadingProgressBar.doubleValue = 0.0

        queue.async {
            self.scanner.scan(withRangeStart: start, end: end)
        }
    }
    
    // calling by subthread
    func portScanResultCallback(port:UInt16, state:PortState) -> Void {
        scanResult[port] = state
        DispatchQueue.main.sync {
            print("callback: \(port), \(Int(Double(self.scanResult.count) / Double(self.scanSize) * 100))%")
            let progressValue = Double(self.scanResult.count) / Double(self.scanSize)

            self.loadingProgressBar.doubleValue = progressValue
            if self.scanResult.count == self.scanSize {
                portScanFinish()
            }else {
                if state == PortState.OPEN {
                    updateTableView(scanResult)
                }
            }
        }
    }
    
    // need calling by main thread with sync
    func portScanFinish() -> Void {
        loadingProgressBar.doubleValue = 1.0
        scanResultView.isHidden = false
        updateTableView(scanResult)
        setEnableScanningUI(isScanningState: false)
    }
    
    func showErrorMessage(_ msg:String) -> Void {
        labelErrorMessgae.isHidden = false
        labelErrorMessgae.stringValue = "ERROR: " + msg
    }
    
    func updateTableView(_ data:Dictionary<UInt16,PortState>) {
        scanResultsTableViewDelegate.updateData(data)
        scanResultsTableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        labelErrorMessgae.isHidden = true
        loadingProgressBar.minValue = 0.0
        loadingProgressBar.maxValue = 1.0
        scanResultView.isHidden = true;
        setEnableScanningUI(isScanningState: true)
        
        scanResultsTableView.delegate = scanResultsTableViewDelegate
        scanResultsTableView.dataSource = scanResultsTableViewDelegate
        scanResultsTableViewDelegate.filterDsiplayItem([PortState.OPEN])
        
        scanner.setScanResultCallback({ (port, state) -> Void in
            self.portScanResultCallback(port: port, state: state)
        })
        
        scanner.setScanFinishCallback({ () -> Void in
            self.portScanFinish()
        })
        scanner.setMultiThread(true)
    
    }
    
    func setEnableScanningUI(isScanningState scanningState: Bool) {
        loadingProgressBar.isHidden = !scanningState
        cancelScanningBtn.isHidden = !scanningState
        goBackBtn.isHidden = scanningState
    }
    
    // MARK: - IBAction
    @IBAction func clickScanBtn(_ sender: Any) {
        guard let start = UInt16(textPortScanStart.stringValue),
            let end = UInt16(textPortScanEnd.stringValue) else {
                showErrorMessage("casting failed")
                return
        }
        if start > end {
            showErrorMessage("시작 범위는 마지막보다 작아야 합니다.")
            return
        }
        if start <= 0 {
            showErrorMessage("시작 범위는 0보다 커야 합니다.")
            return
        }
        if end > 65535 {
            showErrorMessage("마지막 범위는 65535보다 작아야 합니다.")
            return
        }
        portScanStartWithRange(start: start, end: end)
    }
    
    @IBAction func clickRescanBtn(_ sender: Any) {
        guard let start = UInt16(textPortScanStart.stringValue),
            let end = UInt16(textPortScanEnd.stringValue),
            start <= end, 0 < start, end <= 65535 else {
                return
        }
        portScanStartWithRange(start: start, end: end)
    }
    
    @IBAction func clickGoBackBtn(_ sender: Any) {
        scanResultView.isHidden = true
        scanFormView.isHidden = false
    }
    
    @IBAction func clickScanCancelBtn(_ sender: NSButton) {
        sender.isEnabled = false
        queue.async {
            self.scanner.stop()
        }
        sender.isEnabled = true
        setEnableScanningUI(isScanningState: false)
    }
    
    @IBAction func clickAboutBtn(_ sender: Any) {
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
        print("click")
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.closePopover(sender: self)
        }
    }
    
    @IBAction func clickQuitBtn(_ sender: Any) {
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
