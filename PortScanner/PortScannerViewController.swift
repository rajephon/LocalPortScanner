//
//  PortMapperViewController.swift
//  PortMapper
//
//  Created by Chanwoo Noh on 2018. 7. 4..
//  Copyright © 2018년 Chanwoo Noh. All rights reserved.
//

import Cocoa

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
