import AudioToolbox
import Flutter

/// Vibrates during the coverage sound while the app is in the background. The
/// vibration package uses Core Haptics, which iOS only runs for an app in the
/// foreground; the system vibration also works in the background. It can't
/// follow the sound's loudness like the foreground pattern does, so it pulses
/// for as long as the sound plays.
final class AlertVibration {
  static let channelName = "fylgja/notifications"

  /// The system vibration lasts about 0.4 s; this leaves a short gap between pulses.
  private static let pulseInterval: TimeInterval = 0.8

  private var timer: Timer?

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "startVibration":
        let args = call.arguments as? [String: Any]
        let durationMs = args?["durationMs"] as? Int ?? 0
        self.start(duration: TimeInterval(durationMs) / 1000)
        result(nil)
      case "stopVibration":
        self.stop()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func start(duration: TimeInterval) {
    stop()
    let end = Date().addingTimeInterval(duration)
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    timer = Timer.scheduledTimer(withTimeInterval: Self.pulseInterval, repeats: true) { [weak self] _ in
      guard Date() < end else {
        self?.stop()
        return
      }
      AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
  }

  private func stop() {
    timer?.invalidate()
    timer = nil
  }
}
