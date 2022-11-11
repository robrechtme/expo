//
//  ABI47_0_0EXCameraUtils.h
//  Exponent
//
//  Created by Stanisław Chmiela on 23.10.2017.
//  Copyright © 2017 650 Industries. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <ABI47_0_0EXCamera/ABI47_0_0EXCamera.h>

@interface ABI47_0_0EXCameraUtils : NSObject

// Camera utilities
+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position;

// Enum conversions
+ (float)temperatureForWhiteBalance:(ABI47_0_0EXCameraWhiteBalance)whiteBalance;
+ (NSString *)captureSessionPresetForVideoResolution:(ABI47_0_0EXCameraVideoResolution)resolution;
+ (AVCaptureVideoOrientation)videoOrientationForDeviceOrientation:(UIDeviceOrientation)orientation;
+ (AVCaptureVideoOrientation)videoOrientationForInterfaceOrientation:(UIInterfaceOrientation)orientation;
+ (int)exportImageOrientation:(UIImageOrientation)orientation;
+ (AVVideoCodecType)videoCodecForType:(ABI47_0_0EXCameraVideoCodec)videoCodecType;

// Image utilities
+ (nonnull UIImage *)generatePhotoOfSize:(CGSize)size;
+ (UIImage *)cropImage:(UIImage *)image toRect:(CGRect)rect;
+ (nonnull NSString *)writeImage:(NSData *)image toPath:(NSString *)path;
+ (NSMutableDictionary *)updateExifMetadata:(NSDictionary *)metadata withAdditionalData:(NSDictionary *)additionalData;
+ (NSData *)dataFromImage:(UIImage *)image withMetadata:(NSDictionary *)exif imageQuality:(float)quality;

@end
