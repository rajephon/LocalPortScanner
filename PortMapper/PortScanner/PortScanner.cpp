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
#include "PortScanner.hpp"

PortScanner::PortScanner() {
    
}

bool PortScanner::isOpen(unsigned short port) {
    int sock = 0;
    struct sockaddr_in server_addr;
    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        // TODO: send message "socket create failed"
        return false;
    }
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");
//    inet_aton("127.0.0.1", &server_addr.sin_addr);
    if (connect(sock, (struct sockaddr *)&server_addr, sizeof(struct sockaddr)) < 0) {
//        perror("socket");
        return false;
    }
    close(sock);
    return true;
}

void PortScanner::startScan(unsigned short start, unsigned short end) {
    for (int i = start; i <= end; i++) {
        if (isOpen(i))
            _callbackScanResult(i, State::OPEN);
        else
            _callbackScanResult(i, State::CLOSED);
    }
//    _callbackScanFinish
}
