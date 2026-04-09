import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let phoneAuthGuardChannel = "jp.keygo.poigo/phone_auth_guard"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: phoneAuthGuardChannel,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        if call.method == "isIosSimulator" {
          #if targetEnvironment(simulator)
          result(true)
          #else
          result(false)
          #endif
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
