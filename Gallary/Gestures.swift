import ARKit
import SceneKit

extension MainViewController {
    
    // MARK: - TapGesture
    
    func addTapGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MainViewController.didTap(with:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func didTap(with gestureRecognizer: UITapGestureRecognizer) {
        guard let frameNode = self.frameNode else { print("no frame node"); return }
        let hit = sceneView.hitTest(screenCenter, types: .existingPlane)
        guard let positionColumn = hit.first?.worldTransform.columns.3 else { print("wrong position"); return }
        frameNode.position = SCNVector3(positionColumn.x, positionColumn.y, positionColumn.z)
        sceneView.scene.rootNode.addChildNode(frameNode)
        //self.frameNode = nil
        
    }
    
}
