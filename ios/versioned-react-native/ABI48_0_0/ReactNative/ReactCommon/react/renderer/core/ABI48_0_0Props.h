/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#pragma once

#include <folly/dynamic.h>

#include <ABI48_0_0React/ABI48_0_0renderer/core/PropsMacros.h>
#include <ABI48_0_0React/ABI48_0_0renderer/core/PropsParserContext.h>
#include <ABI48_0_0React/ABI48_0_0renderer/core/RawProps.h>
#include <ABI48_0_0React/ABI48_0_0renderer/core/ABI48_0_0ReactPrimitives.h>
#include <ABI48_0_0React/ABI48_0_0renderer/core/Sealable.h>
#include <ABI48_0_0React/ABI48_0_0renderer/debug/DebugStringConvertible.h>

#ifdef ANDROID
#include <ABI48_0_0React/ABI48_0_0renderer/mapbuffer/MapBufferBuilder.h>
#endif

namespace ABI48_0_0facebook {
namespace ABI48_0_0React {

/*
 * Represents the most generic props object.
 */
class Props : public virtual Sealable, public virtual DebugStringConvertible {
 public:
  using Shared = std::shared_ptr<Props const>;

  Props() = default;
  Props(
      const PropsParserContext &context,
      const Props &sourceProps,
      RawProps const &rawProps,
      bool shouldSetRawProps = true);
  virtual ~Props() = default;

  /**
   * Set a prop value via iteration (see enableIterator above).
   * If setProp is defined for a particular props struct, it /must/
   * be called every time setProp is called on the hierarchy.
   * For example, ViewProps overrides setProp and so ViewProps must
   * explicitly call Props::setProp every time ViewProps::setProp is
   * called. This is because a single prop from JS can be reused
   * multiple times for different values in the hierarchy. For example, if
   * ViewProps uses "propX", Props may also use "propX".
   */
  void setProp(
      const PropsParserContext &context,
      RawPropsPropNameHash hash,
      const char *propName,
      RawValue const &value);

  std::string nativeId;

#ifdef ANDROID
  folly::dynamic rawProps = folly::dynamic::object();

  virtual void propsDiffMapBuffer(
      Props const *oldProps,
      MapBufferBuilder &builder) const;
#endif
};

} // namespace ABI48_0_0React
} // namespace ABI48_0_0facebook
