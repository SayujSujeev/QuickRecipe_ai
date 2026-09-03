import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let shareGroupId = "group.com.sayujsujeev.cooksense"
  private let pendingSharesKey = "pendingRecipeShares"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "CookSenseShareIntake"
    ) else { return }
    let channel = FlutterMethodChannel(
      name: "com.sayujsujeev.cooksense/share",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "drainPendingShares" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(self?.drainPendingShares() ?? [])
    }
  }

  private func drainPendingShares() -> [[String: Any]] {
    guard let defaults = UserDefaults(suiteName: shareGroupId),
          let data = defaults.data(forKey: pendingSharesKey),
          let values = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { return [] }

    defaults.removeObject(forKey: pendingSharesKey)
    return values
  }
}
