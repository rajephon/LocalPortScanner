//
//  PortScanner.hpp
//  PortMapper
//
//  Created by Chanwoo Noh on 2018. 7. 4..
//  Copyright © 2018년 Chanwoo Noh. All rights reserved.
//
#ifndef PortScanner_hpp
#define PortScanner_hpp

#include <memory>
#include <functional>
#include <mutex>

class PortScanner {
public:
    enum State { FILTERED, OPEN, CLOSED };
    typedef std::function<void(unsigned short port, State state)> CallbackScanResult;
    typedef std::function<void()> CallbackScanFinish;
    
    PortScanner();
    void setMultiThreadMode(bool isEnable) { _multiThreadMode = isEnable; }
    void setCallbackScanResult(CallbackScanResult callbackScanResult) {
        _callbackScanResult = callbackScanResult;
    }
    void setCallbackScanFinish(CallbackScanFinish callbackScanFinish) {
        _callbackScanFinish = callbackScanFinish;
    }
    
    bool isOpen(unsigned short port);
    void startScan(unsigned short start, unsigned short end);
    
private:
    CallbackScanResult _callbackScanResult;
    CallbackScanFinish _callbackScanFinish;
    std::mutex _callbackMutex;
    bool _multiThreadMode = false;
};

#endif /* PortScanner_hpp */
