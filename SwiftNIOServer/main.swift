//
//  main.swift
//  SwiftNIOServer
//
//  Created by 김소현 on 2023/05/17.
//  

let hostNumber: String = "hostNumber here"
let portNumber: Int = 65456

let echoServer = EchoServer(host: hostNumber, port: portNumber)
let chattingServer = EchoChattingServer(host: hostNumber, port: portNumber)

do {
    print("echo-server is activated")
    try echoServer.start()
} catch let error {
    print("Error: \(error.localizedDescription)")
    echoServer.stop()
    print("echo-server is de-activated")
}
