/// A description
import Flutter
import UIKit
import GoogleMaps // <-- 1. Burayı ekledik

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 2. Kopyaladığın API anahtarını buraya yapıştırıyoruz
    GMSServices.provideAPIKey("AIzaSyD3P98B7U8QlZx0xo9R5M6arOlrekWfsxQ")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}