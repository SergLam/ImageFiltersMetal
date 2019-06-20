import UIKit
import CoreImage

typealias Effect = (CIImage, CIImage) -> CIImage?

class EditorViewController: UIViewController {
    public let image: CIImage
    public let depthMap: CIImage

    private let effects: [Effect] = [
        task1,
        task2,
        task3,
        task4,
        task5
    ]
    private let appendices: [Effect] = [
        appendix1,
        appendix2,
        appendix3,
        appendix4,
        appendix5,
        appendix6,
        appendix7
    ]
    private var selectedEffect: Int = UserDefaults.standard.integer(forKey: "selectedEffect") {
        didSet {
            UserDefaults.standard.set(selectedEffect, forKey: "selectedEffect")
            update()
        }
    }
    private let originalImageView = InputImageView(title: "Original")
    private let depthMapView = InputImageView(title: "Depth Map")
    private let resultImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    private var inputsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()
    private var outerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.preservesSuperviewLayoutMargins = true
        stackView.alignment = .center
        stackView.spacing = 10
        return stackView
    }()

    init(image: CIImage, depthMap: CIImage) {
        self.image = image
        self.depthMap = depthMap
        super.init(nibName: nil, bundle: nil)
    }
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Photo Editor"
        view.backgroundColor = .black
        view.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)

        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(didRequestShare))
        navigationItem.rightBarButtonItem = shareButton

        view.addSubview(outerStackView)
        outerStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            outerStackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            outerStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            outerStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            outerStackView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            ])

        outerStackView.addArrangedSubview(inputsStackView)

        inputsStackView.addArrangedSubview(originalImageView)
        inputsStackView.addArrangedSubview(depthMapView)
        inputsStackView.heightAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.heightAnchor, multiplier: 1/5).isActive = true

        outerStackView.addArrangedSubview(resultImageView)
        resultImageView.setContentCompressionResistancePriority(.fittingSizeLevel, for: .vertical)

        let segment = UISegmentedControl(items: effects.enumerated().map {
            let title = "\($0.offset + 1)" as NSString
            title.accessibilityLabel = "Task"
            return title
        })
        for (index, _) in appendices.enumerated() {
            segment.insertSegment(withTitle: "A\(index + 1)", at: segment.numberOfSegments, animated: false)
        }
        selectedEffect = min(selectedEffect, segment.numberOfSegments - 1)
        segment.selectedSegmentIndex = selectedEffect
        segment.addTarget(self, action: #selector(didChangeSegment), for: .valueChanged)
        toolbarItems = [UIBarButtonItem(customView: segment)]

        let toolbar = UIToolbar()
        view.addSubview(toolbar)

        resultImageView.isAccessibilityElement = true
        resultImageView.accessibilityTraits = [
            .image, // Enables three finger tap for system suggested/detected
        ]

        update()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: animated)
    }

    @objc private func didChangeSegment(segment: UISegmentedControl) {
        selectedEffect = segment.selectedSegmentIndex
    }

    @objc private func didRequestShare() {
        guard let result = effects[selectedEffect](image, depthMap) else { return }
        let context = CIContext()
        let cgImage = context.createCGImage(result, from: result.extent)
        let sharableImage = UIImage(cgImage: cgImage!)

        let activityViewController = UIActivityViewController(activityItems: [sharableImage], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = view

        present(activityViewController, animated: true)
    }

    private func update() {
        originalImageView.image = UIImage(ciImage: image)
        depthMapView.image = UIImage(ciImage: depthMap)
        let effect: Effect
        if effects.indices.contains(selectedEffect) {
            effect = effects[selectedEffect]
        } else {
            effect = appendices[selectedEffect - effects.count]
        }
        guard let result = effect(image, depthMap) else {
            let ac = UIAlertController(title: "No Output", message: "Effect #\(selectedEffect + 1) returned nil.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            resultImageView.image = nil
            return
        }
        resultImageView.image = UIImage(ciImage: result)
    }
}

class InputImageView: UIView {

    var image: UIImage? { didSet { update() }}
    var title: String { didSet { update() }}

    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    private let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .lightText
        return label
    }()
    private var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 5
        stackView.alignment = .center
        return stackView
    }()
    private var imageViewAspectConstraint: NSLayoutConstraint?

    init(title: String) {
        self.title = title
        super.init(frame: .zero)
        setup()
    }
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])

        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(imageView)

        imageView.setContentCompressionResistancePriority(.fittingSizeLevel, for: .vertical)

        update()
    }

    private func update() {
        imageView.image = image
        label.text = title

        label.isAccessibilityElement = false
        imageView.isAccessibilityElement = true
        imageView.accessibilityTraits = [
            .image, // Enables three finger tap for system suggested/detected
        ]
        imageView.accessibilityLabel = title
    }
}
