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
    @IBOutlet weak var scanFormView: NSView!
    
    @IBOutlet weak var textPortScanStart: PortRangeField!
    @IBOutlet weak var textPortScanEnd: PortRangeField!
    @IBOutlet weak var labelErrorMessgae: NSTextField!
    
    func portScanStartWithRange(start:UInt16, end:UInt16) -> Void {
        scanFormView.isHidden = true
    }
    
    func portScanResultCallback(port:UInt16, state:PortState) -> Void {
        
    }
    
    func portScanFinish() -> Void {
        
    }
    
    func showErrorMessage(_ msg:String) -> Void {
        labelErrorMessgae.isHidden = false
        labelErrorMessgae.stringValue = "ERROR: " + msg
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
