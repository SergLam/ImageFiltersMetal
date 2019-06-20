import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        UINavigationBar.appearance().barStyle = .blackOpaque
        UIToolbar.appearance().barStyle = .blackOpaque

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = MainViewController()
        window.makeKeyAndVisible()
        window.tintColor = UIColor(displayP3Red: 1, green: 0, blue: 0.1, alpha: 1)
        self.window = window

        return true
    }
}

