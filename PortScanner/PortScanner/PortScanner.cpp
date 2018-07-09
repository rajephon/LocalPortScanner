//
//  PortScanner.cpp
//  PortMapper
//
//  Created by Chanwoo Noh on 2018. 7. 4..
//  Copyright © 2018년 Chanwoo Noh. All rights reserved.
//

#include <unordered_map>
#include <string>
#include <sstream>
#include <chrono>
#include <list>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <iostream>
#include <unistd.h>
#include "PortScanner.hpp"

PortScanner::PortScanner() {

}

bool PortScanner::isOpen(unsigned short port) {
    int sock = 0;
    struct hostent *he;
    struct sockaddr_in server_addr;
    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        return false;
    }
    if ((he = gethostbyname("127.0.0.1")) == nullptr) {
        return false;
    }
    
    memset(&server_addr, 0, sizeof(struct sockaddr_in));
    server_addr.sin_family = AF_INET;
    memcpy(&server_addr.sin_addr.s_addr, he->h_addr, he->h_length);
    server_addr.sin_port = htons(port);
//    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    if (connect(sock, (struct sockaddr *)&server_addr, sizeof(struct sockaddr_in)) < 0) {
        perror("Error: ");
        return false;
    }
    close(sock);
    return true;
}

void PortScanner::startScan(unsigned short start, unsigned short end) {
    unsigned int concurentThreads = std::thread::hardware_concurrency();
    unsigned short loopSize = end - start + 1;
    if (concurentThreads <= 0 || loopSize <= 128) {
        concurentThreads = 1;
    }
    std::cout << "thread: " << concurentThreads << std::endl;
    unsigned short quota = loopSize / concurentThreads;
    setCancel(false);
    for (int i = 0; i < concurentThreads; i++) {
        _workers.push_back(std::thread([i, start, end, quota, concurentThreads, this](){
            int j = start + quota * i;
            int max = (i+1 == concurentThreads)? end+1 : j + quota;
            for (; j < max && !this->isCancelled(); j++) {
                if (isOpen(j)) {
                    std::lock_guard<std::mutex> guard(_callbackMutex);
                    _callbackScanResult(j, State::OPEN);
                }else {
                    std::lock_guard<std::mutex> guard(_callbackMutex);
                    _callbackScanResult(j, State::CLOSED);
                }
            }
        }));
    }
//    for (int i = start; i <= end; i++) {
//        if (isOpen(i)) {
//            _callbackScanResult(i, State::OPEN);
//        }else
//            _callbackScanResult(i, State::CLOSED);
//    }
}

void PortScanner::stop() {
    setCancel(true);
}

void PortScanner::setCancel(bool cancel) {
    std::lock_guard<std::mutex> guard(_cancelMutex);
    _cancel = cancel;
}

bool PortScanner::isCancelled() {
    std::lock_guard<std::mutex> guard(_cancelMutex);
    return _cancel;
}