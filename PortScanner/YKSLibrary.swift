//
//  YKSLibrary.swift
//  PortMapper
//
//  Created by Chanwoo Noh on 2018. 7. 5..
//  Copyright © 2018년 Chanwoo Noh. All rights reserved.
//

import Foundation
import Cocoa

class NumberOnlyFormattter : NumberFormatter {
    override func isPartialStringValid(_ partialString: String,
                              newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?,
                              errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        if partialString.isEmpty {
            return true
        }
        if partialString.count > 5 {
            return false
        }
        return UInt16(partialString) != nil
    }
}

class PortRangeField : NSTextField {
    override func awakeFromNib() {
        formatter = NumberOnlyFormattter()
        let color = NSColor(deviceRed: 0.784, green: 0.784, blue: 0.784, alpha: 1.0)
        let font = NSFont.systemFont(ofSize: 10)
        let attrs = [NSAttributedStringKey.foregroundColor: color, NSAttributedStringKey.font: font]
        let placeHolderString = NSAttributedString(string: "1 ~ 65535", attributes: attrs)
        placeholderAttributedString = placeHolderString
    }
}
