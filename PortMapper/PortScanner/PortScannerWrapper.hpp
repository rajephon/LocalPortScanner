//
//  PortScannerWrapper.hpp
//  PortMapper
//
//  Created by Chanwoo Noh on 2018. 7. 4..
//  Copyright © 2018년 Chanwoo Noh. All rights reserved.
//

#ifndef PortScannerWrapper_hpp
#define PortScannerWrapper_hpp

#import <Foundation/Foundation.h>

//typedef enum portState { FILTERED, OPEN, CLOSED } PortState;
typedef NS_ENUM(NSInteger, PortState){
    PortStateOPEN = 0,
    PortStateCLOSED,
    PortStateFILTERED
};

@interface PortScannerWrapper : NSObject {
@private
    void* _scanner;
}
- (PortScannerWrapper*) init;
- (bool) isOpen: (unsigned short) port;
- (void) setMultiThread: (bool) enable;
- (void) setScanFinishCallback:(void (^)()) finishCallback;
- (void) setScanResultCallback:(void (^)(unsigned short port, PortState state)) resultCallback;
- (void) scanWithRangeStart: (unsigned short) start end:(unsigned short) end;
- (void) dealloc;
@end

#endif /* PortScannerWrapper_hpp */
