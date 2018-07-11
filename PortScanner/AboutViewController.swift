//
//  AboutViewController.swift
//  PortMapper
//
//  Created by Chanwoo Noh on 2018. 7. 7..
//  Copyright © 2018년 Chanwoo Noh. All rights reserved.
//

import Cocoa

class AboutViewController : NSViewController {
    @IBOutlet var changeLogTextView: NSTextView!
    @IBOutlet weak var lbVersion: NSTextField!
    
    let changeLogFilename:String = "CHANGELOG"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        changeLogTextView.isEditable = false
        
        let appVersionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let appBuildNumberString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        lbVersion.stringValue = "Version \(appVersionString)(\(appBuildNumberString))"
        
        do {
            let path = Bundle.main.url(forResource: changeLogFilename, withExtension: "")
            let content = try NSString(contentsOf: path!, encoding: String.Encoding.utf8.rawValue)
            changeLogTextView.string = "\nCHANGELOG\n\n\(content as String)"
        } catch let err as NSError {
            print(err.description)
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
}
