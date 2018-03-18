import UIKit
import SceneKit
import ARKit
import Photos

class MainViewController: UIViewController, ARSCNViewDelegate, UIPopoverPresentationControllerDelegate {

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBOutlet var choosePhotoButton: UIButton!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var notificationLabel: EdgeInsetLabel!
    
    var focalNode: FocalNode?
    private var screenCenter:CGPoint!
    private var isPhotoLibraryAuthorized: Bool = false
    public var image: UIImage? {
        didSet {
            self.image = self.image?.fixImageOrientation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notificationLabel.isHidden = true
        configureSceneView()
        setupCamera()
        screenCenter = view.center
        notificationLabel.isHidden = false
        
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
    
    private func configureSceneView() {
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = true
        let ARScene = SCNScene()
        sceneView.scene = ARScene
        
        let omniLight = SCNLight()
        omniLight.type = .omni
        let omniNode = SCNNode()
        omniNode.light = omniLight
        omniNode.position = SCNVector3(0, 5, 0)
        omniNode.name = "omni"
        
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        ambientNode.position = SCNVector3(0, 5, 0)
        ambientNode.name = "ambient"
        
        sceneView.scene.rootNode.addChildNode(omniNode)
        sceneView.scene.rootNode.addChildNode(ambientNode)
    }
    
    private func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else { fatalError("Expected a valid camera view from the scene") }
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
        sceneView.preferredFramesPerSecond = 60
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard focalNode == nil else { return }
        let node = FocalNode()
        sceneView.scene.rootNode.addChildNode(node)
        self.focalNode = node
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, animations: {
                self.notificationLabel.alpha = 0.0
            }, completion: { _ in
                self.notificationLabel.isHidden = true
            })
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let focalNode = focalNode else { return }
        let hit = sceneView.hitTest(screenCenter, types: .existingPlane)
        guard let positionColumn = hit.first?.worldTransform.columns.3 else { return }
        focalNode.position = SCNVector3(x: positionColumn.x, y: positionColumn.y, z: positionColumn.z)
        
        guard let lightEstimate = sceneView.session.currentFrame?.lightEstimate, let omniLight = sceneView.scene.rootNode.childNode(withName: "omni", recursively: false), let ambientLight = sceneView.scene.rootNode.childNode(withName: "ambient", recursively: false) else { return }
        
        ambientLight.light?.intensity = lightEstimate.ambientIntensity
        omniLight.light?.intensity = lightEstimate.ambientIntensity
    }
    

    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photoCollectionSegue" {
            let photoLibraryCollectionViewController = segue.destination as! PhotoLibraryCollectionViewController
            photoLibraryCollectionViewController.modalPresentationStyle = .popover
            photoLibraryCollectionViewController.modalTransitionStyle = .coverVertical
            photoLibraryCollectionViewController.popoverPresentationController!.delegate = self

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
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        guard let photoLibararyCollectionViewController = popoverPresentationController.presentedViewController as? PhotoLibraryCollectionViewController else { return }
        guard let selectedPhoto = photoLibararyCollectionViewController.selectedPhoto else { return }
        self.image = selectedPhoto
        print(self.image!.size.width)
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








