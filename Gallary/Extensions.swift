import Foundation
import UIKit
import ARKit
import Photos
import GoogleMobileAds

// ==================== EXTENSION: UIIMAGE ========================
extension UIImage {
    func fixImageOrientation() -> UIImage? {
        if (self.imageOrientation == .up) {
            return self
        }
        var transform: CGAffineTransform = CGAffineTransform.identity
        if ( self.imageOrientation == .left || self.imageOrientation == .leftMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(Double.pi / 2.0))
        } else if ( self.imageOrientation == .right || self.imageOrientation == .rightMirrored ) {
            transform = transform.translatedBy(x: 0, y: self.size.height);
            transform = transform.rotated(by: CGFloat(-Double.pi / 2.0));
        } else if ( self.imageOrientation == .down || self.imageOrientation == .downMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
        } else if ( self.imageOrientation == .upMirrored || self.imageOrientation == .downMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        } else if ( self.imageOrientation == .leftMirrored || self.imageOrientation == .rightMirrored ) {
            transform = transform.translatedBy(x: self.size.height, y: 0);
            transform = transform.scaledBy(x: -1, y: 1);
        }
        
        if let context: CGContext = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height),
                                              bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0,
                                              space: self.cgImage!.colorSpace!,
                                              bitmapInfo: self.cgImage!.bitmapInfo.rawValue) {
            
            context.concatenate(transform)
            if ( self.imageOrientation == UIImageOrientation.left ||
                self.imageOrientation == UIImageOrientation.leftMirrored ||
                self.imageOrientation == UIImageOrientation.right ||
                self.imageOrientation == UIImageOrientation.rightMirrored ) {
                context.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.height,height: self.size.width))
            } else {
                context.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.width,height: self.size.height))
            }
            if let contextImage = context.makeImage() {
                return UIImage(cgImage: contextImage)
            }
        }
        return nil
    }
}

// ==================== EXTENSION: FLOAT ========================
extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

// ==================== EXTENSION: UIVIEW ========================
extension UIView {
    func blur() {
        self.backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.autoresizingMask = .flexibleBottomMargin
        blurView.layer.cornerRadius = 7
        blurView.frame = self.bounds
        self.insertSubview(blurView, at: 0)
    }
}

// ==================== EXTENSION: UIBUTTON =======================

extension UIButton {
    func hideAnimated() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.4, animations: {
                self.alpha = 0.0
                self.isHidden = true
            })
        }
    }
    
    func showAnimated() {
        DispatchQueue.main.async {
            if self.isHidden == true {
                self.alpha = 0
                self.isHidden = false
                UIView.animate(withDuration: 0.4, animations: {
                    self.alpha = 1.0
                })
            }
        }
    }
}

// ==================== EXTENSION: UILABEL ========================
@IBDesignable
class EdgeInsetLabel: UILabel {
    var textInsets = UIEdgeInsets.zero {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetRect = UIEdgeInsetsInsetRect(bounds, textInsets)
        let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -textInsets.top,
                                          left: -textInsets.left,
                                          bottom: -textInsets.bottom,
                                          right: -textInsets.right)
        return UIEdgeInsetsInsetRect(textRect, invertedInsets)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, textInsets))
    }
}

extension EdgeInsetLabel {
    @IBInspectable
    var leftTextInset: CGFloat {
        set { textInsets.left = newValue }
        get { return textInsets.left }
    }
    
    @IBInspectable
    var rightTextInset: CGFloat {
        set { textInsets.right = newValue }
        get { return textInsets.right }
    }
    
    @IBInspectable
    var topTextInset: CGFloat {
        set { textInsets.top = newValue }
        get { return textInsets.top }
    }
    
    @IBInspectable
    var bottomTextInset: CGFloat {
        set { textInsets.bottom = newValue }
        get { return textInsets.bottom }
    }
}

// ==================== EXTENSION: - SCNNODE ====================================
extension SCNNode {
    func alignHorizontally() {
        transform = SCNMatrix4Identity
        transform = SCNMatrix4MakeRotation(-.pi/2, 1.0, 0.0, 0.0)
    }
    func alignVertically() {
        transform = SCNMatrix4Identity
    }
}

// =================== MARK: - CGPoint extensions

extension CGPoint {
    /// Extracts the screen space point from a vector returned by SCNView.projectPoint(_:).
    init(_ vector: SCNVector3) {
        self.init(x: CGFloat(vector.x), y: CGFloat(vector.y))
    }
    
    /// Returns the length of a point when considered as a vector. (Used with gesture recognizers.)
    var length: CGFloat {
        return sqrt(x * x + y * y)
    }
}

// ==================== EXTENSION: - MAINVIEWCONTROLLER =========================

extension MainViewController: GADInterstitialDelegate {
    
    func requestPhotoLibraryAuthorization() {
        
        func statusAlert() {
            let alert = UIAlertController(
                title: "Need Authorization",
                message: "Use your photos in your own AR Gallery!",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(
                title: "Deny", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(
                title: "OK", style: .default, handler: {
                    _ in
                    let url = URL(string:UIApplicationOpenSettingsURLString)!
                    UIApplication.shared.open(url)
            }))
            self.present(alert, animated:true, completion:nil)
        }
        // ----------
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            fetchAllAssets()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization() { status in
                if status == .authorized {
                    self.fetchAllAssets()
                }
            }
        case .restricted: break
        case .denied:
            statusAlert()
        }
    }
    
    // ADMOB Configuration
    
    func adMobConfiguration() {
        //let bannerID = "ca-app-pub-6051983367608032/5251473946"
        let testBannerID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.adUnitID = testBannerID
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        interstitial = createAndLoadInterstitial()
        interstitial.delegate = self
    }
    
    fileprivate func createAndLoadInterstitial() -> GADInterstitial {
        //let interstitialID = "ca-app-pub-6051983367608032/6331254344"
        let testInterstitialID = "ca-app-pub-3940256099942544/4411468910"
        let interstitial = GADInterstitial(adUnitID: testInterstitialID)
        interstitial.load(GADRequest())
        return interstitial
    }
    
    internal func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        DispatchQueue.main.async {
            self.interstitial = self.createAndLoadInterstitial()
        }
    }
    
    
    // Animation of PageControl
    func showPageControl() {
        DispatchQueue.main.async {
            if self.pageControl.isHidden {
                self.pageControl.alpha = 0
                self.pageControl.isHidden = false
                UIView.animate(withDuration: 0.3, animations: {
                    self.pageControl.alpha = 0.85
                })
            }
        }
    }
    
    func hidePageControl() {
        DispatchQueue.main.async {
            if !self.pageControl.isHidden {
                UIView.animate(withDuration: 0.3, animations: {
                    self.pageControl.alpha = 0
                })
                self.pageControl.isHidden = true
            }
        }
    }

}
