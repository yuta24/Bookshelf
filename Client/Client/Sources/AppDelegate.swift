import UIKit
import FirebaseCore
import FirebaseAnalytics
import FirebaseMessaging
import Pulse
import Infrastructure

final class AppDelegate: UIResponder, UIApplicationDelegate {
    let persistence: PersistenceController = .shared

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        Analytics.logEvent("app_launch", parameters: nil)
        URLSessionProxyDelegate.enableAutomaticRegistration()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        return true
    }

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig: UISceneConfiguration = .init(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {}

extension AppDelegate: MessagingDelegate {}
