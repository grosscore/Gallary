import ARKit
import SceneKit

extension MainViewController {
    
    // MARK: - TapGesture
    
    func addTapGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MainViewController.tap(with:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func tap(with gestureRecognizer: UITapGestureRecognizer) {
        
        // Add a frameNode to a scene
        if isPending {
            guard let frameNode = self.frameNode else { print("no frame node"); return }
//            let hit = sceneView.hitTest(screenCenter, types: .existingPlane)
//            guard let positionColumn = hit.first?.worldTransform.columns.3, let planeAnchor = hit.first?.anchor as? ARPlaneAnchor, let planeNode = sceneView.node(for: planeAnchor) else { print("wrong position"); return }
//            frameNode.eulerAngles = planeNode.eulerAngles
//            frameNode.position = SCNVector3(positionColumn.x, positionColumn.y, positionColumn.z)
//            sceneView.scene.rootNode.addChildNode(frameNode)
            frameNode.opacity = 1
            frameNode.clone()
            self.frameNode = nil
            self.isPending = false
        }
        
        //Select an existing node
        let tapLocation = gestureRecognizer.location(in: sceneView)
        let hitTestOptions: [SCNHitTestOption: Any] = [ .clipToZRange: true ]
        let hitTestResult = sceneView.hitTest(tapLocation, options: hitTestOptions)
        if let node = hitTestResult.first(where: { $0.node.parent?.name == "frameNode" || $0.node.name == "frameNode" })?.node{
            if selectedNode !== node {
                focalNode?.isHidden = true
                selectedNode?.opacity = 1
                deleteButton.showAnimated()
                node.opacity = 0.6
                selectedNode = node
            }
        } else {
            focalNode?.isHidden = false
            selectedNode?.opacity = 1
            deleteButton.hideAnimated()
            selectedNode = nil
        }
    }
    
    // MARK: - Pinch Gesture
    
    func addPinchGestureRecognizer() {
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(MainViewController.pinchToScale(with:)))
        sceneView.addGestureRecognizer(pinchGestureRecognizer)
    }
    
    @objc func pinchToScale(with gestureRecognizer: UIPinchGestureRecognizer) {
        if selectedNode != nil {
            if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
                selectedNode!.scale = SCNVector3(gestureRecognizer.scale, gestureRecognizer.scale, gestureRecognizer.scale)
            }
        } else if isPending && frameNode != nil {
            if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
                frameNode!.scale = SCNVector3(gestureRecognizer.scale, gestureRecognizer.scale, gestureRecognizer.scale)
            }
        }
    }
    
    // MARK: - Pan Gesture
    
    func addPanGestureRecognizer() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(MainViewController.panToMove(with:)))
        sceneView.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc func panToMove(with gestureRecognizer: UIPanGestureRecognizer) {
        let location = gestureRecognizer.location(in: gestureRecognizer.view)
        if selectedNode == node(at: location) {
            switch gestureRecognizer.state {
            case .began: selectedNode = node(at: location)
            case .changed :
                guard let result = sceneView.hitTest(location, types: .existingPlane).first else { return }
                let transform = result.worldTransform.columns.3
                let newPosition = SCNVector3(transform.x, transform.y, transform.z)
                selectedNode?.worldPosition = newPosition
            default: break
            }
            
        }
    }

}
