//
//  UDPEchoServer.swift
//  SwiftNIOServer
//
//  Created by 김소현 on 2023/06/01.
//

import Foundation
import NIO

class UDPServer {
    let group: EventLoopGroup
    
    init() throws {
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    }
    
    func bootstrapChannel() -> EventLoopFuture<Channel> {
        let bootstrap = DatagramBootstrap(group: group)
            .channelInitializer { channel in
                return channel.eventLoop.makeSucceededFuture(())
            }
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEPORT), value: 1)
        
        return bootstrap.bind(host: hostNumber, port: portNumber)
    }
    
    func start() throws {
        let channel: Channel = bootstrapChannel() as! Channel
        channel.pipeline.addHandler(ServerHandler(), name: "serverHandler")
        
        print("> echo-server is activated")
        try channel.closeFuture.wait()
        try group.syncShutdownGracefully()
        print("> echo-server is de-activated")
    }
}

class ServerHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let envelope = self.unwrapInboundIn(data)
        let receivedData = envelope.data.getString(at: 0, length: envelope.data.readableBytes) ?? ""
        let sourceAddress = envelope.remoteAddress
                
        let message = "> echoed: \(receivedData)"
        let buffer = context.channel.allocator.buffer(string: message)
        _ = AddressedEnvelope(remoteAddress: sourceAddress, data: buffer)
    }
}
