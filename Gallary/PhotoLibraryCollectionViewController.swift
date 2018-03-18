import UIKit
import Photos

private let reuseIdentifier = "thumbnailCell"

class PhotoLibraryCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var imageManager: PHCachingImageManager?
    var fetchResults: PHFetchResult<PHAsset>? {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    private var itemSize: CGSize?
    var thumbnailSize: CGSize?
    
    var selectedPhoto: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isStatusBarHidden = true
        updateItemSize()

    }
    
    override func viewWillLayoutSubviews() {
        updateItemSize()
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResults!.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? ThumbnailCell else { fatalError("Wrong cell type!") }
        let asset = fetchResults!.object(at: indexPath.item)
        cell.representedAssetIdentifier = asset.localIdentifier
        imageManager!.requestImage(for: asset, targetSize: thumbnailSize!, contentMode: .aspectFit, options: nil) {(object, _) in
            if cell.representedAssetIdentifier == asset.localIdentifier && object != nil {
                    cell.thumbnailView.image = object
            }
        }
        return cell
    }
    
    
    // Selecting and passing the original image
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCell = collectionView.cellForItem(at: indexPath)
        selectedCell?.layer.borderColor = UIColor.yellow.cgColor
        selectedCell?.layer.borderWidth =  2
        
        let photoAsset = fetchResults!.object(at: indexPath.item)
        imageManager!.requestImage(for: photoAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil) { (photo, _) in
            if photo != nil {
                self.selectedPhoto = photo!
                self.dismiss(animated: true, completion: nil)
                print(self.selectedPhoto!.size.width)
            }
        }
    }
    
    // Setting cell's size (with UICollectionViewDelegateFlowLayout)
    func updateItemSize() {
        let viewWidth = view.frame.width
        let side = (viewWidth - 2) / 3
        let size = CGSize(width: side, height: side)
        self.itemSize = size
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = size
        }
    }

}

