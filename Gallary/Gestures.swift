import ARKit
import SceneKit
import AudioToolbox.AudioServices

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
            frameNode.opacity = 1
            AudioServicesPlaySystemSound(peek)
            frameNode.clone()
            self.frameNode = nil
            self.isPending = false
            panGestureRecognizer?.isEnabled = true
            hidePageControl()
        }
        
        //Select an existing node
        let tapLocation = gestureRecognizer.location(in: sceneView)
        let hitTestOptions: [SCNHitTestOption: Any] = [ .clipToZRange: true ]
        let hitTestResult = sceneView.hitTest(tapLocation, options: hitTestOptions)
        if let node = hitTestResult.first(where: { $0.node.parent?.name == "frameNode" || $0.node.name == "frameNode" })?.node{
            if selectedNode !== node {
                selectedNode?.opacity = 1
                deleteButton.showAnimated()
                node.opacity = 0.6
                selectedNode = node
                AudioServicesPlaySystemSound(peek)
            }
        } else {
            selectedNode?.opacity = 1
            selectedNode = nil
            deleteButton.hideAnimated()
            hidePageControl()
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
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(MainViewController.panToMove(with:)))
        sceneView.addGestureRecognizer(panGestureRecognizer!)
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
    
    // MARK: - Swipe Gesture
    
    func addSwipeGestureRecognizers() {
        swipeLeftRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(MainViewController.nextFrame(with:)))
        swipeRightRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(MainViewController.previousFrame(with:)))
        swipeLeftRecognizer!.direction = .left
        swipeRightRecognizer!.direction = .right
        
        sceneView.addGestureRecognizer(swipeLeftRecognizer!)
        sceneView.addGestureRecognizer(swipeRightRecognizer!)
    }
    
    @objc func nextFrame(with gestureRecognizer: UISwipeGestureRecognizer) {
        index += 1
        if index > 2 {
            index = 1
        }
        sceneName = "Frame\(index).scn"
        if isPending {
            DispatchQueue.main.async {
                self.pageControl.currentPage = self.index-1
                self.createFrameNode()
            }
        }
    }
    
    @objc func previousFrame(with gestureRecognizer: UISwipeGestureRecognizer) {
        index -= 1
        if index < 1 {
            index = 2
        }
        sceneName = "Frame\(index).scn"
        if isPending {
            DispatchQueue.main.async {
                self.pageControl.currentPage = self.index-1
                self.createFrameNode()
            }
        }
    }
}
