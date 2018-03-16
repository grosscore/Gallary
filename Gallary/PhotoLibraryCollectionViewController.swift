import UIKit
import Photos

private let reuseIdentifier = "thumbnailCell"

class PhotoLibraryCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var fetchResults: PHFetchResult<PHAsset>! {
        didSet {
            self.collectionView?.reloadData()
            self.fetchResults.enumerateObjects { (asset, _, _) in
                self.assets.append(asset)
            }
        }
    }
    private var assets: [PHAsset] = [] {
        didSet {
            self.imageManager.startCachingImages(for: self.assets, targetSize: self.itemSize!, contentMode: .aspectFit, options: nil)
        }
    }
    
    private var itemSize: CGSize?
    private var thumbnailSize: CGSize?
    private let imageManager = PHCachingImageManager()
    private var selectedPhoto = UIImage()

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isStatusBarHidden = true
        updateItemSize()
        
        //Fetching all assets from Library:
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeAllBurstAssets = false
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        //fetchOptions.fetchLimit = 100
        self.fetchResults = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateItemSize()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResults.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? ThumbnailCell else { fatalError("Wrong cell type!") }
        let asset = assets[indexPath.item]
        print(asset.pixelHeight)
        cell.representedAssetIdentifier = asset.localIdentifier
        imageManager.requestImage(for: asset, targetSize: itemSize!, contentMode: .aspectFit, options: nil) {(object, _) in
            if cell.representedAssetIdentifier == asset.localIdentifier && object != nil {
                    cell.thumbnailView.image = object
            }
        }
        return cell
    }
    
    
    // Selecting and passing the original image
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoAsset = assets[indexPath.item]
        imageManager.requestImage(for: photoAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil) { (photo, _) in
            if photo != nil {
                self.selectedPhoto = photo!
                self.dismiss(animated: true, completion: nil)
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
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }


}

