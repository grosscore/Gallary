import UIKit
import SceneKit
import ARKit
import Photos

class MainViewController: UIViewController, UIPopoverPresentationControllerDelegate, ARSCNViewDelegate {

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBOutlet var choosePhotoButton: UIButton!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var notificationLabel: EdgeInsetLabel!
    
    var isSelected: Bool = false
    
    var screenCenter:CGPoint!
    var focalNode: FocalNode?
    var frameNode: SCNNode?
    var image: UIImage? {
        didSet {
            self.image = self.image?.fixImageOrientation()
            createFrameNode()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notificationLabel.isHidden = true
        configureSceneView()
        setupCamera()
        screenCenter = view.center
        notificationLabel.isHidden = false
        addTapGestureRecognizer()
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = true
        UIApplication.shared.isStatusBarHidden = true
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration)
        requestPhotoLibraryAuthorization()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photoCollectionSegue" {
            let photoLibraryCollectionViewController = segue.destination as! PhotoLibraryCollectionViewController
            photoLibraryCollectionViewController.popoverPresentationController!.delegate = self
            photoLibraryCollectionViewController.modalPresentationStyle = .popover
            photoLibraryCollectionViewController.thumbnailSize = self.thumbnailSize
            photoLibraryCollectionViewController.imageManager = self.imageManager
            photoLibraryCollectionViewController.fetchResults = self.fetchResults
        }
        if let popoverController = segue.destination.popoverPresentationController, let button = sender as? UIButton {
            popoverController.sourceView = button
            popoverController.sourceRect = button.bounds
        }
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }

    
    // MARK: - Fetching and Caching all images from Library
   
    private let imageManager = PHCachingImageManager()
    private var thumbnailSize: CGSize {
        get {
            let side = view.bounds.width / 2
            return CGSize(width: side, height: side)
        }
    }
    
    var fetchResults: PHFetchResult<PHAsset>! {
        didSet {
            self.fetchResults.enumerateObjects { (asset, _, _) in
                self.assets.append(asset)
            }
        }
    }
    
    private var assets: [PHAsset] = [] {
        willSet {
            self.imageManager.stopCachingImagesForAllAssets()
        }
        didSet {
            DispatchQueue.main.async {
                self.imageManager.startCachingImages(for: self.assets, targetSize: self.thumbnailSize, contentMode: .aspectFit, options: nil)
            }
        }
    }
    
    func fetchAllAssets() {
        DispatchQueue.main.async {
            let fetchOptions = PHFetchOptions()
            fetchOptions.includeAllBurstAssets = false
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            self.fetchResults = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        }
    }
    
    @IBAction func openLibrary(_ sender: UIButton) {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            requestPhotoLibraryAuthorization()
            return
        }
    }
    
}








