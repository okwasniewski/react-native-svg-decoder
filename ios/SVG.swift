import Darwin
import Foundation
import UIKit

@objc
class CGSVGDocument: NSObject { }

var CGSVGDocumentRetain: (@convention(c) (CGSVGDocument?) -> Unmanaged<CGSVGDocument>?) = load("CGSVGDocumentRetain")
var CGSVGDocumentRelease: (@convention(c) (CGSVGDocument?) -> Void) = load("CGSVGDocumentRelease")
var CGSVGDocumentCreateFromData: (@convention(c) (CFData?, CFDictionary?) -> Unmanaged<CGSVGDocument>?) = load("CGSVGDocumentCreateFromData")
var CGContextDrawSVGDocument: (@convention(c) (CGContext?, CGSVGDocument?) -> Void) = load("CGContextDrawSVGDocument")
var CGSVGDocumentGetCanvasSize: (@convention(c) (CGSVGDocument?) -> CGSize) = load("CGSVGDocumentGetCanvasSize")

typealias ImageWithCGSVGDocument = @convention(c) (AnyObject, Selector, CGSVGDocument) -> UIImage
var ImageWithCGSVGDocumentSEL: Selector = NSSelectorFromString("_imageWithCGSVGDocument:")

let CoreSVG = dlopen("/System/Library/PrivateFrameworks/CoreSVG.framework/CoreSVG", RTLD_NOW)

func load<T>(_ name: String) -> T {
  unsafeBitCast(dlsym(CoreSVG, name), to: T.self)
}

@objc
@objcMembers
public class SVG: NSObject {
  
  private let document: CGSVGDocument
  
  deinit { CGSVGDocumentRelease(document) }
  
  @objc
  public convenience init?(string value: String) {
    guard let data = value.data(using: .utf8) else { return nil }
    self.init(data: data)
  }
  
  @objc
  public init?(data: Data) {
    guard let document = CGSVGDocumentCreateFromData(data as CFData, nil)?.takeUnretainedValue() else { return nil }
    guard CGSVGDocumentGetCanvasSize(document) != .zero else { return nil }
    self.document = document
    super.init()
  }
  
  @objc
  public var size: CGSize {
    return CGSVGDocumentGetCanvasSize(document)
  }
  
  @objc
  public func image() -> UIImage? {
    let ImageWithCGSVGDocument = unsafeBitCast(UIImage.self.method(for: ImageWithCGSVGDocumentSEL), to: ImageWithCGSVGDocument.self)
    let image = ImageWithCGSVGDocument(UIImage.self, ImageWithCGSVGDocumentSEL, document)
    return image
  }
  
  @objc
  public func imageWithSize(_ size: CGSize) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
    guard let context = UIGraphicsGetCurrentContext() else {
      UIGraphicsEndImageContext()
      return nil
    }
    drawInContext(context, size: size)
    defer { UIGraphicsEndImageContext() }
    return UIGraphicsGetImageFromCurrentImageContext()
  }
  
  @objc
  public func drawInContext(_ context: CGContext) {
    drawInContext(context, size: size)
  }
  
  @objc
  public func drawInContext(_ context: CGContext, size target: CGSize) {
    var target = target
    
    let ratio = (
      x: target.width / size.width,
      y: target.height / size.height
    )
    
    let rect = (
      document: CGRect(origin: .zero, size: size), ()
    )
    
    let scale: (x: CGFloat, y: CGFloat)
    
    if target.width <= 0 {
      scale = (ratio.y, ratio.y)
      target.width = size.width * scale.x
    } else if target.height <= 0 {
      scale = (ratio.x, ratio.x)
      target.width = size.width * scale.y
    } else {
      let min = min(ratio.x, ratio.y)
      scale = (min, min)
      target.width = size.width * scale.x
      target.height = size.height * scale.y
    }
    
    let transform = (
      scale: CGAffineTransform(scaleX: scale.x, y: scale.y),
      aspect: CGAffineTransform(translationX: (target.width / scale.x - rect.document.width) / 2, y: (target.height / scale.y - rect.document.height) / 2)
    )
    
    context.translateBy(x: 0, y: target.height)
    context.scaleBy(x: 1, y: -1)
    context.concatenate(transform.scale)
    context.concatenate(transform.aspect)
    
    CGContextDrawSVGDocument(context, document)
  }
}
