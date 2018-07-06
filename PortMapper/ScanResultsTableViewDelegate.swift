//
//  ScanResultTableView.swift
//  PortMapper
//
//  Created by Chanwoo Noh on 2018. 7. 6..
//  Copyright © 2018년 Chanwoo Noh. All rights reserved.
//

import Foundation
import Cocoa

fileprivate enum CellIdentifiers {
    static let PortCell     = "PortCell"
    static let StatusCell   = "StatusCell"
}

class ScanResultsTableViewDelegate : NSObject, NSTableViewDelegate, NSTableViewDataSource {
    var tableItems:[(UInt16,PortState)] = [(UInt16,PortState)]()
    var itemfilter:Set = Set<PortState>()
    
    public func filterDsiplayItem(_ filter:Set<PortState>) {
        itemfilter = filter
    }
    
    public func updateData(_ data:Dictionary<UInt16,PortState>) {
//        tableItems = data.sorted(by: { $0.0 < $1.0} )
//        for d in tableItems {
//            print(d)
//        }
        var items:Dictionary<UInt16,PortState> = [UInt16:PortState]()
        for d in data {
            if itemfilter.contains(d.value) {
                items[d.key] = d.value
            }
        }
        tableItems = items.sorted(by: { $0.0 < $1.0 } )
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
            // 포트 번호
            text = "\(item.0)"
            cellIdentifier = CellIdentifiers.PortCell
        }else if tableColumn == tableView.tableColumns[1] {
            // 포트 상태
            switch item.1 {
            case .OPEN:
                text = "OPEN"
                break
            case .CLOSED:
                text = "CLOSED"
                break
            case .FILTERED:
                text = "FILTERED"
                break
            }
            cellIdentifier = CellIdentifiers.StatusCell
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
}
