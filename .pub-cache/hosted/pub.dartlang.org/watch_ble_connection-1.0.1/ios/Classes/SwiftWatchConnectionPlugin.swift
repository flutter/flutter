import Flutter
import UIKit
import WatchConnectivity

@available(iOS 9.3, *)
public class SwiftWatchConnectionPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "watchConnection", binaryMessenger: registrar.messenger())
        let instance = SwiftWatchConnectionPlugin()
        instance.startWCSession()
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.channel = channel
    }
    public var channel: FlutterMethodChannel? = nil
    private var messageListenerIds: [Int] = []
    private var dataListenerIds: [Int] = []
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "listenData":
            debugPrint("Listen data")
            if let id = call.arguments as? Int {
                dataListenerIds.append(id)
            }
            result(nil)
        case "listenMessages":
            debugPrint("Listen messages")
            if let id = call.arguments as? Int {
                messageListenerIds.append(id)
            }
            result(nil)
        case "cancelListeningData":
            debugPrint("cancelListeningData")
            if let id = call.arguments as? Int {
                dataListenerIds = dataListenerIds.filter { $0 != id }
            }
            result(nil)
        case "cancelListeningMessages":
            debugPrint("cancelListeningMessages")
            if let id = call.arguments as? Int {
                messageListenerIds = messageListenerIds.filter { $0 != id }
            }
            result(nil)
        case "sendMessage":
            debugPrint("Send message", call.arguments ?? "no arguments")
            self.sendMessage(call, result)
            result(nil)
        case "setData":
            debugPrint("set Data", call.arguments ?? "no arguments")
            self.setData(call)
            result(nil)
        default:
            break;
        }
    }
    
    private func sendMessage(_ call: FlutterMethodCall, _ result: FlutterResult){
        startWCSession()
        if let safeArgs = call.arguments as? Dictionary<String, Any> {
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(safeArgs, replyHandler: nil, errorHandler: nil)
            }
        }
    }
    
    private func setData(_ call: FlutterMethodCall) {
        startWCSession()
        if let safeArgs = call.arguments as? Dictionary<String, Any> {
            if WCSession.default.activationState == .activated {
                if let path = safeArgs["path"] as? String, let args = safeArgs["args"] as? Dictionary<String, Any> {
                    var ctx = WCSession.default.applicationContext
                    ctx[path] = args
                    do {
                        try WCSession.default.updateApplicationContext(ctx)
                    } catch {
                        debugPrint(error)
                    }
                }
                
            }
        }
    }
    
    
    public func startWCSession() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
}

@available(iOS 9.3, *)
extension SwiftWatchConnectionPlugin: WCSessionDelegate {
    
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        for id in messageListenerIds {
            channel?.invokeMethod("messageReceived", arguments: [
                "id": id,
                "args": message
            ])
        }
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        for id in dataListenerIds {
            channel?.invokeMethod("dataReceived", arguments: [
                "id": id,
                "args":applicationContext
            ])
        }
    }
}
