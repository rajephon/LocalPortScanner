//
//  PreferenceViewController.swift
//  PortScanner
//
//  Created by Chanwoo Noh on 2018. 7. 10..
//  Copyright © 2018년 Chanwoo Noh. All rights reserved.
//

import Cocoa

class PreferenceViewController : NSViewController {
    
    let wellKnownPortListTableViewDelegate = WellKnownPortListTableViewDelegate()
    
    @IBOutlet weak var wellKnownPortListTableView: NSTableView!
    
    // MARK: - NSViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wellKnownPortListTableView.delegate = wellKnownPortListTableViewDelegate
        wellKnownPortListTableView.dataSource = wellKnownPortListTableViewDelegate
        
        do {
            var data:[[String:String]] = []
            let path = Bundle.main.url(forResource: "WellKnownPortList", withExtension: "csv")
            let content = (try NSString(contentsOf: path!, encoding: String.Encoding.utf8.rawValue)) as String
            let rows = cleanRows(data: content).components(separatedBy: "\n")
            if rows.count > 0 {
                data = []
                let columnTitles = rows.first!.components(separatedBy: ",")
                for idx in 1...rows.count-1 {
                    let row = rows[idx]
                    let fields = row.components(separatedBy: ",")
                    if fields.count != columnTitles.count { continue; }
                    var dataRow = [String:String]()
                    for (index,field) in fields.enumerated() {
                        let fieldName = columnTitles[index]
                        dataRow[fieldName] = field
                    }
                    data += [dataRow]
                }
                wellKnownPortListTableViewDelegate.updateData(data)
                wellKnownPortListTableView.reloadData()
            }
        } catch let err as NSError {
            print(err.description)
        }
        // loadscv file
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
    }
    
    func cleanRows(data:String)->String{
        //use a uniform \n for end of lines.
        var result = data
        result = result.replacingOccurrences(of: "\r", with: "\n")
        result = result.replacingOccurrences(of: "\n\n", with: "\n")
        return result
    }
    
    // MARK: - IBAction
    
    @IBAction func clickAddRowBtn(_ sender:NSButton) {
        
    }
    
    
}
