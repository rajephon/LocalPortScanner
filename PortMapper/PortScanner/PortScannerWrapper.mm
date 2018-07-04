//
//  PortScannerWrapper.mm
//  PortMapper
//
//  Created by Chanwoo Noh on 2018. 7. 4..
//  Copyright © 2018년 Chanwoo Noh. All rights reserved.
//

#import "PortScannerWrapper.hpp"
#import "PortScanner.hpp"

@implementation PortScannerWrapper
- (PortScannerWrapper *)init {
    _scanner = (void*) new PortScanner;
    return self;
}

- (bool)isOpen:(unsigned short)port {
    PortScanner *scanner = (PortScanner *)_scanner;
    return scanner->isOpen(port);
}

@end
