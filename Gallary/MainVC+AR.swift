import ARKit
import SceneKit

extension MainViewController {
    
    // MARK: - Configure Session
    
    func configureSceneView() {
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
    
    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else { fatalError("Expected a valid camera view from the scene") }
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
        sceneView.preferredFramesPerSecond = 60
    }
    
    // MARK: - ARSCNViewDelegate
    
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
        
        // TOO DARK:
        if lightEstimate.ambientIntensity < 100 {
            
        }
    }
    
    // MARK: - Nodes
    
    func createFrameNode(){
        guard let frameScene = SCNScene(named: "painting.scn", inDirectory: "art.scnassets", options: nil) else { print("no such scene or node"); return }
        guard let image = self.image else { print("no image available"); return }
        
        let frameNode = SCNNode()
        let frameChildNodes = frameScene.rootNode.childNodes
        for node in frameChildNodes {
            frameNode.addChildNode(node)
        }
        
        if let material = frameNode.childNode(withName: "default", recursively: true)?.geometry?.material(named: "contents") {
            material.diffuse.contents = image
            if image.size.width > image.size.height {
                let rotateZ = SCNMatrix4MakeRotation(-Float.pi/2, 0, 0, 1)
                let rotateX = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
                frameNode.transform = SCNMatrix4Mult(rotateZ, rotateX)
                let rotation = SCNMatrix4MakeRotation(Float.pi / 2, 0, 0, 1)
                let mirroring = SCNMatrix4MakeScale(-1, 1, 1)
                let transform = SCNMatrix4Mult(rotation, mirroring)
                material.diffuse.contentsTransform = transform
            } else {
                frameNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
            }
        }
        
        self.frameNode = frameNode
    }
    
}
