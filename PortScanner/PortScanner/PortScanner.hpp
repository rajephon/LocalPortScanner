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
#include <thread>
#include <mutex>
#include <vector>

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
    
    void startScan(unsigned short start, unsigned short end);
    void stop();
    
private:
    bool isOpen(unsigned short port);
    void setCancel(bool cancel);
    bool isCancelled();
    CallbackScanResult _callbackScanResult;
    CallbackScanFinish _callbackScanFinish;
    std::vector<std::thread> _workers;
    std::mutex _callbackMutex;
    std::mutex _cancelMutex;
    bool _cancel = false;
    bool _multiThreadMode = false;
};

#endif /* PortScanner_hpp */
