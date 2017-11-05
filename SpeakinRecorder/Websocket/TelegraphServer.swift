//
//  TelegraphServer.swift
//  SpeakinRecorder
//
//  Created by west on 2017/10/12.
//  Copyright © 2017年 speakin. All rights reserved.
//

import Foundation
import Telegraph

public class TelWebSocket : NSObject, WebSocket {
    public func send(message: WebSocketMessage) {
        socket?.send(message: message)
    }
    
    public func close(immediately: Bool) {
        socket?.close(immediately: immediately)
    }
    
    public func send(data: Data) {
        socket?.send(data: data)
    }
    
    public func send(text: String) {
        socket?.send(text: text)
    }
    
    fileprivate var socket: WebSocket? = nil
    
    fileprivate init(webSocket: WebSocket) {
        super.init()
        socket = webSocket;
    }
    
}

@objc public protocol TelegraphServerDelegate {
    func server(_ server: TelegraphServer, webSocketDidConnect webSocket: TelWebSocket)
    func server(_ server: TelegraphServer, webSocketDidDisconnect webSocket: TelWebSocket, error: Error?)
    
    func server(_ server: TelegraphServer, webSocket: TelWebSocket, didReceiveMessage message: String)
    func server(_ server: TelegraphServer, webSocket: TelWebSocket, didSendMessage message: String)
}

public class TelegraphServer : NSObject, ServerWebSocketDelegate {

    private let websocketServer = Server();
    public weak var delegate: TelegraphServerDelegate?
    fileprivate var webSocketConnections = Set<TelWebSocket>()
    
    public override init() {
        super.init()
        websocketServer.webSocketConfig.pingInterval = 5
        websocketServer.webSocketDelegate = self;
    }
    
    public func start(onPort port: UInt16) {
        try! websocketServer.start(onPort: port)
    }
    
    public func stopServer() {
        websocketServer.stop(immediately: false)
    }
    
    public func sendToAll(message: String) {
        webSocketConnections.forEach { $0.send(text: message) }
    }
    
    public func clientCount() -> Int {
        return websocketServer.webSocketCount;
    }
    
    public func telWebsocketClients() -> [TelWebSocket] {
        return Array(webSocketConnections)
    }
    
    private func teleWebSocketOf(webSocket socket: WebSocket) -> TelWebSocket? {
        let webSC = socket as! WebSocketConnection
        var found: TelWebSocket? = nil
        for wSocket in webSocketConnections {
            let aWebSC = wSocket.socket as! WebSocketConnection
            if aWebSC == webSC {
                found = wSocket
                break
            }
        }
        return found
    }
    
    public func server(_ server: Server, webSocketDidConnect webSocket: WebSocket, handshake: HTTPRequest) {
        print("client connect: \(webSocket) handshake\(handshake)")
        let name = handshake.headers["X-Name"] ?? "stranger"
        print("WebSocket connected (\(name))")
        
        let telSocket = TelWebSocket(webSocket: webSocket)
        webSocketConnections.insert(telSocket)
        DispatchQueue.main.async(execute: {
            self.delegate?.server(self, webSocketDidConnect: telSocket)
        })
    }
    
    public func server(_ server: Server, webSocketDidDisconnect webSocket: WebSocket, error: Error?) {
        print("webSocketDidDisconnect: err：\(String(describing: error))")
        let found: TelWebSocket? = self.teleWebSocketOf(webSocket: webSocket)
        if found != nil {
            webSocketConnections.remove(found!)
            DispatchQueue.main.async(execute: {
                self.delegate?.server(self, webSocketDidDisconnect: found!, error: error)
            })
        }
    }
    
    public func server(_ server: Server, webSocket: WebSocket, didReceiveMessage message: WebSocketMessage) {
        print("didReceiveMessage:\(message)")
        let found: TelWebSocket? = self.teleWebSocketOf(webSocket: webSocket)
        if found != nil {
//            let strMsg: String = message
            switch(message.payload) {
            case .text(let msg):
                DispatchQueue.main.async(execute: {
                    self.delegate?.server(self, webSocket: found!, didReceiveMessage: msg)
                })
            case .none:
                print("none")
            case .binary(let data):
                print("binary data \(data)")
            case .close(let code, let reason):
                print("code=\(code) reason=\(reason)")
            }
        }
    }
    
    public func server(_ server: Server, webSocket: WebSocket, didSendMessage message: WebSocketMessage) {
//        print("didSendMessage: send\(message.payload)")
    }
    
}
