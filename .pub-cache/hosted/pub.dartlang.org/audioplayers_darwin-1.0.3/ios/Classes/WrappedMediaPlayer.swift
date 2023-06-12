import AVKit

private let defaultPlaybackRate: Double = 1.0
private let defaultVolume: Double = 1.0
private let defaultLooping: Bool = false

typealias Completer = () -> Void

class WrappedMediaPlayer {
    var reference: SwiftAudioplayersDarwinPlugin
    
    var playerId: String
    var player: AVPlayer?
    
    var observers: [TimeObserver]
    var keyValueObservation: NSKeyValueObservation?
    
    var isPlaying: Bool
    var playbackRate: Double
    var volume: Double
    var looping: Bool

    var url: String?
    
    init(
        reference: SwiftAudioplayersDarwinPlugin,
        playerId: String,
        player: AVPlayer? = nil,
        playbackRate: Double = defaultPlaybackRate,
        volume: Double = defaultVolume,
        looping: Bool = defaultLooping,
        url: String? = nil
    ) {
        self.reference = reference
        self.playerId = playerId
        self.player = player
        self.observers = []
        self.keyValueObservation = nil
        
        self.isPlaying = false
        self.playbackRate = playbackRate
        self.volume = volume
        self.looping = looping
        self.url = url
    }
    
    func dispose() {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer.observer)
        }
        keyValueObservation?.invalidate()
        observers = []
    }
    
    func getDurationCMTime() -> CMTime? {
        return player?.currentItem?.asset.duration
    }
    
    func getDuration() -> Int? {
        guard let duration = getDurationCMTime() else {
            return nil
        }
        return fromCMTime(time: duration)
    }
    
    private func getCurrentCMTime() -> CMTime? {
        return player?.currentTime()
    }
    
    func getCurrentPosition() -> Int? {
        guard let time = getCurrentCMTime() else {
            return nil
        }
        return fromCMTime(time: time)
    }
    
    func pause() {
        isPlaying = false
        player?.pause()
    }
    
    func resume() {
        isPlaying = true
        if let player = self.player {
            configParameters(player: player)
            if #available(iOS 10.0, macOS 10.12, *) {
                player.playImmediately(atRate: Float(playbackRate))
            } else {
                player.play()
            }
            updateDuration()
        }
    }
    
    func setVolume(volume: Double) {
        self.volume = volume
        player?.volume = Float(volume)
    }
    
    func setPlaybackRate(playbackRate: Double) {
        self.playbackRate = playbackRate
        player?.rate = Float(playbackRate)
    }
    
    func seek(time: CMTime, completer: Completer? = nil) {
        guard let currentItem = player?.currentItem else {
            completer?()
            return
        }
        currentItem.seek(to: time) {
            finished in
            if !self.isPlaying {
                self.player?.pause()
            }
            self.reference.onSeekComplete(playerId: self.playerId, finished: finished)
            if (finished) {
                completer?()
            }
        }
    }
    
    func stop(completer: Completer? = nil) {
        pause()
        seek(time: toCMTime(millis: 0), completer: completer)
    }
    
    func release(completer: Completer? = nil) {
        stop {
            self.dispose()
            completer?()
        }
    }
    
    func onSoundComplete() {
        if !isPlaying {
            return
        }

        seek(time: toCMTime(millis: 0)) {
            if self.looping {
                self.resume()
            } else {
                self.isPlaying = false
            }
        }
        
        reference.controlAudioSession()
        reference.onComplete(playerId: playerId)
    }
    
    func onTimeInterval(time: CMTime) {
        let millis = fromCMTime(time: time)
        reference.onCurrentPosition(playerId: playerId, millis: millis)
    }
    
    func updateDuration() {
        guard let duration = player?.currentItem?.asset.duration else {
            return
        }
        if CMTimeGetSeconds(duration) > 0 {
            let millis = fromCMTime(time: duration)
            reference.onDuration(playerId: playerId, millis: millis)
        }
    }
    
    func setSourceUrl(
        url: String,
        isLocal: Bool,
        completer: Completer? = nil
    ) {
        let playbackStatus = player?.currentItem?.status
        
        if self.url != url || playbackStatus == .failed || playbackStatus == nil {
            let parsedUrl = isLocal ? URL.init(fileURLWithPath: url.deletingPrefix("file://")) : URL.init(string: url)!
            let playerItem = AVPlayerItem.init(url: parsedUrl)
            playerItem.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm.timeDomain
            let player: AVPlayer
            if let existingPlayer = self.player {
                keyValueObservation?.invalidate()
                self.url = url
                dispose()
                existingPlayer.replaceCurrentItem(with: playerItem)
                player = existingPlayer
            } else {
                player = AVPlayer.init(playerItem: playerItem)
                configParameters(player: player)
                
                self.player = player
                self.observers = []
                self.url = url
                
                // stream player position
                let interval = toCMTime(millis: 0.2)
                let timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: nil) {
                    [weak self] time in
                    self!.onTimeInterval(time: time)
                }
                self.observers.append(TimeObserver(player: player, observer: timeObserver))
            }
            
            let anObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: nil
            ) {
                [weak self] (notification) in
                self!.onSoundComplete()
            }
            self.observers.append(TimeObserver(player: player, observer: anObserver))
            
            // is sound ready
            let newKeyValueObservation = playerItem.observe(\AVPlayerItem.status) { (playerItem, change) in
                let status = playerItem.status
                Logger.info("player status: %@ change: %@", status, change)
                
                if status == .readyToPlay {
                    self.updateDuration()
                    completer?()
                } else if status == .failed {
                    self.reference.onError(playerId: self.playerId)
                }
            }
            
            keyValueObservation?.invalidate()
            keyValueObservation = newKeyValueObservation
        } else {
            if playbackStatus == .readyToPlay {
                completer?()
            }
        }
    }

    func configParameters(player: AVPlayer) {
        if (isPlaying) {
            player.volume = Float(volume)
            player.rate = Float(playbackRate)
        }
    }
}
