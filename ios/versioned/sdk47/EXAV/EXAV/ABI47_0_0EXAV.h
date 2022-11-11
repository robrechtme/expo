// Copyright 2017-present 650 Industries. All rights reserved.

#import <AVFoundation/AVFoundation.h>

#import <ABI47_0_0React/ABI47_0_0RCTBridgeModule.h>

#import <ABI47_0_0ExpoModulesCore/ABI47_0_0EXModuleRegistryConsumer.h>
#import <ABI47_0_0ExpoModulesCore/ABI47_0_0EXAppLifecycleListener.h>
#import <ABI47_0_0ExpoModulesCore/ABI47_0_0EXExportedModule.h>
#import <ABI47_0_0ExpoModulesCore/ABI47_0_0EXEventEmitter.h>
#import <ABI47_0_0EXAV/ABI47_0_0EXAVObject.h>

typedef NS_OPTIONS(NSUInteger, ABI47_0_0EXAudioInterruptionMode)
{
  ABI47_0_0EXAudioInterruptionModeMixWithOthers = 0,
  ABI47_0_0EXAudioInterruptionModeDoNotMix      = 1,
  ABI47_0_0EXAudioInterruptionModeDuckOthers    = 2
};

typedef NS_OPTIONS(NSUInteger, ABI47_0_0EXAudioRecordingOptionBitRateStrategy)
{
  ABI47_0_0EXAudioRecordingOptionBitRateStrategyConstant            = 0,
  ABI47_0_0EXAudioRecordingOptionBitRateStrategyLongTermAverage     = 1,
  ABI47_0_0EXAudioRecordingOptionBitRateStrategyVariableConstrained = 2,
  ABI47_0_0EXAudioRecordingOptionBitRateStrategyVariable            = 3
};

@protocol ABI47_0_0EXAVScopedModuleDelegate

// Call this when your module knows it won't use the audio session now
// but may do in the future (settings persist).
- (void)moduleDidBackground:(id)module;
// Call this when your module knows it will use the audio session now.
- (void)moduleDidForeground:(id)module;
// Call this when your module knows it won't use the audio session now
// or in the future (forget settings).
- (void)moduleWillDeallocate:(id)module;
- (BOOL)isActiveForModule:(id)module;
- (NSString *)activeCategory;
- (AVAudioSessionCategoryOptions)activeCategoryOptions;
- (NSError *)setActive:(BOOL)active forModule:(id)module;
- (NSError *)setCategory:(NSString *)category withOptions:(AVAudioSessionCategoryOptions)options forModule:(id)module;
- (AVAudioSessionPortDescription *) activeInput;
- (NSError *)setActiveInput:(AVAudioSessionPortDescription *)activeInput;

@end

@protocol ABI47_0_0EXAVInterface

- (NSError *)promoteAudioSessionIfNecessary;

- (NSError *)demoteAudioSessionIfPossible;

- (void)registerVideoForAudioLifecycle:(NSObject<ABI47_0_0EXAVObject> *)video;

- (void)unregisterVideoForAudioLifecycle:(NSObject<ABI47_0_0EXAVObject> *)video;

@end

@interface ABI47_0_0EXAV : ABI47_0_0EXExportedModule <ABI47_0_0RCTBridgeModule, ABI47_0_0EXEventEmitter, ABI47_0_0EXAppLifecycleListener, ABI47_0_0EXModuleRegistryConsumer, ABI47_0_0EXAVInterface>

- (void)handleMediaServicesReset:(NSNotification *)notification;
- (void)handleAudioSessionInterruption:(NSNotification *)notification;

@end
