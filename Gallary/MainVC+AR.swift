import ARKit
import SceneKit

extension MainViewController: ARSCNViewDelegate {
    
    // MARK: - Configure Session
    
    func configureSceneView() {
        sceneView.delegate = self
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
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
        ambientNode.position = SCNVector3(0, 2, 0)
        ambientNode.name = "ambient"
        
        sceneView.scene.rootNode.addChildNode(omniNode)
        sceneView.scene.rootNode.addChildNode(ambientNode)
    }
    
    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else { fatalError("Expected a valid camera view from the scene") }
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
        sceneView.antialiasingMode = .multisampling4X
        sceneView.preferredFramesPerSecond = 60
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard focalNode == nil  else { return }
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
        let hit = sceneView.hitTest(screenCenter, types: [.existingPlaneUsingExtent])
        guard let positionColumn = hit.first?.worldTransform.columns.3, let focalNode = focalNode, let planeAnchor = hit.last?.anchor as? ARPlaneAnchor else { return }
        let planeNode = self.sceneView.node(for: planeAnchor)
        
        if planeAnchor.alignment == .vertical {
            focalNode.alignVertically()
            focalNode.eulerAngles.y = planeNode!.eulerAngles.y
        } else if planeAnchor.alignment == .horizontal {
            focalNode.alignHorizontally()
            
        }
        
        focalNode.position = SCNVector3(x: positionColumn.x, y: positionColumn.y, z: positionColumn.z)
        
        // Light estimation
        guard let lightEstimate = sceneView.session.currentFrame?.lightEstimate, let omniLight = sceneView.scene.rootNode.childNode(withName: "omni", recursively: false), let ambientLight = sceneView.scene.rootNode.childNode(withName: "ambient", recursively: false) else { return }
        ambientLight.light?.intensity = lightEstimate.ambientIntensity
        omniLight.light?.intensity = lightEstimate.ambientIntensity
        
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {

    }
    
    // MARK: - Nodes
    
    func createFrameNode(){
        guard let frameScene = SCNScene(named: "Frame.scn", inDirectory: "art.scnassets", options: nil) else { print("no such scene or node"); return }
        guard let image = self.image else { print("no image available"); return }
        
        let frameNode = SCNNode()
        frameNode.name = "frameNode"
        let frameChildNodes = frameScene.rootNode.childNodes
        for node in frameChildNodes {
            frameNode.addChildNode(node)
        }
        
        if let material = frameNode.childNode(withName: "frame", recursively: true)?.geometry?.material(named: "contents") {
            material.diffuse.contents = image
            if image.size.width > image.size.height {
                frameNode.categoryBitMask = 2
                let rotation = SCNMatrix4MakeRotation(Float.pi/2, 0, 0, 1)
                let mirroring = SCNMatrix4MakeScale(-1, 1, 1)
                let transform = SCNMatrix4Mult(rotation, mirroring)
                material.diffuse.contentsTransform = transform
            }
        }
        self.frameNode = frameNode
    }
    
    func node(at position: CGPoint) -> SCNNode? {
        return sceneView.hitTest(position, options: nil).first(where: { $0.node !== focalNode })?.node
    }
    
    func createWall() {
        
        
    }
    
}
