import UIKit
import SceneKit
import ARKit
import Photos
import GoogleMobileAds

class MainViewController: UIViewController, UIPopoverPresentationControllerDelegate {

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var choosePhotoButton: UIButton!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet weak var notificationLabel: EdgeInsetLabel!
    @IBOutlet weak var captureButton: UIButton!
    
    //AdMob variables:
    @IBOutlet weak var bannerView: GADBannerView!
    var interstitial: GADInterstitial!
    
    var isSelected: Bool = false
    var isPending: Bool = false
    
    var screenCenter: CGPoint!
    var focalNode: FocalNode?
    var frameNode: SCNNode? {
        didSet {
            if selectedNode != nil {
                frameNode!.position = selectedNode!.worldPosition
                sceneView.scene.rootNode.addChildNode(frameNode!)
                selectedNode!.removeFromParentNode()
                selectedNode = frameNode
                frameNode = nil
            } else {
                if frameNode?.categoryBitMask == 2 {
                    frameNode?.childNodes.first?.eulerAngles.y = -.pi/2
                }
                isPending = true
            }
        }
    }
    var selectedNode: SCNNode?
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
        addPinchGestureRecognizer()
        addPanGestureRecognizer()
        
        selectedNode = nil
        deleteButton.isHidden = true
    
        adMobConfiguration()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = true
        UIApplication.shared.isStatusBarHidden = true
        let configuration = ARWorldTrackingConfiguration()
        if #available(iOS 11.3, *) {
            configuration.planeDetection = [.horizontal, .vertical]
        } else {
            configuration.planeDetection = .horizontal
        }
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration)
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = false
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
    
    @IBAction func deleteNode(_ sender: UIButton) {
        guard selectedNode != nil else { return }
        selectedNode?.removeFromParentNode()
        selectedNode = nil
        deleteButton.hideAnimated()
        focalNode?.isHidden = false
    }
    
    @IBAction func capturePhoto(_ sender: UIButton) {
        let snapshot = sceneView.snapshot().fixImageOrientation()
        try? PHPhotoLibrary.shared().performChangesAndWait {
            PHAssetChangeRequest.creationRequestForAsset(from: snapshot!)
        }
        
        showNotification(text: "Saved", time: 3, autohide: true)
    }
    
    @IBAction func restartSession(_ sender: UIButton) {
        
        DispatchQueue.main.async {
            if self.interstitial.isReady {
                self.interstitial.present(fromRootViewController: self)
            }
        }
        
        selectedNode = nil
        isSelected = false
        isPending = false
        frameNode = nil
        image = nil
        deleteButton.hideAnimated()
        for node in sceneView.scene.rootNode.childNodes {
            if node.name == "frameNode" {
                node.removeFromParentNode()
            }
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
        
        showNotification(text: "Reinitializing tracking. Please, move gently.")
    }
    
}








