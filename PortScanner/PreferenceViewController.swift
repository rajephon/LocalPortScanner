//
//  PreferenceViewController.swift
//  PortScanner
//
//  Created by Chanwoo Noh on 2018. 7. 10..
//  Copyright © 2018년 Chanwoo Noh. All rights reserved.
//

import Cocoa
import ServiceManagement

class PreferenceViewController : NSViewController {

    @IBOutlet weak var autoLaunchCheckbox: NSButton!
    
    var autoLaunchEnabled:Bool = false
    let keyAutoLaunchEnabled:String = "LoginItemEnabled"
    
    // MARK: - NSViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        autoLaunchEnabled = UserDefaults.standard.bool(forKey: keyAutoLaunchEnabled)
        
        autoLaunchCheckbox.state = autoLaunchEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    @IBAction func set(sender: NSButton) {
        let appBundleIdentifier = "so.yoko.portscanner.LaunchHelper"
        let autoLaunch = (autoLaunchCheckbox.state == NSControl.StateValue.on)
        
        UserDefaults.standard.set(autoLaunch, forKey: keyAutoLaunchEnabled)
        if SMLoginItemSetEnabled(appBundleIdentifier as CFString, autoLaunch) {
            if autoLaunch {
                NSLog("Successfully add login item.")
            } else {
                NSLog("Successfully remove login item.")
            }
        } else {
            NSLog("Failed to add login item.")
        }
    }
    
}
