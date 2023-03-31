// Copyright 2018-present 650 Industries. All rights reserved.

#import <ABI48_0_0ExpoModulesCore/ABI48_0_0EXReactCompatibleHelpers.h>

#import <ABI48_0_0React/ABI48_0_0RCTRootView.h>

#if __has_include(<ABI48_0_0React/ABI48_0_0RCTAppSetupUtils.h>)
#import <ABI48_0_0React/ABI48_0_0RCTAppSetupUtils.h>
#endif

UIView *ABI48_0_0EXAppSetupDefaultRootView(ABI48_0_0RCTBridge *bridge, NSString *moduleName, NSDictionary *initialProperties, BOOL fabricEnabled)
{
#if __has_include(<ABI48_0_0React/ABI48_0_0RCTAppSetupUtils.h>)

#if REACT_NATIVE_MINOR_VERSION >= 71
  return ABI48_0_0RCTAppSetupDefaultRootView(bridge, moduleName, initialProperties, fabricEnabled);
#else
  return ABI48_0_0RCTAppSetupDefaultRootView(bridge, moduleName, initialProperties);
#endif // REACT_NATIVE_MINOR_VERSION >= 71

#else
  return [[ABI48_0_0RCTRootView alloc] initWithBridge:bridge moduleName:moduleName initialProperties:initialProperties];
#endif // __has_include(<ABI48_0_0React/ABI48_0_0RCTAppSetupUtils.h>)
}

