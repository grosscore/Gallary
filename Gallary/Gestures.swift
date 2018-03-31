import ARKit
import SceneKit

extension MainViewController {
    
    // MARK: - TapGesture
    
    func addTapGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MainViewController.didTap(with:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func didTap(with gestureRecognizer: UITapGestureRecognizer) {
        
        if isPending {
            guard let frameNode = self.frameNode else { print("no frame node"); return }
            let hit = sceneView.hitTest(screenCenter, types: .existingPlane)
            guard let positionColumn = hit.first?.worldTransform.columns.3 else { print("wrong position"); return }
            frameNode.position = SCNVector3(positionColumn.x, positionColumn.y, positionColumn.z)
            sceneView.scene.rootNode.addChildNode(frameNode)
            //self.frameNode = nil
            self.isPending = false
        }
        
        let tapLocation = gestureRecognizer.location(in: self.sceneView)
        let hitTestOptions: [SCNHitTestOption: Any] = [ .boundingBoxOnly: true ]
        let hitTestResult = sceneView.hitTest(tapLocation, options: hitTestOptions)
        
        guard let node = hitTestResult.first(where: { $0.node !== focalNode && $0.node !== sceneView.scene.rootNode})?.node else { return }
        
        deleteButton.isHidden = false
        selectedNode = node.parent
        selectedNode?.opacity = 0.6
        
    }
    
}
