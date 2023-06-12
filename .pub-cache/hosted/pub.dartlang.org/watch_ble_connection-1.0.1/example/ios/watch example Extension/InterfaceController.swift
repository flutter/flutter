//
//  InterfaceController.swift
//  watch example Extension
//
//  Created by Afriwan Ahda on 22/06/2022.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController {

    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        startSession()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
    }

    @IBAction func sendMessageButtonPressed() {
        startSession()
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["text": "foo"], replyHandler: nil, errorHandler: nil)
            debugPrint("Sent message")
        } else {
            debugPrint("no contact available")
        }
    }
    @IBAction func setData() {
        startSession()
        if WCSession.default.activationState == .activated {
            var ctx = WCSession.default.applicationContext
            let formatter = DateFormatter()
            ctx["watchData"] = formatter.string(from: Date())
            do {
                try WCSession.default.updateApplicationContext(ctx)
                debugPrint("set data")
            } catch {
                debugPrint(error)
            }
            
        }
    }
    
    func startSession() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
}

extension InterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print(message)
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print(applicationContext)
    }
}
