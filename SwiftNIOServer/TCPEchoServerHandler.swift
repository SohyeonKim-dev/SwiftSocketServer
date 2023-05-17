//
//  TCPEchoServerHandler.swift
//  SwiftNIOServer
//
//  Created by 김소현 on 2023/05/17.
//

import Foundation
import NIO

class EchoHandler: ChannelInboundHandler {
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
