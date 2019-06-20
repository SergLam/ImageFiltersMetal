import UIKit

class MainViewController: UIViewController {
    private let browser = BrowserViewController()
    private lazy var navigation = UINavigationController()

    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(navigation.view)
        addChild(navigation)
        navigation.didMove(toParent: self)

        if let imageData = UserDefaults.standard.data(forKey: "lastImageData") {
            let editor = buildEditor(withImageData: imageData)
            navigation.viewControllers = [browser, editor]
        } else {
            navigation.viewControllers = [browser]
        }

        browser.delegate = self
    }
}

extension MainViewController: BrowserViewControllerDelegate {
    func browserDidLoad(_ browser: BrowserViewController, imageData: Data) {
        UserDefaults.standard.set(imageData, forKey: "lastImageData")
        UserDefaults.standard.synchronize()
        let editor = buildEditor(withImageData: imageData)
        navigation.pushViewController(editor, animated: true)
    }
}

func buildEditor(withImageData imageData: Data) -> UIViewController {
    let image = CIImage(data: imageData, options: [.applyOrientationProperty: true])!
    let depthMap = CIImage(data: imageData, options: [.auxiliaryDepth: true, .applyOrientationProperty: true])!
    let scale = image.extent.width / depthMap.extent.width
    let scaledDepthMap = depthMap.transformed(by: .init(scaleX: scale, y: scale))

    return EditorViewController(image: image, depthMap: scaledDepthMap)
}
