//
//  WellKnownPortListTableViewController.swift
//  PortScanner
//
//  Created by Chanwoo Noh on 2018. 7. 11..
//  Copyright © 2018년 Chanwoo Noh. All rights reserved.
//

import Foundation
import Cocoa

fileprivate enum CellIdentifiers {
    static let PortCell     = "PortCell"
    static let StatusCell   = "DescCell"
}

class WellKnownPortListTableViewDelegate : NSObject, NSTableViewDelegate, NSTableViewDataSource {
    var tableItems:[[String:String]] = [[String:String]]()
    var itemfilter:Set = Set<PortState>()
    
    public func updateData(_ data:[[String:String]]) {
        tableItems = data
    }
    
    // MARK: - NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        print("\(#function)")
        return tableItems.count
    }
    
    // MARK: - NSTableViewDelegate
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        print("\(#function) row:\(row)")
        guard tableItems.count > row else {
            return nil
        }
        let item = tableItems[row]
        var text: String = ""
        var cellIdentifier: String = ""
        if tableColumn == tableView.tableColumns[0] {
            // Port Number
            text = item["Port"]!
            cellIdentifier = CellIdentifiers.PortCell
        }else if tableColumn == tableView.tableColumns[1] {
            // Port Description
            text = item["Desc"]!
            cellIdentifier = CellIdentifiers.StatusCell
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            print("text: \(text)")
            return cell
        }else {
            print("could'nt make cell")
        }
        return nil
    }
}
