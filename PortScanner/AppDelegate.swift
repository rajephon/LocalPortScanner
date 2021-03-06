//
//  AppDelegate.swift
//  PortMapper
//
//  Created by Chanwoo Noh on 2018. 7. 4..
//  Copyright © 2018년 Chanwoo Noh. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    let popover = NSPopover()
    
    var viewController: PortScannerViewController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("\(#function)")

        // set menu bar icon & popover view
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
            button.action = #selector(togglePopover(_:))
        }
        
        viewController = PortScannerViewController.freshController()
        popover.contentViewController = viewController
        popover.behavior = NSPopover.Behavior.semitransient

        viewController.checkHelperVersionAndUpdateIfNecessary { installed in
            if !installed {
                self.viewController.installHelperDaemon()
            }
            // Create an empty authorization reference
            self.viewController.initAuthorizationRef()
        }

        if !popover.isShown {
            showPopover(sender: self)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        viewController.freeAuthorizationRef()
    }

    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }

    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }

    func closePopover(sender: Any?) {
        popover.performClose(sender)
    }
    
}

