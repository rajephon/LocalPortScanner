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

enum State { FILTERED, OPEN, CLOSED };
std::unordered_map<int, std::string> states = { { FILTERED, "filtered" }, { OPEN, "open" }, { CLOSED, "closed" } };

class Attempt {
public:
    Attempt() = delete;
    Attempt(const std::string& a, int p) : address(a), port(p), fd(0), state(State::FILTERED) { }
    
    std::string flatten() {
        std::stringstream ss;
        ss << address << ":" << port << " " << states[state];
        return ss.str();
    }
    
    std::string address;
    int port;
    int state;
    int fd;
    std::chrono::time_point<std::chrono::steady_clock> start_time;
};

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

