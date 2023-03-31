// Copyright 2019-present 650 Industries. All rights reserved.

#import <ABI48_0_0ExpoModulesCore/ABI48_0_0EXAppLifecycleService.h>
#import <ABI48_0_0ExpoModulesCore/ABI48_0_0EXDefines.h>
#import <ABI48_0_0ExpoModulesCore/ABI48_0_0EXEventEmitterService.h>
#import <ABI48_0_0ExpoModulesCore/ABI48_0_0EXModuleRegistryProvider.h>

#import <ABI48_0_0EXScreenOrientation/ABI48_0_0EXScreenOrientationModule.h>
#import <ABI48_0_0EXScreenOrientation/ABI48_0_0EXScreenOrientationUtilities.h>
#import <ABI48_0_0EXScreenOrientation/ABI48_0_0EXScreenOrientationRegistry.h>

#import <UIKit/UIKit.h>

static NSString *const ABI48_0_0EXScreenOrientationDidUpdateDimensions = @"expoDidUpdateDimensions";

@interface ABI48_0_0EXScreenOrientationModule ()

@property (nonatomic, weak) ABI48_0_0EXScreenOrientationRegistry *screenOrientationRegistry;
@property (nonatomic, weak) id<ABI48_0_0EXEventEmitterService> eventEmitter;

@end

@implementation ABI48_0_0EXScreenOrientationModule

ABI48_0_0EX_EXPORT_MODULE(ExpoScreenOrientation);

-(void)dealloc
{
  [self stopObserving];
  [_screenOrientationRegistry moduleWillDeallocate:self];
}

- (void)setModuleRegistry:(ABI48_0_0EXModuleRegistry *)moduleRegistry
{
  _screenOrientationRegistry = [moduleRegistry getSingletonModuleForName:@"ScreenOrientationRegistry"];
  [[moduleRegistry getModuleImplementingProtocol:@protocol(ABI48_0_0EXAppLifecycleService)] registerAppLifecycleListener:self];
  _eventEmitter = [moduleRegistry getModuleImplementingProtocol:@protocol(ABI48_0_0EXEventEmitterService)];

  // TODO: This shouldn't be here, but it temporarily fixes
  // https://github.com/expo/expo/issues/13641 and https://github.com/expo/expo/issues/11558
  // We're going to redesign this once we drop support for multiple apps being open in Expo Go at the same time.
  // Then we probably won't need the screen orientation registry at all. (@tsapeta)
  [self onAppForegrounded];
}

ABI48_0_0EX_EXPORT_METHOD_AS(lockAsync,
                    lockAsync:(NSNumber *)orientationLock
                    resolver:(ABI48_0_0EXPromiseResolveBlock)resolve
                    rejecter:(ABI48_0_0EXPromiseRejectBlock)reject)
{
  UIInterfaceOrientationMask orientationMask = [ABI48_0_0EXScreenOrientationUtilities importOrientationLock:orientationLock];
  
  if (!orientationMask) {
    return reject(@"ERR_SCREEN_ORIENTATION_INVALID_ORIENTATION_LOCK", [NSString stringWithFormat:@"Invalid screen orientation lock %@", orientationLock], nil);
  }
  if (![ABI48_0_0EXScreenOrientationUtilities doesDeviceSupportOrientationMask:orientationMask]) {
    return reject(@"ERR_SCREEN_ORIENTATION_UNSUPPORTED_ORIENTATION_LOCK", [NSString stringWithFormat:@"This device does not support the requested orientation %@", orientationLock], nil);
  }
  
  [_screenOrientationRegistry setMask:orientationMask forModule:self];
  resolve(nil);
}

ABI48_0_0EX_EXPORT_METHOD_AS(lockPlatformAsync,
                    lockPlatformAsync:(NSArray <NSNumber *> *)allowedOrientations
                    resolver:(ABI48_0_0EXPromiseResolveBlock)resolve
                    rejecter:(ABI48_0_0EXPromiseRejectBlock)reject)
{
  // combine all the allowedOrientations into one bitmask
  UIInterfaceOrientationMask allowedOrientationsMask = 0;
  for (NSNumber *allowedOrientation in allowedOrientations) {
    UIInterfaceOrientation orientation = [ABI48_0_0EXScreenOrientationUtilities importOrientation:allowedOrientation];
    UIInterfaceOrientationMask orientationMask = [ABI48_0_0EXScreenOrientationUtilities maskFromOrientation:orientation];
    if (!orientationMask) {
      return reject(@"ERR_SCREEN_ORIENTATION_INVALID_ORIENTATION_LOCK", @"Invalid screen orientation lock.", nil);
    }
                                                                         
    allowedOrientationsMask = allowedOrientationsMask | orientationMask;
  }
  
  if (![ABI48_0_0EXScreenOrientationUtilities doesDeviceSupportOrientationMask:allowedOrientationsMask]) {
    return reject(@"ERR_SCREEN_ORIENTATION_UNSUPPORTED_ORIENTATION_LOCK", @"This device does not support the requested orientation.", nil);
  }
  
  [_screenOrientationRegistry setMask:allowedOrientationsMask forModule:self];
  resolve(nil);
}

ABI48_0_0EX_EXPORT_METHOD_AS(getOrientationLockAsync,
                    getOrientationLockAsyncWithResolver:(ABI48_0_0EXPromiseResolveBlock)resolve
                    rejecter:(ABI48_0_0EXPromiseRejectBlock)reject)
{
  resolve([ABI48_0_0EXScreenOrientationUtilities exportOrientationLock:[_screenOrientationRegistry currentOrientationMask]]);
}

ABI48_0_0EX_EXPORT_METHOD_AS(getPlatformOrientationLockAsync,
                    getPlatformOrientationLockAsyncResolver:(ABI48_0_0EXPromiseResolveBlock)resolve
                    rejecter:(ABI48_0_0EXPromiseRejectBlock)reject)
{
  UIInterfaceOrientationMask orientationMask = [_screenOrientationRegistry currentOrientationMask];
  NSDictionary *maskToOrienationMap = @{
    @(UIInterfaceOrientationMaskPortrait): @(UIInterfaceOrientationPortrait),
    @(UIInterfaceOrientationMaskPortraitUpsideDown): @(UIInterfaceOrientationPortraitUpsideDown),
    @(UIInterfaceOrientationMaskLandscapeLeft): @(UIInterfaceOrientationLandscapeLeft),
    @(UIInterfaceOrientationMaskLandscapeRight): @(UIInterfaceOrientationLandscapeRight)
  };
  // If the particular orientation is supported, we add it to the array of allowedOrientations
  NSMutableArray *allowedOrientations = [[NSMutableArray alloc] init];
  for (NSNumber *wrappedSingleOrientation in [maskToOrienationMap allKeys]) {
    UIInterfaceOrientationMask supportedOrientationMask = orientationMask & [wrappedSingleOrientation intValue];
    if (supportedOrientationMask) {
      UIInterfaceOrientation supportedOrientation = [maskToOrienationMap[@(supportedOrientationMask)] intValue];
      [allowedOrientations addObject:[ABI48_0_0EXScreenOrientationUtilities exportOrientation:supportedOrientation]];
    }
  }
  resolve(allowedOrientations);
}

ABI48_0_0EX_EXPORT_METHOD_AS(supportsOrientationLockAsync,
                    supportsOrientationLockAsync:(NSNumber *)orientationLock
                    resolver:(ABI48_0_0EXPromiseResolveBlock)resolve
                    rejecter:(ABI48_0_0EXPromiseRejectBlock)reject)
{
  UIInterfaceOrientationMask orientationMask = [ABI48_0_0EXScreenOrientationUtilities importOrientationLock:orientationLock];
 
  if (orientationMask && [ABI48_0_0EXScreenOrientationUtilities doesDeviceSupportOrientationMask:orientationMask]) {
    return resolve(@YES);
  }
  
  resolve(@NO);
}

ABI48_0_0EX_EXPORT_METHOD_AS(getOrientationAsync,
                    getOrientationAsyncResolver:(ABI48_0_0EXPromiseResolveBlock)resolve
                    rejecter:(ABI48_0_0EXPromiseRejectBlock)reject)
{
  resolve([ABI48_0_0EXScreenOrientationUtilities exportOrientation:[_screenOrientationRegistry currentOrientation]]);
}

// Will be called when this module's first listener is added.
- (void)startObserving
{
  [_screenOrientationRegistry registerModuleToReceiveNotification:self];
}

// Will be called when this module's last listener is removed, or on dealloc.
- (void)stopObserving
{
  [_screenOrientationRegistry unregisterModuleFromReceivingNotification:self];
}

- (void)screenOrientationDidChange:(UIInterfaceOrientation)orientation
{
  UITraitCollection * currentTraitCollection = [_screenOrientationRegistry currentTrailCollection];
  [_eventEmitter sendEventWithName:ABI48_0_0EXScreenOrientationDidUpdateDimensions body:@{
    @"orientationLock": [ABI48_0_0EXScreenOrientationUtilities exportOrientationLock:[_screenOrientationRegistry currentOrientationMask]],
    @"orientationInfo": @{
      @"orientation": [ABI48_0_0EXScreenOrientationUtilities exportOrientation:orientation],
      @"verticalSizeClass": ABI48_0_0EXNullIfNil(@(currentTraitCollection.verticalSizeClass)),
      @"horizontalSizeClass": ABI48_0_0EXNullIfNil(@(currentTraitCollection.horizontalSizeClass)),
    }
  }];
}

- (NSArray<NSString *> *)supportedEvents {
  return @[ABI48_0_0EXScreenOrientationDidUpdateDimensions];
}

- (void)onAppBackgrounded {
  [_screenOrientationRegistry moduleDidBackground:self];
}

- (void)onAppForegrounded {
  [_screenOrientationRegistry moduleDidForeground:self];
}

@end
