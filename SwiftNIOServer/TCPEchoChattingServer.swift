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
var group_queue:[Int] = [1, 2, 3]

class EchoChattingServerHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    func channelRead(channelContext: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        let readableBytes = buffer.readableBytes
        if let received = buffer.readString(length: readableBytes) {
            print(received)
        }
        channelContext.write(data, promise: nil)
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
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: group_queue.count)
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
            print("echo-server is de-activated")
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
            .serverChannelInitializer{ channel in
                // Handler 변경 주의
                channel.pipeline.addHandler(EchoChattingServerHandler())
            }
            .childChannelInitializer { channel in
                // Handler 변경 주의
                let socket = try SocketIOClient(config: [], socketURL: URL(string: "server address")!, sessionDelegate: nil)
                let handler = SocketIOClientHandler(socket: socket)
                return channel.pipeline.addHandler(handler)
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }
}
