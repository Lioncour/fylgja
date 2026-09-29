import Flutter
import Network

/// Detects coverage natively on iOS, the counterpart of Android's
/// ConnectivityMonitoringService: same `fylgja/connectivity` methods and the
/// same `coverage_found` event on `fylgja/events`. Like the Android service it
/// reports coverage once and then stops detecting until the next
/// `startMonitoring` (a new search or the end of a pause).
///
/// BackgroundKeepAlive keeps the app running for the whole search, including
/// pauses, so the Dart pause timer and the alert also work with the screen
/// locked.
final class CoverageMonitor: NSObject, FlutterStreamHandler {
  static let methodChannelName = "fylgja/connectivity"
  static let eventChannelName = "fylgja/events"

  /// Same check as the Dart side and Android's NET_CAPABILITY_VALIDATED: a
  /// network interface being up doesn't mean data gets through (no signal, a
  /// captive portal), so coverage needs a real response.
  private static let probeURL = URL(string: "https://www.google.com/generate_204")!
  private static let probeInterval: DispatchTimeInterval = .seconds(3)

  private let keepAlive = BackgroundKeepAlive()
  private var eventSink: FlutterEventSink?

  // Everything below is only touched on `queue`.
  private let queue = DispatchQueue(label: "no.fylgja.coverage-monitor")
  private var pathMonitor: NWPathMonitor?
  private var probeTimer: DispatchSourceTimer?
  private var isProbing = false
  /// Bumped on every start and stop, so a probe that finishes after the search
  /// was stopped or restarted is ignored.
  private var generation = 0

  private let probeSession: URLSession = {
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 5
    config.timeoutIntervalForResource = 5
    config.requestCachePolicy = .reloadIgnoringLocalCacheData
    return URLSession(configuration: config)
  }()

  func register(with messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(name: Self.methodChannelName, binaryMessenger: messenger)
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "startMonitoring":
        result(self.start())
      case "stopMonitoring":
        self.stop()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    FlutterEventChannel(name: Self.eventChannelName, binaryMessenger: messenger)
      .setStreamHandler(self)
  }

  /// Returns whether the search keeps running with the screen locked.
  private func start() -> Bool {
    let keepsRunning = keepAlive.start()
    queue.async { self.startDetection() }
    return keepsRunning
  }

  private func stop() {
    keepAlive.stop()
    queue.async { self.stopDetection() }
  }

  private func startDetection() {
    stopDetection()
    let current = generation

    let monitor = NWPathMonitor()
    monitor.pathUpdateHandler = { [weak self] path in
      guard let self, current == self.generation, path.status == .satisfied else { return }
      self.probe(current)
    }
    monitor.start(queue: queue)
    pathMonitor = monitor

    // The path can be satisfied long before data gets through, and then no new
    // path update comes, so keep probing while it is.
    let timer = DispatchSource.makeTimerSource(queue: queue)
    timer.schedule(deadline: .now() + Self.probeInterval, repeating: Self.probeInterval)
    timer.setEventHandler { [weak self] in
      guard let self, current == self.generation,
            self.pathMonitor?.currentPath.status == .satisfied else { return }
      self.probe(current)
    }
    timer.resume()
    probeTimer = timer

    NSLog("CoverageMonitor: detection started")
  }

  private func stopDetection() {
    generation += 1
    pathMonitor?.cancel()
    pathMonitor = nil
    probeTimer?.cancel()
    probeTimer = nil
    isProbing = false
  }

  private func probe(_ current: Int) {
    guard !isProbing else { return }
    isProbing = true
    probeSession.dataTask(with: Self.probeURL) { [weak self] _, response, _ in
      guard let self else { return }
      self.queue.async {
        guard current == self.generation else { return }
        self.isProbing = false
        if (response as? HTTPURLResponse)?.statusCode == 204 {
          self.coverageFound()
        }
      }
    }.resume()
  }

  private func coverageFound() {
    NSLog("CoverageMonitor: coverage found")
    stopDetection()
    DispatchQueue.main.async {
      self.eventSink?("coverage_found")
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
