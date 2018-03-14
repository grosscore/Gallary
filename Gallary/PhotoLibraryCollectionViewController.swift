import UIKit
import Photos

private let reuseIdentifier = "thumbnailCell"

class PhotoLibraryCollectionViewController: UICollectionViewController {
    
    var fetchResults: PHFetchResult<PHAsset>!
    private var itemSize: CGSize?
    private let imageManager = PHCachingImageManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResults.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    // Item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    
     // MARK: - Navigation

     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
     }

}

class ThumbnailCell: UICollectionViewCell {
    
    
}
