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

- (void)setMultiThread:(bool)enable {
    PortScanner *scanner = (PortScanner *)_scanner;
    scanner->setMultiThreadMode(enable);
}
- (void)setScanFinishCallback:(void (^)())finishCallback {
    PortScanner *scanner = (PortScanner *)_scanner;
    scanner->setCallbackScanFinish([finishCallback](){
        finishCallback();
    });
}
- (void)setScanResultCallback:(void (^)(unsigned short, PortState))resultCallback {
    PortScanner *scanner = (PortScanner *)_scanner;
    scanner->setCallbackScanResult([resultCallback](unsigned short port, PortScanner::State state){
        if (state == PortScanner::State::OPEN) {
            resultCallback(port, PortState::PortStateOPEN);
        }else if (state == PortScanner::State::CLOSED) {
            resultCallback(port, PortState::PortStateCLOSED);
        }else if (state == PortScanner::State::FILTERED) {
            resultCallback(port, PortState::PortStateFILTERED);
        }
    });
}
- (void)scanWithRangeStart:(unsigned short)start end:(unsigned short)end {
    PortScanner *scanner = (PortScanner *)_scanner;
    scanner->startScan(start, end);
}

- (void)stop {
    PortScanner *scanner = (PortScanner *)_scanner;
    scanner->stop();
}

- (void)dealloc {
    delete (PortScanner *)_scanner;
}

@end
