import MediaPlayer

// no-op impl of AudioContext for macos
struct AudioContext {
    func activateAudioSession(active: Bool) {}

    func apply() {
        Logger.error("AudioContext configuration is not available on macOS")
    }

    static func parse(args: [String: Any]) -> AudioContext? {
        return AudioContext()
    }
}
