import AVKit
import AVFoundation

#if os(iOS)
import Flutter
import UIKit
import MediaPlayer
#else
import FlutterMacOS
import AVFAudio
#endif

let CHANNEL_NAME = "xyz.luan/audioplayers"
let GLOBAL_CHANNEL_NAME = "xyz.luan/audioplayers.global"

public class SwiftAudioplayersDarwinPlugin: NSObject, FlutterPlugin {
    var registrar: FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    var globalChannel: FlutterMethodChannel
    
    var globalContext = AudioContext()
    var players = [String : WrappedMediaPlayer]()
    
    init(registrar: FlutterPluginRegistrar, channel: FlutterMethodChannel, globalChannel: FlutterMethodChannel) {
        self.registrar = registrar
        self.channel = channel
        self.globalChannel = globalChannel
        
        globalContext.apply()
        
        super.init()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        // apparently there is a bug in Flutter causing some inconsistency between Flutter and FlutterMacOS
        #if os(iOS)
        let binaryMessenger = registrar.messenger()
        #else
        let binaryMessenger = registrar.messenger
        #endif
        
        let channel = FlutterMethodChannel(name: CHANNEL_NAME, binaryMessenger: binaryMessenger)
        let globalChannel = FlutterMethodChannel(name: GLOBAL_CHANNEL_NAME, binaryMessenger: binaryMessenger)

        let instance = SwiftAudioplayersDarwinPlugin(registrar: registrar, channel: channel, globalChannel: globalChannel)
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addMethodCallDelegate(instance, channel: globalChannel)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        dispose()
    }
    
    func dispose() {
        for (_, player) in self.players {
            player.dispose()
        }
        self.players = [:]
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let method = call.method
        
        guard let args = call.arguments as? [String: Any] else {
            Logger.error("Failed to parse call.arguments from Flutter.")
            result(0)
            return
        }

        Logger.info("method: %@", method)

        // global handlers (no playerId)
        if method == "changeLogLevel" {
            guard let valueName = args["value"] as! String? else {
                Logger.error("Null value received on changeLogLevel")
                result(0)
                return
            }
            guard let value = LogLevel.parse(valueName) else {
                Logger.error("Invalid value received on changeLogLevel")
                result(0)
                return
            }

            Logger.logLevel = value
            result(1)
            return
        } else if method == "setGlobalAudioContext" {
            guard let context = AudioContext.parse(args: args) else {
                result(0)
                return
            }
            globalContext = context
            globalContext.apply()
            result(1)
            return
        }

        // player specific handlers
        guard let playerId = args["playerId"] as? String else {
            Logger.error("Call missing mandatory parameter playerId.")
            result(0)
            return
        }
        Logger.info("playerId: %@", playerId)
        let player = self.getOrCreatePlayer(playerId: playerId)
        
        if method == "pause" {
            player.pause()
        } else if method == "resume" {
            player.resume()
        } else if method == "stop" {
            player.stop() {
                result(1)
            }
            return
        } else if method == "release" {
            player.release()
        } else if method == "seek" {
            guard let position = args["position"] as? Int else {
                Logger.error("Null position received on seek")
                result(0)
                return
            }
            let time = toCMTime(millis: position)
            player.seek(time: time) {
                result(1)
            }
            return
        } else if method == "setSourceUrl" {
            let url: String? = args["url"] as? String
            let isLocal: Bool = (args["isLocal"] as? Bool) ?? false
            
            if url == nil {
                Logger.error("Null URL received on setSourceUrl")
                result(0)
                return
            }
            
            player.setSourceUrl(url: url!, isLocal: isLocal) {
                result(1)
            }
            return
        } else if method == "setSourceBytes" {
            Logger.error("setSourceBytes is not currently implemented on iOS")
            result(0)
            return
        } else if method == "getDuration" {
            let duration = player.getDuration()
            result(duration)
        } else if method == "setVolume" {
            guard let volume = args["volume"] as? Double else {
                Logger.error("Error calling setVolume, volume cannot be null")
                result(0)
                return
            }
            
            player.setVolume(volume: volume)
        } else if method == "setBalance" {
            Logger.error("setBalance is not currently implemented on iOS")
            result(0)
            return
       } else if method == "getCurrentPosition" {
            let currentPosition = player.getCurrentPosition()
            result(currentPosition)
            return
        } else if method == "setPlaybackRate" {
            guard let playbackRate = args["playbackRate"] as? Double else {
                Logger.error("Error calling setPlaybackRate, playbackRate cannot be null")
                result(0)
                return
            }
            player.setPlaybackRate(playbackRate: playbackRate)
        } else if method == "setReleaseMode" {
            guard let releaseMode = args["releaseMode"] as? String else {
                Logger.error("Error calling setReleaseMode, releaseMode cannot be null")
                result(0)
                return
            }
            // Note: there is no "release" on iOS; hence we only care if it's looping or not
            let looping = releaseMode.hasSuffix("loop")
            player.looping = looping
        } else if method == "setPlayerMode" {
            // no-op for darwin; only one player mode
        } else if method == "setAudioContext" {
            Logger.error("iOS does not allow for player-specific audio contexts; use setGlobalAudioContext instead.")
            result(0)
            return
        } else {
            Logger.error("Called not implemented method: %@", method)
            result(FlutterMethodNotImplemented)
            return
        }
        
        // default result (bypass by adding `return` to your branch)
        result(1)
    }
    
    func getOrCreatePlayer(playerId: String) -> WrappedMediaPlayer {
        if let player = players[playerId] {
            return player
        }
        let newPlayer = WrappedMediaPlayer(
            reference: self,
            playerId: playerId
        )
        players[playerId] = newPlayer
        return newPlayer
    }
    
    func onSeekComplete(playerId: String, finished: Bool) {
        channel.invokeMethod("audio.onSeekComplete", arguments: ["playerId": playerId, "value": finished])
    }
    
    func onComplete(playerId: String) {
        channel.invokeMethod("audio.onComplete", arguments: ["playerId": playerId])
    }
    
    func onCurrentPosition(playerId: String, millis: Int) {
        channel.invokeMethod("audio.onCurrentPosition", arguments: ["playerId": playerId, "value": millis])
    }
    
    func onError(playerId: String) {
        channel.invokeMethod("audio.onError", arguments: ["playerId": playerId, "value": "AVPlayerItem.Status.failed"])
    }
    
    func onDuration(playerId: String, millis: Int) {
        channel.invokeMethod("audio.onDuration", arguments: ["playerId": playerId, "value": millis])
    }
    
    func controlAudioSession() {
        let anyIsPlaying = players.values.contains { player in player.isPlaying }
        globalContext.activateAudioSession(active: anyIsPlaying)
    }
}
