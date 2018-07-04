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

@interface PortScannerWrapper : NSObject {
@private
    void* _scanner;
}
- (PortScannerWrapper*) init;
- (bool) isOpen: (unsigned short) port;
@end

#endif /* PortScannerWrapper_hpp */
