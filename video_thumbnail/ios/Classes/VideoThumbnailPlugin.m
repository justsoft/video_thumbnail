#import "VideoThumbnailPlugin.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#if __has_include("webp/decode.h") && __has_include("webp/encode.h") && __has_include("webp/demux.h") && __has_include("webp/mux.h")
#import "webp/decode.h"
#import "webp/encode.h"
#import "webp/demux.h"
#import "webp/mux.h"
#elif __has_include(<libwebp/decode.h>) && __has_include(<libwebp/encode.h>) && __has_include(<libwebp/demux.h>) && __has_include(<libwebp/mux.h>)
#import <libwebp/decode.h>
#import <libwebp/encode.h>
#import <libwebp/demux.h>
#import <libwebp/mux.h>
#endif

@implementation VideoThumbnailPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"plugins.justsoft.xyz/video_thumbnail"
                                     binaryMessenger:[registrar messenger]];
    VideoThumbnailPlugin* instance = [[VideoThumbnailPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    
    NSDictionary *_args = call.arguments;
    
    NSString *file = _args[@"video"];

    NSMutableDictionary * headers = _args[@"headers"];

    NSString *path = _args[@"path"];
    int format = [[_args objectForKey:@"format"] intValue];
    int maxh = [[_args objectForKey:@"maxh"] intValue];
    int maxw = [[_args objectForKey:@"maxw"] intValue];
    int timeMs = [[_args objectForKey:@"timeMs"] intValue];
    int quality = [[_args objectForKey:@"quality"] intValue];
    _args = nil;
    bool isLocalFile = [file hasPrefix:@"file://"] || [file hasPrefix:@"/"];
    
    NSURL *url = [file hasPrefix:@"file://"] ? [NSURL fileURLWithPath:[file substringFromIndex:7]] :
      ( [file hasPrefix:@"/"] ? [NSURL fileURLWithPath:file] : [NSURL URLWithString:file] );
    
    if ([@"data" isEqualToString:call.method]) {

        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            //Background Thread
            result([VideoThumbnailPlugin generateThumbnail:url headers:headers format:format maxHeight:maxh maxWidth:maxw timeMs:timeMs quality:quality]);
        });
        
    } else if ([@"file" isEqualToString:call.method]) {
        if( [path isEqual:[NSNull null]] && !isLocalFile ) {
            path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        }
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            //Background Thread
           
            NSData *data = [VideoThumbnailPlugin generateThumbnail:url headers:headers format:format maxHeight:maxh maxWidth:maxw timeMs:timeMs quality:quality];
            NSString *ext = ( (format == 0 ) ? @"jpg" : ( format == 1 ) ? @"png" : @"webp" );
            NSURL *thumbnail = [[url URLByDeletingPathExtension] URLByAppendingPathExtension:ext];

            if(path && [path isKindOfClass:[NSString class]] && path.length>0) {
                NSString *lastPart = [thumbnail lastPathComponent];
                thumbnail = [NSURL fileURLWithPath:path];
                if( ![[thumbnail pathExtension] isEqualToString:ext] ) {
                    thumbnail = [thumbnail URLByAppendingPathComponent:lastPart];
                }
            }
            
            NSError *error = nil;
            if( [data writeToURL:thumbnail options:0 error:&error] != YES ) {
                if( error != nil ) {
                    result( [FlutterError errorWithCode:[NSString stringWithFormat:@"Error %ld", error.code]
                                                message:error.domain
                                                details:error.localizedDescription] );
                } else result( [FlutterError errorWithCode:@"IO Error" message:@"Failed to write data to file" details:nil] );
            } else {
                NSString *fullpath = [thumbnail absoluteString];
                if([fullpath hasPrefix:@"file://"]) {
                    result([fullpath substringFromIndex:7]);
                }
                else {
                    result(fullpath);
                }
            }
        });
        
    } else {
        result(FlutterMethodNotImplemented);
    }
}

+ (NSData *)generateThumbnail:(NSURL*)url headers:(NSMutableDictionary*)headers  format:(int)format maxHeight:(int)maxh maxWidth:(int)maxw timeMs:(int)timeMs quality:(int)quality {
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options: [headers isEqual:[NSNull null]] ? nil : @{@"AVURLAssetHTTPHeaderFieldsKey" : headers}];
    AVAssetImageGenerator *imgGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    imgGenerator.appliesPreferredTrackTransform = YES;
    imgGenerator.maximumSize = CGSizeMake((CGFloat)maxw, (CGFloat)maxh);
    imgGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    imgGenerator.requestedTimeToleranceAfter = CMTimeMake(100, 1000);
    
    NSError *error = nil;
    CGImageRef cgImage = [imgGenerator copyCGImageAtTime:CMTimeMake(timeMs, 1000) actualTime:nil error:&error];
    
    if( error != nil ) {
        NSLog(@"couldn't generate thumbnail, error:%@", error);
        return nil;
    }
    
    if( format <= 1 ) {
        UIImage *thumbnail = [UIImage imageWithCGImage:cgImage];
        
        CGImageRelease(cgImage);  // CGImageRef won't be released by ARC
        
        if( format == 0 ) {
            CGFloat fQuality = ( CGFloat) ( quality * 0.01 );
            return UIImageJPEGRepresentation( thumbnail, fQuality );
        } else {
            return UIImagePNGRepresentation( thumbnail );
        }
    } else {
        CGColorSpaceRef colorSpace = CGImageGetColorSpace(cgImage);
        if (CGColorSpaceGetModel(colorSpace) != kCGColorSpaceModelRGB) {
            CGImageRelease(cgImage);
            return nil;
        }
        CGImageAlphaInfo ainfo = CGImageGetAlphaInfo( cgImage );
        CGBitmapInfo binfo = CGImageGetBitmapInfo( cgImage );
        
        CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImage);
        CFDataRef imageData = CGDataProviderCopyData(dataProvider);
        UInt8 *rawData = ( UInt8 * ) CFDataGetBytePtr(imageData);
        
        int width = ( int ) CGImageGetWidth(cgImage);
        int height = ( int ) CGImageGetHeight(cgImage);
        int stride = ( int ) CGImageGetBytesPerRow(cgImage);
        size_t ret_size = 0;
        uint8_t *output = NULL;
        
        // preprocess the data for libwebp
        if( ainfo == kCGImageAlphaPremultipliedFirst || ainfo == kCGImageAlphaNoneSkipFirst ) {
            if( ( binfo & kCGBitmapByteOrderMask ) == kCGBitmapByteOrder32Little ) {
                // Little-endian ( iPhone )
                if( quality == 100 )
                    ret_size = WebPEncodeLosslessBGRA(rawData, width, height, stride, &output);
                else
                    ret_size = WebPEncodeBGRA(rawData, width, height, stride, (float)quality, &output);
            } else 
                if( ( binfo & kCGBitmapByteOrderMask ) == kCGBitmapByteOrder32Big ) {
                    // Big-endian ( iPhone Simulator )
                    for(int y = 0;y<height;y++) {
                        uint32_t *p = ( uint32_t * ) ( ( (uint8_t * ) (rawData + y*stride) ) );
                        for(int x = 0; x<width;x++,p++) {
                            uint32_t u = *p;
                            *p = ( ( u << 24 ) & 0xFF000000 ) | ( ( u >> 8 ) & 0x00FFFFFF );
                        }
                    }
                    if( quality == 100 )
                        ret_size = WebPEncodeLosslessRGBA(rawData, width, height, stride, &output);
                    else
                        ret_size = WebPEncodeRGBA(rawData, width, height, stride, (float)quality, &output);
                }
        }
        else {
            NSLog(@"Sorry, don't support this CGImageAlphaInfo: %d", (int) binfo );
        }
        CGDataProviderRelease(dataProvider);
        CFRelease(imageData);
        CGColorSpaceRelease(colorSpace);
        
        if (ret_size == 0) {
            return nil;
        }
        NSData *data = [NSData dataWithBytes:(const void *)output length:ret_size];
        return( data );
    }
}

@end
