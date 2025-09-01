#import "SvgDecoder.h"

#import "SvgDecoder-Swift.h"

@implementation SvgDecoder
RCT_EXPORT_MODULE()

- (BOOL)canDecodeImageData:(NSData *)imageData
{
  if (!imageData || imageData.length == 0) {
    return NO;
  }
  
  // Convert data to string to check for SVG markers
  NSString *dataString = [[NSString alloc] initWithData:imageData encoding:NSUTF8StringEncoding];
  
  if (!dataString) {
    return NO;
  }
  
  // Check for SVG indicators
  NSString *lowercaseString = [dataString lowercaseString];
  BOOL containsSVGTag = [lowercaseString containsString:@"<svg"];
  BOOL containsXMLDeclaration = [lowercaseString containsString:@"<?xml"];
  BOOL containsSVGNamespace = [lowercaseString containsString:@"http://www.w3.org/2000/svg"];
  
  return containsSVGTag || (containsXMLDeclaration && containsSVGNamespace);
}


- (RCTImageLoaderCancellationBlock)decodeImageData:(NSData *)imageData
                                              size:(CGSize)size
                                             scale:(CGFloat)scale
                                        resizeMode:(RCTResizeMode)resizeMode
                                 completionHandler:(RCTImageLoaderCompletionBlock)completionHandler
{
  // Create SVG instance from the image data
  SVG *svg = [[SVG alloc] initWithData:imageData ];
  
  if (!svg) {
    // If SVG creation failed, call completion handler with error
    NSError *error = [NSError errorWithDomain:@"SVGDecoderErrorDomain"
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to create SVG from data"}];
    completionHandler(error, nil);
    return ^{
      // Empty cancellation block since operation completed immediately
    };
  }
  
  // Get the natural size of the SVG
  CGSize naturalSize = svg.size;
  
  // Determine target size based on provided size parameter
  CGSize targetSize = size;
  if (CGSizeEqualToSize(targetSize, CGSizeZero)) {
    // If no size specified, use natural size
    targetSize = naturalSize;
  }
  
  // Apply scale factor
  if (scale > 0) {
    targetSize.width *= scale;
    targetSize.height *= scale;
  }
  
  // Handle resize mode (you may need to adjust this based on your RCTResizeMode enum values)
  switch (resizeMode) {
    case RCTResizeModeContain: {
      // Scale to fit within bounds while maintaining aspect ratio
      CGFloat scaleX = targetSize.width / naturalSize.width;
      CGFloat scaleY = targetSize.height / naturalSize.height;
      CGFloat finalScale = MIN(scaleX, scaleY);
      targetSize.width = naturalSize.width * finalScale;
      targetSize.height = naturalSize.height * finalScale;
      break;
    }
    case RCTResizeModeCover: {
      // Scale to fill bounds while maintaining aspect ratio (may crop)
      CGFloat scaleX = targetSize.width / naturalSize.width;
      CGFloat scaleY = targetSize.height / naturalSize.height;
      CGFloat finalScale = MAX(scaleX, scaleY);
      targetSize.width = naturalSize.width * finalScale;
      targetSize.height = naturalSize.height * finalScale;
      break;
    }
    case RCTResizeModeStretch:
      // Use targetSize as-is (will stretch to fit)
      break;
    case RCTResizeModeCenter:
      // Use natural size, ignore target size
      targetSize = naturalSize;
      break;
    default:
      break;
  }
  
  // Generate the image
  UIImage *image = [svg imageWithSize:targetSize];
  
  if (image) {
    // Success - call completion handler with the image
    completionHandler(nil, image);
  } else {
    // Failed to generate image
    NSError *error = [NSError errorWithDomain:@"SVGDecoderErrorDomain"
                                         code:2
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to render SVG to image"}];
    completionHandler(error, nil);
  }
  
  // Return cancellation block (empty since we're doing synchronous work)
  return ^{
    // Could potentially cancel ongoing operations here if needed
  };
}


- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
(const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativeSvgDecoderSpecJSI>(params);
}

@end
