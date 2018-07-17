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
    
    // MARK: - NSViewController
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    @IBAction func set(sender: NSButton) {
        let appBundleIdentifier = "so.yoko.portscanner.LaunchHelper"
        let autoLaunch = (autoLaunchCheckbox.state == NSControl.StateValue.on)
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
