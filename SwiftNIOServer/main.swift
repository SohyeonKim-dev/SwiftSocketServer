//
//  main.swift
//  SwiftNIOServer
//
//  Created by 김소현 on 2023/05/17.
//  ref: https://fattywaffles.medium.com/getting-started-with-swiftnio-40d35de15c0b

let server = EchoServer(host: "typing host here", port: 65456)

do {
    try server.start()
} catch let error {
    print("Error: \(error.localizedDescription)")
    server.stop()
}
