import AVKit
import AVFoundation

#if os(iOS)
import Flutter
import UIKit
import MediaPlayer
#else
import FlutterMacOS
#endif

#if os(iOS)
let OS_NAME = "iOS"
let ENABLE_NOTIFICATIONS_HANDLER = true
#else
let OS_NAME = "macOS"
let ENABLE_NOTIFICATIONS_HANDLER = false
#endif

let CHANNEL_NAME = "xyz.luan/audioplayers"
let AudioplayersPluginStop = NSNotification.Name("AudioplayersPluginStop")

public class SwiftAudioplayersPlugin: NSObject, FlutterPlugin {
    
    var registrar: FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    var notificationsHandler: NotificationsHandler? = nil
    
    var players = [String : WrappedMediaPlayer]()
    // last player that started playing, to be used for notifications command center
    // TODO(luan): provide generic way to control this
    var lastPlayerId: String? = nil
    
    var timeObservers = [TimeObserver]()
    
    var isDealloc = false
    
    init(registrar: FlutterPluginRegistrar, channel: FlutterMethodChannel) {
        self.registrar = registrar
        self.channel = channel
        
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.needStop), name: AudioplayersPluginStop, object: nil)
        if ENABLE_NOTIFICATIONS_HANDLER {
            notificationsHandler = NotificationsHandler(reference: self)
        }
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        // TODO(luan) apparently there is a bug in Flutter causing some inconsistency between Flutter and FlutterMacOS
        #if os(iOS)
        let binaryMessenger = registrar.messenger()
        #else
        let binaryMessenger = registrar.messenger
        #endif
        
        let channel = FlutterMethodChannel(name: CHANNEL_NAME, binaryMessenger: binaryMessenger)

        let instance = SwiftAudioplayersPlugin(registrar: registrar, channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    @objc func needStop() {
        isDealloc = true
        destroy()
    }
    
    func destroy() {
        for osberver in self.timeObservers {
            osberver.player.removeTimeObserver(osberver.observer)
        }
        self.timeObservers = []
        
        for (_, player) in self.players {
            player.clearObservers()
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
        }

        guard let playerId = args["playerId"] as? String else {
            Logger.error("Call missing mandatory parameter playerId.")
            result(0)
            return
        }
        Logger.info("%@ => call %@, playerId %@", OS_NAME, method, playerId)
        
        let player = self.getOrCreatePlayer(playerId: playerId)
        
        if method == "startHeadlessService" {
            guard let handler = notificationsHandler else {
                result(FlutterMethodNotImplemented)
                return
            }
            if let handleKey = args["handleKey"] {
                Logger.info("calling start headless service %@", handleKey)
                let handle = (handleKey as! [Any])[0]
                handler.startHeadlessService(handle: (handle as! Int64))
            } else {
                result(0)
            }
        } else if method == "monitorNotificationStateChanges" {
            guard let handler = notificationsHandler else {
                result(FlutterMethodNotImplemented)
                return
            }
            if let handleMonitorKey = args["handleMonitorKey"] {
                Logger.info("calling monitor notification %@", handleMonitorKey)
                let handle = (handleMonitorKey as! [Any])[0]
                handler.updateHandleMonitorKey(handle: handle as! Int64)
            } else {
                result(0)
            }
        } else if method == "play" {
            guard let url = args["url"] as! String? else {
                Logger.error("Null url received on play")
                result(0)
                return
            }
            
            let isLocal: Bool = (args["isLocal"] as? Bool) ?? true
            let volume: Double = (args["volume"] as? Double) ?? 1.0
            
            // we might or might not want to seek
            let seekTimeMillis: Int = (args["position"] as? Int) ?? 0
            let seekTime: CMTime = toCMTime(millis: seekTimeMillis)
            
            let respectSilence: Bool = (args["respectSilence"] as? Bool) ?? false
            let recordingActive: Bool = (args["recordingActive"] as? Bool) ?? false
            let duckAudio: Bool = (args["duckAudio"] as? Bool) ?? false
            
            player.play(
                url: url,
                isLocal: isLocal,
                volume: volume,
                time: seekTime,
                isNotification: respectSilence,
                recordingActive: recordingActive,
                duckAudio: duckAudio
            )
        } else if method == "pause" {
            player.pause()
        } else if method == "resume" {
            player.resume()
        } else if method == "stop" {
            player.stop()
        } else if method == "release" {
            player.release()
        } else if method == "seek" {
            let position = args["position"] as? Int
            if let position = position {
                let time = toCMTime(millis: position)
                player.seek(time: time)
            } else {
                Logger.error("Null position received on seek")
                result(0)
            }
        } else if method == "setUrl" {
            let url: String? = args["url"] as? String
            let isLocal: Bool = (args["isLocal"] as? Bool) ?? false
            let respectSilence: Bool = (args["respectSilence"] as? Bool) ?? false
            let recordingActive: Bool = (args["recordingActive"] as? Bool) ?? false
            
            if url == nil {
                Logger.error("Null URL received on setUrl")
                result(0)
                return
            }
            
            player.setUrl(
                url: url!,
                isLocal: isLocal,
                isNotification: respectSilence,
                recordingActive: recordingActive,
                duckAudio: false
            ) {
                player in
                result(1)
            }
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
        } else if method == "getCurrentPosition" {
            let currentPosition = player.getCurrentPosition()
            result(currentPosition)
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
            let looping = releaseMode.hasSuffix("LOOP")
            player.looping = looping
        } else if method == "earpieceOrSpeakersToggle" {
            guard let playingRoute = args["playingRoute"] as? String else {
                Logger.error("Error calling earpieceOrSpeakersToggle, playingRoute cannot be null")
                result(0)
                return
            }
            self.setPlayingRoute(playerId: playerId, playingRoute: playingRoute)
        } else if method == "setNotification" {
            let title = args["title"] as? String
            let albumTitle = args["albumTitle"] as? String
            let artist = args["artist"] as? String
            let imageUrl = args["imageUrl"] as? String
            
            let forwardSkipInterval = args["forwardSkipInterval"] as? Int
            let backwardSkipInterval = args["backwardSkipInterval"] as? Int
            let duration = args["duration"] as? Int
            let elapsedTime = args["elapsedTime"] as? Int
            
            let enablePreviousTrackButton = args["enablePreviousTrackButton"] as? Bool
            let enableNextTrackButton = args["enableNextTrackButton"] as? Bool
            
            guard let handler = notificationsHandler else {
                result(FlutterMethodNotImplemented)
                return
            }
            // TODO(luan) reconsider whether these params are optional or not + default values/errors
            handler.setNotification(
                playerId: playerId,
                title: title,
                albumTitle: albumTitle,
                artist: artist,
                imageUrl: imageUrl,
                forwardSkipInterval: forwardSkipInterval ?? 0,
                backwardSkipInterval: backwardSkipInterval ?? 0,
                duration: duration,
                elapsedTime: elapsedTime!,
                enablePreviousTrackButton: enablePreviousTrackButton,
                enableNextTrackButton: enableNextTrackButton
            )
        } else if method == "clearNotification" {
            guard let handler = notificationsHandler else {
                result(FlutterMethodNotImplemented)
                return
            }
            handler.clearNotification()
            player.release()
        } else {
            Logger.error("Called not implemented method: %@", method)
            result(FlutterMethodNotImplemented)
            return
        }
        
        // shortcut to avoid requiring explicit call of result(1) everywhere
        if method != "setUrl" {
            result(1)
        }
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
    
    func onSeekCompleted(playerId: String, finished: Bool) {
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
    
    func onNotificationPlayerStateChanged(playerId: String, isPlaying: Bool) {
        channel.invokeMethod("audio.onNotificationPlayerStateChanged", arguments: ["playerId": playerId, "value": isPlaying])
    }
    
    func onGotPreviousTrackCommand(playerId: String) {
        channel.invokeMethod("audio.onGotPreviousTrackCommand", arguments: ["playerId": playerId])
    }
    
    func onGotNextTrackCommand(playerId: String) {
        channel.invokeMethod("audio.onGotNextTrackCommand", arguments: ["playerId": playerId])
    }
    
    func updateCategory(
        recordingActive: Bool,
        isNotification: Bool,
        playingRoute: String,
        duckAudio: Bool
    ) {
        #if os(iOS)
        // When using AVAudioSessionCategoryPlayback, by default, this implies that your app’s audio is nonmixable—activating your session
        // will interrupt any other audio sessions which are also nonmixable. AVAudioSessionCategoryPlayback should not be used with
        // AVAudioSessionCategoryOptionMixWithOthers option. If so, it prevents infoCenter from working correctly.
        let category = (playingRoute == "earpiece" || recordingActive) ? AVAudioSession.Category.playAndRecord : (
            isNotification ? AVAudioSession.Category.ambient : AVAudioSession.Category.playback
        )
        let options = isNotification || duckAudio ? AVAudioSession.CategoryOptions.mixWithOthers : []
        
        configureAudioSession(category: category, options: options)
        if isNotification {
            UIApplication.shared.beginReceivingRemoteControlEvents()
        }
        #endif
    }
    
    func maybeDeactivateAudioSession() {
        let hasPlaying = players.values.contains { player in player.isPlaying }
        if !hasPlaying {
            #if os(iOS)
            configureAudioSession(active: false)
            #endif
        }
    }
    
    func lastPlayer() -> WrappedMediaPlayer? {
        if let playerId = lastPlayerId {
            return getOrCreatePlayer(playerId: playerId)
        } else {
            return nil
        }
    }

    func updateNotifications(player: WrappedMediaPlayer, time: CMTime) {
        notificationsHandler?.update(playerId: player.playerId, time: time, playbackRate: player.playbackRate)
    }
    
    // TODO(luan) this should not be here. is playingRoute player-specific or global?
    func setPlayingRoute(playerId: String, playingRoute: String) {
        let wrappedPlayer = players[playerId]!
        wrappedPlayer.playingRoute = playingRoute
        
        #if os(iOS)
        let category = playingRoute == "earpiece" ? AVAudioSession.Category.playAndRecord : AVAudioSession.Category.playback
        configureAudioSession(category: category)
        #endif
    }
    
    #if os(iOS)
    private func configureAudioSession(
        category: AVAudioSession.Category? = nil,
        options: AVAudioSession.CategoryOptions = [],
        active: Bool? = nil
    ) {
        do {
            let session = AVAudioSession.sharedInstance()
            if let category = category {
                try session.setCategory(category, options: options)
            }
            if let active = active {
                try session.setActive(active)
            }
        } catch {
            Logger.error("Error configuring audio session: %@", error)
        }
    }
    #endif
}
