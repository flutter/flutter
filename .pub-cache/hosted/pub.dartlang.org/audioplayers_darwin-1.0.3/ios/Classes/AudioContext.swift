import MediaPlayer

struct AudioContext {
    let category: AVAudioSession.Category
    let options: [AVAudioSession.CategoryOptions]
    let defaultToSpeaker: Bool
    
    init() {
        self.category = .playAndRecord
        self.options = [.mixWithOthers]
        self.defaultToSpeaker = false
    }
    
    init(
        category: AVAudioSession.Category,
        options: [AVAudioSession.CategoryOptions],
        defaultToSpeaker: Bool
    ) {
        self.category = category
        self.options = options
        self.defaultToSpeaker = defaultToSpeaker
    }
    
    func activateAudioSession(
        active: Bool
    ) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(active)
        } catch {
            Logger.error("Error configuring audio session: %@", error)
        }
    }

    func apply() {
        do {
            let session = AVAudioSession.sharedInstance()
            let combinedOptions = options.reduce(AVAudioSession.CategoryOptions()) { [$0, $1] }
            try session.setCategory(category, options: combinedOptions)
        } catch {
            Logger.error("Error configuring audio session: %@", error)
        }
    }

    static func parse(args: [String: Any]) -> AudioContext? {
        guard let categoryString = args["category"] as! String? else {
            Logger.error("Null value received for category")
            return nil
        }
        guard let category = parseCategory(category: categoryString) else {
            return nil
        }
        
        guard let optionStrings = args["options"] as! [String]? else {
            Logger.error("Null value received for options")
            return nil
        }
        let options = optionStrings.compactMap { parseCategoryOption(option: $0) }
        if (optionStrings.count != options.count) {
            return nil
        }
        
        guard let defaultToSpeaker = args["defaultToSpeaker"] as! Bool? else {
            Logger.error("Null value received for defaultToSpeaker")
            return nil
        }
        
        return AudioContext(
            category: category,
            options: options,
            defaultToSpeaker: defaultToSpeaker
        )
    }

    private static func parseCategory(category: String) -> AVAudioSession.Category? {
        switch category {
        case "ambient":
            return .ambient
        case "soloAmbient":
            return .soloAmbient
        case "playback":
            return .playback
        case "record":
            return .record
        case "playAndRecord":
            return .playAndRecord
        case "audioProcessing":
            return .audioProcessing
        case "multiRoute":
            return .multiRoute
        default:
            Logger.error("Invalid Category %@", category)
            return nil
        }
    }
    
    private static func parseCategoryOption(option: String) -> AVAudioSession.CategoryOptions? {
        switch option {
        case "mixWithOthers":
            return .mixWithOthers
        case "duckOthers":
            return .duckOthers
        case "allowBluetooth":
            return .allowBluetooth
        case "defaultToSpeaker":
            return .defaultToSpeaker
        case "interruptSpokenAudioAndMixWithOthers":
            return .interruptSpokenAudioAndMixWithOthers
        case "allowBluetoothA2DP":
            if #available(iOS 10.0, *) {
                return .allowBluetoothA2DP
            } else {
                Logger.error("Category Option allowBluetoothA2DP is only available on iOS 10+")
                return nil
            }
        case "allowAirPlay":
            if #available(iOS 10.0, *) {
                return .allowAirPlay
            } else {
                Logger.error("Category Option allowAirPlay is only available on iOS 10+")
                return nil
            }
        case "overrideMutedMicrophoneInterruption":
            if #available(iOS 14.5, *) {
                return .overrideMutedMicrophoneInterruption
            } else {
                Logger.error("Category Option overrideMutedMicrophoneInterruption is only available on iOS 14.5+")
                return nil
            }
        default:
            Logger.error("Invalid Category Option %@", option)
            return nil
        }
    }
}
