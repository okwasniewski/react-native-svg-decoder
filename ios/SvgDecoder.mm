#import "SvgDecoder.h"
#import "CoreSVG.h"

#if __has_include("SvgDecoder/SvgDecoder-Swift.h")
#import "SvgDecoder/SvgDecoder-Swift.h"
#else
#import "SvgDecoder-Swift.h"
#endif

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
  UIImage *image = [[CoreSVGWrapper alloc] imageFromSVGData:imageData targetSize:size];
  
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
