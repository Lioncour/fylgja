import CoreLocation
import Flutter

/// Keeps the app running while the screen is locked, so the search and the
/// coverage sound keep working. iOS suspends an app shortly after it goes to
/// the background unless it has an active background mode; continuous location
/// updates (UIBackgroundModes: location) are that mode here. The position is
/// also what the statistics page stores when coverage is found.
///
/// Uses the same `fylgja/connectivity` channel as Android's
/// ConnectivityMonitoringService, so the Dart side calls it the same way.
final class BackgroundKeepAlive: NSObject, CLLocationManagerDelegate {
  static let channelName = "fylgja/connectivity"

  private let locationManager = CLLocationManager()
  private var isRunning = false

  override init() {
    super.init()
    locationManager.delegate = self
    // Staying alive is the point, not precision: coarse accuracy and a large
    // distance filter keep the GPS mostly off and the battery cost low.
    locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    locationManager.distanceFilter = 500
    locationManager.activityType = .other
    // Without this iOS stops the updates when the user stands still, and the
    // app is suspended with them.
    locationManager.pausesLocationUpdatesAutomatically = false
  }

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "startMonitoring":
        self.start(result: result)
      case "stopMonitoring":
        self.stop()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func start(result: FlutterResult) {
    switch locationManager.authorizationStatus {
    case .denied, .restricted:
      result(FlutterError(
        code: "location_denied",
        message: "Location access is needed to keep searching with the screen locked",
        details: nil))
      return
    case .notDetermined:
      // Updates start on their own once the user answers.
      locationManager.requestWhenInUseAuthorization()
    default:
      break
    }

    // "When in use" is enough: updates started in the foreground continue in
    // the background, shown to the user by the blue location indicator.
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.showsBackgroundLocationIndicator = true
    locationManager.startUpdatingLocation()
    isRunning = true
    NSLog("BackgroundKeepAlive: started")
    result(nil)
  }

  private func stop() {
    guard isRunning else { return }
    locationManager.stopUpdatingLocation()
    locationManager.allowsBackgroundLocationUpdates = false
    isRunning = false
    NSLog("BackgroundKeepAlive: stopped")
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // Only needed to keep the app running; the Dart side reads the position
    // itself when coverage is found.
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    NSLog("BackgroundKeepAlive: location error: \(error.localizedDescription)")
  }
}
