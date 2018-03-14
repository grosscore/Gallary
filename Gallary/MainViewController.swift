import UIKit
import SceneKit
import ARKit
import Photos

class MainViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var notificationLabel: EdgeInsetLabel!
    
    var focalNode: FocalNode?
    private var screenCenter:CGPoint!
    
    private var image: UIImage? {
        didSet {
            self.image = self.image?.fixImageOrientation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSceneView()
        setupCamera()
        screenCenter = view.center
        notificationLabel.isHidden = false
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = true
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.isLightEstimationEnabled = true
        
        sceneView.session.run(configuration)
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
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "photoLibrarySegue" {
//            let popoverViewController = segue.destination as! PhotoCollectionViewController
//            popoverViewController.modalPresentationStyle = .popover
//            popoverViewController.modalTransitionStyle = .coverVertical
//            popoverViewController.popoverPresentationController!.delegate = self
//        }
//    }
//
//    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
//        return UIModalPresentationStyle.none
//    }
//
}
