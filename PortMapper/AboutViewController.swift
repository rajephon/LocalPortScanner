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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        changeLogTextView.isEditable = false
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
}
