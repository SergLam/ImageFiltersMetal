import UIKit
import Photos
import CoreImage


protocol BrowserViewControllerDelegate: AnyObject {
    func browserDidLoad(_ browser: BrowserViewController, imageData: Data)
}

private let cellIdentifier = "BrowserCell"

class BrowserViewController: UIViewController {
    private enum Image {
        case asset(PHAsset)
        case sample(Data)
    }

    public var delegate: BrowserViewControllerDelegate?
    private let photoLibrary = PHPhotoLibrary.shared()
    private let photoManager = PHImageManager()
    private var assets: PHFetchResult<PHAsset>?
    private lazy var samplePhotos: [Data] = {
        let bundle = Bundle.main
        return [
            bundle.url(forResource: "Window", withExtension: "heic"),
            bundle.url(forResource: "Goat", withExtension: "jpg"),
            bundle.url(forResource: "Ice", withExtension: "jpg")
        ].compactMap { $0 }.compactMap {
            try? Data(contentsOf: $0)
        }
    }()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 60, height: 60)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(BrowserCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .black
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Photo Browser"

        photoLibrary.register(self)

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])

        updateBrowser()
    }

    private func updateBrowser() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "(mediaType == %d) && ((mediaSubtype & %d) != 0)", PHAssetMediaType.image.rawValue, PHAssetMediaSubtype.photoDepthEffect.rawValue)
        assets = PHAsset.fetchAssets(with: options)

        collectionView.reloadData()
    }

    private func image(at indexPath: IndexPath) -> Image {
        let row = indexPath.row
        switch indexPath.section {
        case 0: return .sample(samplePhotos[row])
        case 1: return .asset(validAssets()![row])
        default: fatalError()
        }
    }

    private func validAssets() -> PHFetchResult<PHAsset>? {
        if let assets = assets, assets.count > 0 {
            return assets
        }
        return nil
    }
}

extension BrowserViewController: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async { [weak self] in
            self?.updateBrowser()
        }
    }
}

extension BrowserViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch image(at: indexPath) {
        case .asset(let asset):
            _ = photoManager.loadImageData(asset: asset) { [weak self] data in
                guard let weakSelf = self else { return }
                guard let data = data else {
                    let ac = UIAlertController(title: "Opening Failed", message: "Couldn't open photo.", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    weakSelf.present(ac, animated: true)
                    return
                }
                weakSelf.delegate?.browserDidLoad(weakSelf, imageData: data)
            }
        case .sample(let data):
            delegate?.browserDidLoad(self, imageData: data)
        }
    }
}

extension BrowserViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return validAssets() == nil ? 1 : 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: return samplePhotos.count
        case 1: return assets!.count
        default: fatalError()
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! BrowserCollectionViewCell

        if cell.tag != 0 {
            photoManager.cancelImageRequest(PHImageRequestID(cell.tag))
        }
        switch image(at: indexPath) {
        case .asset(let asset):
            let pixelsPerPoint = (collectionView.window?.screen ?? .main).scale
            let imagePixelSize = CGSize(width: cell.bounds.width * pixelsPerPoint,
                                        height: cell.bounds.height * pixelsPerPoint)
            let requestId = photoManager.loadImage(asset: asset, size: imagePixelSize) { [weak cell] image in
                cell?.imageView.image = image
            }
            cell.tag = Int(requestId)
        case .sample(let data):
            cell.imageView.image = UIImage(data: data)
            cell.tag = 0
        }
        return cell
    }
}

final class BrowserCollectionViewCell: UICollectionViewCell {
    public let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    private func setup() {
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])

        imageView.isAccessibilityElement = true
        imageView.accessibilityTraits = [
            .image, // Enables three finger tap for system suggested/detected
            .button,
        ]
        imageView.accessibilityHint = "Opens photo."
    }
}

extension PHImageManager {
    func loadImage(asset: PHAsset, size: CGSize, completion: @escaping (UIImage?) -> Void) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast

        options.progressHandler = { value, _, _, _ in
            print(value)
        }

        let id = requestImage(for: asset, targetSize: size, contentMode: .default, options: options) { image, info in
            if
                let isCancelled = info?[PHImageCancelledKey] as? Bool,
                isCancelled {
                // If request was cancelled, don't call completion block.
                return
            }
            completion(image)
        }
        return id
    }

    func loadImageData(asset: PHAsset, completion: @escaping (Data?) -> Void) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.version = .unadjusted

        options.progressHandler = { value, _, _, _ in
            print(value)
        }

        let id = requestImageData(for: asset, options: options) { data, _, _, info in
            if
                let isCancelled = info?[PHImageCancelledKey] as? Bool,
                isCancelled {
                // If request was cancelled, don't call completion block.
                return
            }
            completion(data)
        }
        return id
    }
}
