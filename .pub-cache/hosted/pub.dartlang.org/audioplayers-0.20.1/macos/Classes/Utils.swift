import AVKit

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}

func toCMTime(millis: Int) -> CMTime {
    return toCMTime(millis: Float(millis))
}

func toCMTime(millis: Double) -> CMTime {
    return toCMTime(millis: Float(millis))
}

func toCMTime(millis: Float) -> CMTime {
    return CMTimeMakeWithSeconds(Float64(millis) / 1000, preferredTimescale: Int32(NSEC_PER_SEC))
}

func fromCMTime(time: CMTime) -> Int {
    let seconds: Float64 = CMTimeGetSeconds(time)
    let milliseconds: Int = Int(seconds * 1000)
    return milliseconds
}

class TimeObserver {
    let player: AVPlayer
    let observer: Any
    
    init(
        player: AVPlayer,
        observer: Any
    ) {
        self.player = player
        self.observer = observer
    }
}
