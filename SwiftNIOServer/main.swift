//
//  main.swift
//  SwiftNIOServer
//
//  Created by 김소현 on 2023/05/17.
//  

let hostNumber: String = "hostNumber here"

let echoServer = EchoServer(host: hostNumber, port: 65456)
let chattingServer = EchoChattingServer(host: hostNumber, port: 65456)

do {
    print("echo-server is activated")
    try chattingServer.start()
} catch let error {
    print("Error: \(error.localizedDescription)")
    chattingServer.stop()
    print("echo-server is de-activated")
}
