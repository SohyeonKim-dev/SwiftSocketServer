//
//  main.swift
//  SwiftNIOServer
//
//  Created by 김소현 on 2023/05/17.
//  

let server = EchoServer(host: "Local Host Number here", port: 65456)

do {
    print("echo-server is activated")
    try server.start()
} catch let error {
    print("Error: \(error.localizedDescription)")
    server.stop()
    print("echo-server is de-activated")
}
