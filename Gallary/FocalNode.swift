import SceneKit

class FocalNode: SCNNode {
    
    let size: CGFloat = 0.15
    let segmentWidth: CGFloat = 0.004
    let centralDistance: CGFloat = 0.01
    
    private let colorMaterial: SCNMaterial = {
        let material = SCNMaterial()
        material.diffuse.contents = #colorLiteral(red: 0.3137254902, green: 0.5803921569, blue: 0.7764705882, alpha: 1).withAlphaComponent(0.5)
        return material
    }()
    
    override init() {
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func createSegment(width: CGFloat, height: CGFloat) -> SCNNode {
        let segment = SCNPlane(width: width, height: height)
        segment.materials = [colorMaterial]
        return SCNNode(geometry: segment)
    }
    
    private func addHorizontalSegment(dx: Float) {
        let segmentNode = createSegment(width: segmentWidth, height: size)
        segmentNode.position.x += dx
        addChildNode(segmentNode)
    }
    
    private func addVerticalSegment(dy: Float) {
        let segmentNode = createSegment(width: size, height: segmentWidth)
        segmentNode.position.y += dy
        addChildNode(segmentNode)
    }
    
    private func addCentralPlane() {
        let side = size - (centralDistance * 2)
        let centralNode = createSegment(width: side, height: side)
        centralNode.position = SCNVector3(x: 0.0, y: 0.0, z: 0.0)
        addChildNode(centralNode)
    }
    
    private func setup() {
        let dist = Float(size) / 2.0
        addHorizontalSegment(dx: dist)
        addHorizontalSegment(dx: -dist)
        addVerticalSegment(dy: dist)
        addVerticalSegment(dy: -dist)
        addCentralPlane()
    }
    
    func alignHorizontally() {
        transform = SCNMatrix4Identity
        transform = SCNMatrix4MakeRotation(-.pi/2, 1.0, 0.0, 0.0)
    }
    
    func alignVertically() {
        transform = SCNMatrix4Identity
        
    }
    
}
