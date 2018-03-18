import Foundation
import UIKit
import ARKit
import Photos

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

// ==================== EXTENSION: - MAINVIEWCONTROLLER =========================

extension MainViewController {
    
    func requestPhotoLibraryAuthorization(){
        
        func statusAlert() {
            let alert = UIAlertController(
                title: "Need Authorization",
                message: "Wouldn't you like to authorize this app " +
                "to use your Photo library?",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(
                title: "No", style: .cancel, handler: nil))
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
            choosePhotoButton.isEnabled = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization() { status in
                if status == .authorized {
                    self.fetchAllAssets()
                    self.choosePhotoButton.isEnabled = true
                } else {
                    statusAlert()
                }
            }
        case .restricted: break
        case .denied:
            statusAlert()
        }
    }
    
}
