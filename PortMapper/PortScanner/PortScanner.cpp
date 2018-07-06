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
#include <vector>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <iostream>
#include <unistd.h>
#include <thread>
#include "PortScanner.hpp"

PortScanner::PortScanner() {
    
}

bool PortScanner::isOpen(unsigned short port) {
    int sock = 0;
    struct sockaddr_in server_addr;
    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        return false;
    }
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    if (connect(sock, (struct sockaddr *)&server_addr, sizeof(struct sockaddr)) < 0) {
        return false;
    }
    close(sock);
    return true;
}

void PortScanner::startScan(unsigned short start, unsigned short end) {
    unsigned int concurentThreads = std::thread::hardware_concurrency();
    std::cout << "thread: " << concurentThreads << std::endl;
    unsigned short loopSize = end - start + 1;
    if (concurentThreads <= 0 || loopSize <= 128) {
        concurentThreads = 1;
    }
    unsigned short quota = loopSize / concurentThreads;
    std::vector<std::thread> workers;
    for (int i = 0; i < concurentThreads; i++) {
        workers.push_back(std::thread([i, start, end, quota, concurentThreads, this](){
            int j = start + quota * i;
            int max = (i+1 == concurentThreads)? end+1 : j + quota;
            for (; j < max; j++) {
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
    for (auto &t : workers) {
        if (t.joinable()) {
            t.join();
        }
    }
}
