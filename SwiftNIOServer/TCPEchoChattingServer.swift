//
//  TCPEchoChattingServer.swift
//  SwiftNIOServer
//
//  Created by 김소현 on 2023/05/26.
//

import Foundation

import NIO
import SocketIO

// global DB
var connectedClients: [ObjectIdentifier: Channel] = [:]

class EchoChattingServerHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    func channelActive(context: ChannelHandlerContext) {
        let clientChannel = context.channel
        let clientId = ObjectIdentifier(clientChannel)
        connectedClients[clientId] = clientChannel
    }
    
    func channelRead(channelContext: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        let readableBytes = buffer.readableBytes
        
        if let received = buffer.readString(length: readableBytes) {
            // client에게 받은 메세지를 connectedClients에게 broadcast
            let receivedMessage = "received \(received) and echoed to \(connectedClients.count) clients"
            print(receivedMessage)
            broadcastMessage(receivedMessage)
        }
    }
    
    func channelInactive(context: ChannelHandlerContext) {
        let clientChannel = context.channel
        let clientId = ObjectIdentifier(clientChannel)
        connectedClients.removeValue(forKey: clientId)

        let message = "active threads are remained: \(connectedClients.count) threads"
        print(message)
        broadcastMessage(message)
    }
    
    func broadcastMessage(_ message: String) {
        let messageBuffer = ByteBuffer(string: message)

        for (_, clientChannel) in connectedClients {
            _ = clientChannel.writeAndFlush(messageBuffer)
        }
    }
    
    func channelReadComplete(channelContext: ChannelHandlerContext) {
        channelContext.flush()
    }
    
    func errorCaught(channelContext: ChannelHandlerContext, error: Error) {
        print("error: \(error.localizedDescription)")
        channelContext.close(promise: nil)
    }
}

class EchoChattingServer {
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    private var host: String?
    var port: Int?
    
    init(host: String, port: Int) {
        self.host = host
        self.port = port
    }
    
    func start() throws {
        guard let host = host else {
            throw EchoServerError.invalidHost
        }
        guard let port = port else {
            throw EchoServerError.invalidPort
        }
        do {
            let channel = try serverBootstrap.bind(host: host, port: port).wait()
            print("Listening on \(String(describing: channel.localAddress)) ...")
            try channel.closeFuture.wait()
        } catch let error {
            throw error
        }
    }
    
    func stop() {
        do {
            try group.syncShutdownGracefully()
            print("chatting-server is de-activated")
        } catch let error {
            print("Error shutting down \(error.localizedDescription)")
            exit(0)
        }
        print("Client connection closed")
    }
    
    private var serverBootstrap: ServerBootstrap {
        return ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .serverChannelInitializer { channel in
                channel.pipeline.addHandler(EchoChattingServerHandler())
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }
}
