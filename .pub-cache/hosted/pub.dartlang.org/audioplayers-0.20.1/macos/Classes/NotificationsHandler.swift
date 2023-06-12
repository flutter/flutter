#if os(iOS)
import MediaPlayer
#endif

class NotificationsHandler {
    private let reference: SwiftAudioplayersPlugin
    
    #if os(iOS)
    private var infoCenter: MPNowPlayingInfoCenter? = nil
    private var remoteCommandCenter: MPRemoteCommandCenter? = nil
    #endif
    
    private var headlessServiceInitialized = false
    private var headlessEngine: FlutterEngine?
    private var callbackChannel: FlutterMethodChannel?
    private var updateHandleMonitorKey: Int64? = nil
    
    private var title: String? = nil
    private var albumTitle: String? = nil
    private var artist: String? = nil
    private var imageUrl: String? = nil
    private var duration: Int? = nil
        
    init(reference: SwiftAudioplayersPlugin) {
        self.reference = reference
        self.initHeadlessService()
    }
    
    func initHeadlessService() {
        #if os(iOS)
        // this method is used to listen to audio playpause event
        // from the notification area in the background.
        let headlessEngine = FlutterEngine.init(name: "AudioPlayerIsolate")
        // This is the method channel used to communicate with
        // `_backgroundCallbackDispatcher` defined in the Dart portion of our plugin.
        // Note: we don't add a MethodCallDelegate for this channel now since our
        // BinaryMessenger needs to be initialized first, which is done in
        // `startHeadlessService` below.
        self.headlessEngine = headlessEngine
        self.callbackChannel = FlutterMethodChannel(
            name: "xyz.luan/audioplayers_callback",
            binaryMessenger: headlessEngine.binaryMessenger
        )
        #endif
    }
    
    // Initializes and starts the background isolate which will process audio
    // events. `handle` is the handle to the callback dispatcher which we specified
    // in the Dart portion of the plugin.
    func startHeadlessService(handle: Int64) {
        guard let headlessEngine = self.headlessEngine else { return }
        guard let callbackChannel = self.callbackChannel else { return }
        
        #if os(iOS)
        // Lookup the information for our callback dispatcher from the callback cache.
        // This cache is populated when `PluginUtilities.getCallbackHandle` is called
        // and the resulting handle maps to a `FlutterCallbackInformation` object.
        // This object contains information needed by the engine to start a headless
        // runner, which includes the callback name as well as the path to the file
        // containing the callback.
        let info = FlutterCallbackCache.lookupCallbackInformation(handle)!
        let entrypoint = info.callbackName
        let uri = info.callbackLibraryPath
        
        // Here we actually launch the background isolate to start executing our
        // callback dispatcher, `_backgroundCallbackDispatcher`, in Dart.
        self.headlessServiceInitialized = headlessEngine.run(withEntrypoint: entrypoint, libraryURI: uri)
        if self.headlessServiceInitialized {
            // The headless runner needs to be initialized before we can register it as a
            // MethodCallDelegate or else we get an illegal memory access. If we don't
            // want to make calls from `_backgroundCallDispatcher` back to native code,
            // we don't need to add a MethodCallDelegate for this channel.
            self.reference.registrar.addMethodCallDelegate(reference, channel: callbackChannel)
        }
        #endif
    }
    
    func updateHandleMonitorKey(handle: Int64) {
        self.updateHandleMonitorKey = handle
    }
    
    func onNotificationBackgroundPlayerStateChanged(playerId: String, value: String) {
        if headlessServiceInitialized {
            guard let callbackChannel = self.callbackChannel else { return }
            guard let updateHandleMonitorKey = self.updateHandleMonitorKey else { return }
            
            callbackChannel.invokeMethod(
                "audio.onNotificationBackgroundPlayerStateChanged",
                arguments: [
                    "playerId": playerId,
                    "updateHandleMonitorKey": updateHandleMonitorKey as Any,
                    "value": value
                ]
            )
        }
    }
    
    func update(playerId: String, time: CMTime, playbackRate: Double) {
        #if os(iOS)
        updateForIos(playerId: playerId, time: time, playbackRate: playbackRate)
        #else
        // not implemented for macos
        #endif
    }
    
    func setNotification(
        playerId: String,
        title: String?,
        albumTitle: String?,
        artist: String?,
        imageUrl: String?,
        forwardSkipInterval: Int,
        backwardSkipInterval: Int,
        duration: Int?,
        elapsedTime: Int,
        enablePreviousTrackButton: Bool?,
        enableNextTrackButton: Bool?
    ) {
        #if os(iOS)
        setNotificationForIos(
            playerId: playerId,
            title: title,
            albumTitle: albumTitle,
            artist: artist,
            imageUrl: imageUrl,
            forwardSkipInterval: forwardSkipInterval,
            backwardSkipInterval: backwardSkipInterval,
            duration: duration,
            elapsedTime: elapsedTime,
            enablePreviousTrackButton: enablePreviousTrackButton,
            enableNextTrackButton: enableNextTrackButton
        )
        #else
        // not implemented for macos
        #endif
    }
    
    func clearNotification() {
        self.title = nil
        self.albumTitle = nil
        self.artist = nil
        self.imageUrl = nil

        #if os(iOS)
        // Set both the nowPlayingInfo and infoCenter to nil so
        // we clear all the references to the notification
        self.infoCenter?.nowPlayingInfo = nil
        self.infoCenter = nil
        #endif
    }
    
    #if os(iOS)
    static func geneateImageFromUrl(urlString: String) -> UIImage? {
        if urlString.hasPrefix("http") {
            guard let url: URL = URL.init(string: urlString) else {
                Logger.error("Error download image url, invalid url %@", urlString)
                return nil
            }
            do {
                let data = try Data(contentsOf: url)
                return UIImage.init(data: data)
            } catch {
                Logger.error("Error download image url %@", error)
                return nil
            }
        } else {
            return UIImage.init(contentsOfFile: urlString)
        }
    }
    
    func updateForIos(playerId: String, time: CMTime, playbackRate: Double) {
        if (infoCenter == nil || playerId != reference.lastPlayerId) {
            return
        }
        // From `MPNowPlayingInfoPropertyElapsedPlaybackTime` docs -- it is not recommended to update this value frequently.
        // Thus it should represent integer seconds and not an accurate `CMTime` value with fractions of a second
        let elapsedTime = Int(time.seconds)
        
        var playingInfo: [String: Any?] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyAlbumTitle: albumTitle,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsedTime,
            MPNowPlayingInfoPropertyPlaybackRate: Float(playbackRate)
        ]
        
        Logger.info("Updating playing info...")
        
        // fetch notification image in async fashion to avoid freezing UI
        DispatchQueue.global().async() { [weak self] in
            if let imageUrl = self?.imageUrl {
                let artworkImage = NotificationsHandler.geneateImageFromUrl(urlString: imageUrl)
                if let artworkImage = artworkImage {
                    if #available(iOS 10, *) {
                        let albumArt = MPMediaItemArtwork.init(
                            boundsSize: artworkImage.size,
                            requestHandler: { (size) -> UIImage in
                                return artworkImage
                            }
                        )
                        playingInfo[MPMediaItemPropertyArtwork] = albumArt
                    } else {
                        let albumArt = MPMediaItemArtwork.init(image: artworkImage)
                        playingInfo[MPMediaItemPropertyArtwork] = albumArt
                    }
                    Logger.info("Will add custom album art")
                }
            }
            
            if let infoCenter = self?.infoCenter {
                let filteredMap = playingInfo.filter { $0.value != nil }.mapValues { $0! }
                Logger.info("Setting playing info: %@", filteredMap)
                infoCenter.nowPlayingInfo = filteredMap
            }
        }
    }
    
    func setNotificationForIos(
        playerId: String,
        title: String?,
        albumTitle: String?,
        artist: String?,
        imageUrl: String?,
        forwardSkipInterval: Int,
        backwardSkipInterval: Int,
        duration: Int?,
        elapsedTime: Int,
        enablePreviousTrackButton: Bool?,
        enableNextTrackButton: Bool?
    ) {
        self.title = title
        self.albumTitle = albumTitle
        self.artist = artist
        self.imageUrl = imageUrl
        self.duration = duration
        
        self.infoCenter = MPNowPlayingInfoCenter.default()
        reference.lastPlayerId = playerId
        reference.updateNotifications(player: reference.lastPlayer()!, time: toCMTime(millis: elapsedTime))
        
        if (remoteCommandCenter == nil) {
            remoteCommandCenter = MPRemoteCommandCenter.shared()
            
            if (forwardSkipInterval > 0 || backwardSkipInterval > 0) {
                let skipBackwardIntervalCommand = remoteCommandCenter!.skipBackwardCommand
                skipBackwardIntervalCommand.isEnabled = true
                skipBackwardIntervalCommand.addTarget(handler: self.skipBackwardEvent)
                skipBackwardIntervalCommand.preferredIntervals = [backwardSkipInterval as NSNumber]
                
                let skipForwardIntervalCommand = remoteCommandCenter!.skipForwardCommand
                skipForwardIntervalCommand.isEnabled = true
                skipForwardIntervalCommand.addTarget(handler: self.skipForwardEvent)
                skipForwardIntervalCommand.preferredIntervals = [forwardSkipInterval as NSNumber] // Max 99
            } else {  // if skip interval not set using next and previous
                let nextTrackCommand = remoteCommandCenter!.nextTrackCommand
                nextTrackCommand.isEnabled = enableNextTrackButton ?? false
                nextTrackCommand.addTarget(handler: self.nextTrackEvent)
                
                let previousTrackCommand = remoteCommandCenter!.previousTrackCommand
                previousTrackCommand.isEnabled = enablePreviousTrackButton ?? false
                previousTrackCommand.addTarget(handler: self.previousTrackEvent)
            }
            
            let pauseCommand = remoteCommandCenter!.pauseCommand
            pauseCommand.isEnabled = true
            pauseCommand.addTarget(handler: self.playOrPauseEvent)
            
            let playCommand = remoteCommandCenter!.playCommand
            playCommand.isEnabled = true
            playCommand.addTarget(handler: self.playOrPauseEvent)
            
            let togglePlayPauseCommand = remoteCommandCenter!.togglePlayPauseCommand
            togglePlayPauseCommand.isEnabled = true
            togglePlayPauseCommand.addTarget(handler: self.playOrPauseEvent)
            
            if #available(iOS 9.1, *) {
                let changePlaybackPositionCommand = remoteCommandCenter!.changePlaybackPositionCommand
                changePlaybackPositionCommand.isEnabled = true
                changePlaybackPositionCommand.addTarget(handler: self.onChangePlaybackPositionCommand)
            }
        }
    }
    
    func skipBackwardEvent(skipEvent: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        let interval = (skipEvent as! MPSkipIntervalCommandEvent).interval
        Logger.info("Skip backward by %f", interval)
        
        guard let player = reference.lastPlayer() else {
            return MPRemoteCommandHandlerStatus.commandFailed
        }
        
        player.skipBackward(interval: interval)
        return MPRemoteCommandHandlerStatus.success
    }
    
    func skipForwardEvent(skipEvent: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        let interval = (skipEvent as! MPSkipIntervalCommandEvent).interval
        Logger.info("Skip forward by %f", interval)
        
        guard let player = reference.lastPlayer() else {
            return MPRemoteCommandHandlerStatus.commandFailed
        }
        
        player.skipForward(interval: interval)
        return MPRemoteCommandHandlerStatus.success
    }
    
    func nextTrackEvent(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        guard let player = reference.lastPlayer() else {
            return MPRemoteCommandHandlerStatus.commandFailed
        }
        reference.onGotNextTrackCommand(playerId: player.playerId)
        return MPRemoteCommandHandlerStatus.success
    }
    
    func previousTrackEvent(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        guard let player = reference.lastPlayer() else {
            return MPRemoteCommandHandlerStatus.commandFailed
        }
        reference.onGotPreviousTrackCommand(playerId: player.playerId)
        return MPRemoteCommandHandlerStatus.success
    }
    
    func playOrPauseEvent(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        guard let player = reference.lastPlayer() else {
            return MPRemoteCommandHandlerStatus.commandFailed
        }
        
        // TODO(luan) incorporate this into WrappedMediaPlayer
        let playerState: String
        if #available(iOS 10.0, *) {
            if (player.isPlaying) {
                player.pause()
                playerState = "paused"
            } else {
                player.resume()
                playerState = "playing"
            }
        } else {
            // No fallback on earlier versions
            return MPRemoteCommandHandlerStatus.commandFailed
        }
        
        reference.onNotificationPlayerStateChanged(playerId: player.playerId, isPlaying: player.isPlaying)
        onNotificationBackgroundPlayerStateChanged(playerId: player.playerId, value: playerState)
        
        return MPRemoteCommandHandlerStatus.success
        
    }
    
    func onChangePlaybackPositionCommand(changePositionEvent: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        guard let player = reference.lastPlayer() else {
            return MPRemoteCommandHandlerStatus.commandFailed
        }
        
        let positionTime = (changePositionEvent as! MPChangePlaybackPositionCommandEvent).positionTime
        Logger.info("changePlaybackPosition to %f", positionTime)
        let newTime = toCMTime(millis: positionTime)
        player.seek(time: newTime)
        return MPRemoteCommandHandlerStatus.success
    }
    
    #endif
}
