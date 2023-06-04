//
//  UDPChattingServer.swift
//  SwiftNIOServer
//
//  Created by 김소현 on 2023/06/04.
//

import Foundation
import NIO

class UDPChattingServer {
    let group: EventLoopGroup
    // var channel: Channel
    var connectedClients: [SocketAddress: Channel] = [:]
    
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
        channel.pipeline.addHandler(UDPChattingServerHandler(server: self), name: "UDPChattingServerHandler")
        
        print("> echo-server is activated")
        try channel.closeFuture.wait()
        try group.syncShutdownGracefully()
        print("> echo-server is de-activated")
    }
    
    func sendToAllClients(message: String, senderAddress: SocketAddress) {
        for (clientAddress, clientChannel) in connectedClients {
            guard clientAddress != senderAddress else {
                continue
            }
            
            // TODO: Logic 수정 need
            let channel: Channel = bootstrapChannel() as! Channel
            let buffer = channel.allocator.buffer(string: message)
            let envelope = AddressedEnvelope(remoteAddress: clientAddress, data: buffer)
            _ = clientChannel.writeAndFlush(envelope)
        }
    }
    
    func addClient(address: SocketAddress, channel: Channel) {
        connectedClients[address] = channel
    }
    
    func removeClient(address: SocketAddress) {
        connectedClients.removeValue(forKey: address)
    }
}

class UDPChattingServerHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    
    let server: UDPChattingServer
    
    init(server: UDPChattingServer) {
        self.server = server
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let envelope = self.unwrapInboundIn(data)
        let receivedData = envelope.data.getString(at: 0, length: envelope.data.readableBytes) ?? ""
        let sourceAddress = envelope.remoteAddress
        
        print("> received (\(receivedData)) and echoed to \(connectedClients.count) clients")
        
        server.sendToAllClients(message: receivedData, senderAddress: sourceAddress)
    }
    
    func channelActive(context: ChannelHandlerContext) {
        let clientAddress = context.channel.remoteAddress!
        server.addClient(address: clientAddress, channel: context.channel)
        print("client registered \(clientAddress)")
        
        if (connectedClients.isEmpty) {
            print("> no clients to echo")
        }
    }
    
    func channelInactive(context: ChannelHandlerContext) {
        let clientAddress = context.channel.remoteAddress!
        server.removeClient(address: clientAddress)
        
        print("> client de-registered \(clientAddress)")
    }
}
