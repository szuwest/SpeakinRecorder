//
//  TelegraphSlave.swift
//  SpeakinRecorder
//
//  Created by west on 2017/10/12.
//  Copyright © 2017年 speakin. All rights reserved.
//

import Foundation
import Telegraph

@objc public protocol TelegraphSlaveDelegate {
    func telegraphSlave(_ client: TelegraphSlave, didConnectToHost host: String)
    func telegraphSlave(_ client: TelegraphSlave, didDisconnectWithError error: Error?)
    
    func telegraphSlave(_ client: TelegraphSlave, didReceiveData data: Data)
    func telegraphSlave(_ client: TelegraphSlave, didReceiveText text: String)
}

public class TelegraphSlave : NSObject, WebSocketClientDelegate{

    var serverIp: String
    var serverPort: UInt16 = 0;
    
    var client: WebSocketClient? = nil
    public weak var delegate: TelegraphSlaveDelegate? = nil
    
    public init(serverIp: String, serverPort: UInt16) {
        self.serverIp = serverIp
        self.serverPort = serverPort
        super.init()
    }
    
    public func startConnect(clientName: String) {
        if (self.client != nil) {
            print("already start")
            return
        }
        let url: String = "ws://\(self.serverIp):\(self.serverPort)"
        NSLog("url=\(url)")
        do {
            client = try WebSocketClient(url)
        } catch {
            print("error=\(error.localizedDescription)")
        }
        client?.headers["X-Name"] = clientName
//        client?.headers["Sec-WebSocket-Protocol"] = "speakinchat"
        client?.delegate = self;
        print("start")
        client?.connect()
    }
    
    public func stopConnect() {
        client?.close(immediately: true)
        client = nil;
        print("stop")
    }
    
    public func sendMessage(message: String) {
        client?.send(text: message)
//        print("send\(message)")
    }
    
    public func webSocketClient(_ client: WebSocketClient, didConnectToHost host: String) {
        print("didConnectToHost: \(host)")
        DispatchQueue.main.async(execute: {
            self.delegate?.telegraphSlave(self, didConnectToHost: host)
        })
    }
    
    public func webSocketClient(_ client: WebSocketClient, didDisconnectWithError error: Error?) {
        print("didDisconnectWithError: \(String(describing: error?.localizedDescription))")
        DispatchQueue.main.async(execute: {
            self.delegate?.telegraphSlave(self, didDisconnectWithError: error)
        })
    }
    
    public func webSocketClient(_ client: WebSocketClient, didReceiveData data: Data) {
        DispatchQueue.main.async(execute: {
            self.delegate?.telegraphSlave(self, didReceiveData: data)
        })
    }
    
    public func webSocketClient(_ client: WebSocketClient, didReceiveText text: String) {
        print("didReceiveText: \(text)")
        DispatchQueue.main.async(execute: {
            self.delegate?.telegraphSlave(self, didReceiveText: text)
        })
    }
    
}
