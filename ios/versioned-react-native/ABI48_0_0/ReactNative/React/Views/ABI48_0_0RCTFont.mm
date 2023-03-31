/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "ABI48_0_0RCTFont.h"
#import "ABI48_0_0RCTAssert.h"
#import "ABI48_0_0RCTLog.h"

#import <CoreText/CoreText.h>

typedef CGFloat ABI48_0_0RCTFontWeight;
static ABI48_0_0RCTFontWeight weightOfFont(UIFont *font)
{
  static NSArray<NSString *> *weightSuffixes;
  static NSArray<NSNumber *> *fontWeights;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // We use two arrays instead of one map because
    // the order is important for suffix matching.
    weightSuffixes = @[
      @"normal",
      @"ultralight",
      @"thin",
      @"light",
      @"regular",
      @"medium",
      @"semibold",
      @"demibold",
      @"extrabold",
      @"ultrabold",
      @"bold",
      @"heavy",
      @"black"
    ];
    fontWeights = @[
      @(UIFontWeightRegular),
      @(UIFontWeightUltraLight),
      @(UIFontWeightThin),
      @(UIFontWeightLight),
      @(UIFontWeightRegular),
      @(UIFontWeightMedium),
      @(UIFontWeightSemibold),
      @(UIFontWeightSemibold),
      @(UIFontWeightHeavy),
      @(UIFontWeightHeavy),
      @(UIFontWeightBold),
      @(UIFontWeightHeavy),
      @(UIFontWeightBlack)
    ];
  });

  NSString *fontName = font.fontName;
  NSInteger i = 0;
  for (NSString *suffix in weightSuffixes) {
    // CFStringFind is much faster than any variant of rangeOfString: because it does not use a locale.
    auto options = kCFCompareCaseInsensitive | kCFCompareAnchored | kCFCompareBackwards;
    if (CFStringFind((CFStringRef)fontName, (CFStringRef)suffix, options).location != kCFNotFound) {
      return (ABI48_0_0RCTFontWeight)fontWeights[i].doubleValue;
    }
    i++;
  }

  auto traits = (__bridge_transfer NSDictionary *)CTFontCopyTraits((CTFontRef)font);
  return (ABI48_0_0RCTFontWeight)[traits[UIFontWeightTrait] doubleValue];
}

static BOOL isItalicFont(UIFont *font)
{
  return (CTFontGetSymbolicTraits((CTFontRef)font) & kCTFontTraitItalic) != 0;
}

static BOOL isCondensedFont(UIFont *font)
{
  return (CTFontGetSymbolicTraits((CTFontRef)font) & kCTFontTraitCondensed) != 0;
}

static ABI48_0_0RCTFontHandler defaultFontHandler;

void ABI48_0_0RCTSetDefaultFontHandler(ABI48_0_0RCTFontHandler handler)
{
  defaultFontHandler = handler;
}

BOOL ABI48_0_0RCTHasFontHandlerSet()
{
  return defaultFontHandler != nil;
}

// We pass a string description of the font weight to the defaultFontHandler because UIFontWeight
// is not defined pre-iOS 8.2.
// Furthermore, UIFontWeight's are lossy floats, so we must use an inexact compare to figure out
// which one we actually have.
static inline BOOL CompareFontWeights(UIFontWeight firstWeight, UIFontWeight secondWeight)
{
#if CGFLOAT_IS_DOUBLE
  return fabs(firstWeight - secondWeight) < 0.01;
#else
  return fabsf(firstWeight - secondWeight) < 0.01;
#endif
}

static NSString *FontWeightDescriptionFromUIFontWeight(UIFontWeight fontWeight)
{
  if (CompareFontWeights(fontWeight, UIFontWeightUltraLight)) {
    return @"ultralight";
  } else if (CompareFontWeights(fontWeight, UIFontWeightThin)) {
    return @"thin";
  } else if (CompareFontWeights(fontWeight, UIFontWeightLight)) {
    return @"light";
  } else if (CompareFontWeights(fontWeight, UIFontWeightRegular)) {
    return @"regular";
  } else if (CompareFontWeights(fontWeight, UIFontWeightMedium)) {
    return @"medium";
  } else if (CompareFontWeights(fontWeight, UIFontWeightSemibold)) {
    return @"semibold";
  } else if (CompareFontWeights(fontWeight, UIFontWeightBold)) {
    return @"bold";
  } else if (CompareFontWeights(fontWeight, UIFontWeightHeavy)) {
    return @"heavy";
  } else if (CompareFontWeights(fontWeight, UIFontWeightBlack)) {
    return @"black";
  }
  ABI48_0_0RCTAssert(NO, @"Unknown UIFontWeight passed in: %f", fontWeight);
  return @"regular";
}

static UIFont *cachedSystemFont(CGFloat size, ABI48_0_0RCTFontWeight weight)
{
  static NSCache<NSValue *, UIFont *> *fontCache = [NSCache new];

  struct __attribute__((__packed__)) CacheKey {
    CGFloat size;
    ABI48_0_0RCTFontWeight weight;
  };

  CacheKey key{size, weight};
  NSValue *cacheKey = [[NSValue alloc] initWithBytes:&key objCType:@encode(CacheKey)];
  UIFont *font = [fontCache objectForKey:cacheKey];

  if (!font) {
    if (defaultFontHandler) {
      NSString *fontWeightDescription = FontWeightDescriptionFromUIFontWeight(weight);
      font = defaultFontHandler(size, fontWeightDescription);
    } else {
      font = [UIFont systemFontOfSize:size weight:weight];
    }

    [fontCache setObject:font forKey:cacheKey];
  }

  return font;
}

// Caching wrapper around expensive +[UIFont fontNamesForFamilyName:]
static NSArray<NSString *> *fontNamesForFamilyName(NSString *familyName)
{
  static NSCache<NSString *, NSArray<NSString *> *> *cache;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cache = [NSCache new];
    [NSNotificationCenter.defaultCenter
        addObserverForName:(NSNotificationName)kCTFontManagerRegisteredFontsChangedNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *) {
                  [cache removeAllObjects];
                }];
  });

  auto names = [cache objectForKey:familyName];
  if (!names) {
    names = [UIFont fontNamesForFamilyName:familyName] ?: [NSArray new];
    [cache setObject:names forKey:familyName];
  }
  return names;
}

@implementation ABI48_0_0RCTConvert (ABI48_0_0RCTFont)

+ (UIFont *)UIFont:(id)json
{
  json = [self NSDictionary:json];
  return [ABI48_0_0RCTFont updateFont:nil
                  withFamily:[ABI48_0_0RCTConvert NSString:json[@"fontFamily"]]
                        size:[ABI48_0_0RCTConvert NSNumber:json[@"fontSize"]]
                      weight:[ABI48_0_0RCTConvert NSString:json[@"fontWeight"]]
                       style:[ABI48_0_0RCTConvert NSString:json[@"fontStyle"]]
                     variant:[ABI48_0_0RCTConvert NSStringArray:json[@"fontVariant"]]
             scaleMultiplier:1];
}

ABI48_0_0RCT_ENUM_CONVERTER(
    ABI48_0_0RCTFontWeight,
    (@{
      @"normal" : @(UIFontWeightRegular),
      @"bold" : @(UIFontWeightBold),
      @"100" : @(UIFontWeightUltraLight),
      @"200" : @(UIFontWeightThin),
      @"300" : @(UIFontWeightLight),
      @"400" : @(UIFontWeightRegular),
      @"500" : @(UIFontWeightMedium),
      @"600" : @(UIFontWeightSemibold),
      @"700" : @(UIFontWeightBold),
      @"800" : @(UIFontWeightHeavy),
      @"900" : @(UIFontWeightBlack),
    }),
    UIFontWeightRegular,
    doubleValue)

typedef BOOL ABI48_0_0RCTFontStyle;
ABI48_0_0RCT_ENUM_CONVERTER(
    ABI48_0_0RCTFontStyle,
    (@{
      @"normal" : @NO,
      @"italic" : @YES,
      @"oblique" : @YES,
    }),
    NO,
    boolValue)

typedef NSDictionary ABI48_0_0RCTFontVariantDescriptor;
+ (ABI48_0_0RCTFontVariantDescriptor *)ABI48_0_0RCTFontVariantDescriptor:(id)json
{
  static NSDictionary *mapping;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    mapping = @{
      @"small-caps" : @{
        UIFontFeatureTypeIdentifierKey : @(kLowerCaseType),
        UIFontFeatureSelectorIdentifierKey : @(kLowerCaseSmallCapsSelector),
      },
      @"oldstyle-nums" : @{
        UIFontFeatureTypeIdentifierKey : @(kNumberCaseType),
        UIFontFeatureSelectorIdentifierKey : @(kLowerCaseNumbersSelector),
      },
      @"lining-nums" : @{
        UIFontFeatureTypeIdentifierKey : @(kNumberCaseType),
        UIFontFeatureSelectorIdentifierKey : @(kUpperCaseNumbersSelector),
      },
      @"tabular-nums" : @{
        UIFontFeatureTypeIdentifierKey : @(kNumberSpacingType),
        UIFontFeatureSelectorIdentifierKey : @(kMonospacedNumbersSelector),
      },
      @"proportional-nums" : @{
        UIFontFeatureTypeIdentifierKey : @(kNumberSpacingType),
        UIFontFeatureSelectorIdentifierKey : @(kProportionalNumbersSelector),
      },
      @"stylistic-one" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltOneOnSelector),
      },
      @"stylistic-two" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltTwoOnSelector),
      },
      @"stylistic-three" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltThreeOnSelector),
      },
      @"stylistic-four" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltFourOnSelector),
      },
      @"stylistic-five" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltFiveOnSelector),
      },
      @"stylistic-six" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltSixOnSelector),
      },
      @"stylistic-seven" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltSevenOnSelector),
      },
      @"stylistic-eight" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltEightOnSelector),
      },
      @"stylistic-nine" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltNineOnSelector),
      },
      @"stylistic-ten" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltTenOnSelector),
      },
      @"stylistic-eleven" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltElevenOnSelector),
      },
      @"stylistic-twelve" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltTwelveOnSelector),
      },
      @"stylistic-thirteen" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltThirteenOnSelector),
      },
      @"stylistic-fourteen" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltFourteenOnSelector),
      },
      @"stylistic-fifteen" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltFifteenOnSelector),
      },
      @"stylistic-sixteen" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltSixteenOnSelector),
      },
      @"stylistic-seventeen" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltSeventeenOnSelector),
      },
      @"stylistic-eighteen" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltEighteenOnSelector),
      },
      @"stylistic-nineteen" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltNineteenOnSelector),
      },
      @"stylistic-twenty" : @{
        UIFontFeatureTypeIdentifierKey : @(kStylisticAlternativesType),
        UIFontFeatureSelectorIdentifierKey : @(kStylisticAltTwentyOnSelector),
      }
    };
  });
  ABI48_0_0RCTFontVariantDescriptor *value = mapping[json];
  if (ABI48_0_0RCT_DEBUG && !value && [json description].length > 0) {
    ABI48_0_0RCTLogError(
        @"Invalid ABI48_0_0RCTFontVariantDescriptor '%@'. should be one of: %@",
        json,
        [[mapping allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]);
  }
  return value;
}

ABI48_0_0RCT_ARRAY_CONVERTER(ABI48_0_0RCTFontVariantDescriptor)

@end

@implementation ABI48_0_0RCTFont

+ (UIFont *)updateFont:(UIFont *)font
            withFamily:(NSString *)family
                  size:(NSNumber *)size
                weight:(NSString *)weight
                 style:(NSString *)style
               variant:(NSArray<ABI48_0_0RCTFontVariantDescriptor *> *)variant
       scaleMultiplier:(CGFloat)scaleMultiplier
{
  // Defaults
  static NSString *defaultFontFamily;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    defaultFontFamily = [UIFont systemFontOfSize:14].familyName;
  });
  const ABI48_0_0RCTFontWeight defaultFontWeight = UIFontWeightRegular;
  const CGFloat defaultFontSize = 14;

  // Initialize properties to defaults
  CGFloat fontSize = defaultFontSize;
  ABI48_0_0RCTFontWeight fontWeight = defaultFontWeight;
  NSString *familyName = defaultFontFamily;
  BOOL isItalic = NO;
  BOOL isCondensed = NO;

  if (font) {
    familyName = font.familyName ?: defaultFontFamily;
    fontSize = font.pointSize ?: defaultFontSize;
    fontWeight = weightOfFont(font);
    isItalic = isItalicFont(font);
    isCondensed = isCondensedFont(font);
  }

  // Get font attributes
  fontSize = [ABI48_0_0RCTConvert CGFloat:size] ?: fontSize;
  if (scaleMultiplier > 0.0 && scaleMultiplier != 1.0) {
    fontSize = round(fontSize * scaleMultiplier);
  }
  familyName = [ABI48_0_0RCTConvert NSString:family] ?: familyName;
  isItalic = style ? [ABI48_0_0RCTConvert ABI48_0_0RCTFontStyle:style] : isItalic;
  fontWeight = weight ? [ABI48_0_0RCTConvert ABI48_0_0RCTFontWeight:weight] : fontWeight;

  BOOL didFindFont = NO;

  // Handle system font as special case. This ensures that we preserve
  // the specific metrics of the standard system font as closely as possible.
  if ([familyName isEqual:defaultFontFamily] || [familyName isEqualToString:@"System"]) {
    font = cachedSystemFont(fontSize, fontWeight);
    if (font) {
      didFindFont = YES;

      if (isItalic || isCondensed) {
        UIFontDescriptor *fontDescriptor = [font fontDescriptor];
        UIFontDescriptorSymbolicTraits symbolicTraits = fontDescriptor.symbolicTraits;
        if (isItalic) {
          symbolicTraits |= UIFontDescriptorTraitItalic;
        }
        if (isCondensed) {
          symbolicTraits |= UIFontDescriptorTraitCondensed;
        }
        fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:symbolicTraits];
        font = [UIFont fontWithDescriptor:fontDescriptor size:fontSize];
      }
    }
  }

  // Gracefully handle being given a font name rather than font family, for
  // example: "Helvetica Light Oblique" rather than just "Helvetica".
  if (!didFindFont && fontNamesForFamilyName(familyName).count == 0) {
    font = [UIFont fontWithName:familyName size:fontSize];
    if (font) {
      // It's actually a font name, not a font family name,
      // but we'll do what was meant, not what was said.
      familyName = font.familyName;
      fontWeight = weight ? fontWeight : weightOfFont(font);
      isItalic = style ? isItalic : isItalicFont(font);
      isCondensed = isCondensedFont(font);
    } else {
      // Not a valid font or family
      ABI48_0_0RCTLogError(@"Unrecognized font family '%@'", familyName);
      if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)]) {
        font = [UIFont systemFontOfSize:fontSize weight:fontWeight];
      } else if (fontWeight > UIFontWeightRegular) {
        font = [UIFont boldSystemFontOfSize:fontSize];
      } else {
        font = [UIFont systemFontOfSize:fontSize];
      }
    }
  }

  NSArray<NSString *> *names = fontNamesForFamilyName(familyName);
  if (!didFindFont) {
    // Get the closest font that matches the given weight for the fontFamily
    CGFloat closestWeight = INFINITY;
    for (NSString *name in names) {
      UIFont *match = [UIFont fontWithName:name size:fontSize];
      if (isItalic == isItalicFont(match) && isCondensed == isCondensedFont(match)) {
        CGFloat testWeight = weightOfFont(match);
        if (ABS(testWeight - fontWeight) < ABS(closestWeight - fontWeight)) {
          font = match;
          closestWeight = testWeight;
        }
      }
    }
  }

  // If we still don't have a match at least return the first font in the fontFamily
  // This is to support built-in font Zapfino and other custom single font families like Impact
  if (!font && names.count > 0) {
    font = [UIFont fontWithName:names[0] size:fontSize];
  }

  // Apply font variants to font object
  if (variant) {
    NSArray *fontFeatures = [ABI48_0_0RCTConvert ABI48_0_0RCTFontVariantDescriptorArray:variant];
    UIFontDescriptor *fontDescriptor = [font.fontDescriptor
        fontDescriptorByAddingAttributes:@{UIFontDescriptorFeatureSettingsAttribute : fontFeatures}];
    font = [UIFont fontWithDescriptor:fontDescriptor size:fontSize];
  }

  return font;
}

+ (UIFont *)updateFont:(UIFont *)font withFamily:(NSString *)family
{
  return [self updateFont:font withFamily:family size:nil weight:nil style:nil variant:nil scaleMultiplier:1];
}

+ (UIFont *)updateFont:(UIFont *)font withSize:(NSNumber *)size
{
  return [self updateFont:font withFamily:nil size:size weight:nil style:nil variant:nil scaleMultiplier:1];
}

+ (UIFont *)updateFont:(UIFont *)font withWeight:(NSString *)weight
{
  return [self updateFont:font withFamily:nil size:nil weight:weight style:nil variant:nil scaleMultiplier:1];
}

+ (UIFont *)updateFont:(UIFont *)font withStyle:(NSString *)style
{
  return [self updateFont:font withFamily:nil size:nil weight:nil style:style variant:nil scaleMultiplier:1];
}

@end
