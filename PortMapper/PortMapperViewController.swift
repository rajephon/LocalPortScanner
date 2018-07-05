//
//  PortMapperViewController.swift
//  PortMapper
//
//  Created by Chanwoo Noh on 2018. 7. 4..
//  Copyright © 2018년 Chanwoo Noh. All rights reserved.
//

import Cocoa
//import SwiftSocket

class PortMapperViewController: NSViewController {
    let scanner = PortScannerWrapper()!
    
    @IBOutlet weak var lbOpenedPortList: NSTextField!
    
    func portScanResultCallback(port:UInt16, state:PortState) -> Void {
        
    }
    
    func portScanFinish() -> Void {
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        lbOpenedPortList.stringValue = ""
        
        scanner.setScanResultCallback({ (port, state) -> Void in
            self.portScanResultCallback(port: port, state: state)
        })
        
        scanner.setScanFinishCallback({ () -> Void in
            self.portScanFinish()
        })
        scanner.setMultiThread(true)
        
        
        
//        var i: UInt16 = 1
//        while i < 1024 {
//            let result = scanner?.isOpen(i);
//            if result == true {
//                print("\(i) is opened")
//                lbOpenedPortList.stringValue += "\(i) is opened\n"
//            }
//            i += 1
//        }
    }
    
}

extension PortMapperViewController {
    // MARK: Storyboard instantiation
    static func freshController() -> PortMapperViewController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "PortMapperViewController")
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? PortMapperViewController else {
            fatalError("Why cant i find PortMapperViewController? - Check Main.storyboard")
        }
        return viewcontroller
    }
}
