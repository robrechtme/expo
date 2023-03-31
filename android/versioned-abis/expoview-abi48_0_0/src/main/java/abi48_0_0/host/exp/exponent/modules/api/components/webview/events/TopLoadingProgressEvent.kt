package abi48_0_0.host.exp.exponent.modules.api.components.webview.events

import abi48_0_0.com.facebook.react.bridge.WritableMap
import abi48_0_0.com.facebook.react.uimanager.events.Event
import abi48_0_0.com.facebook.react.uimanager.events.RCTEventEmitter

/**
 * Event emitted when there is a loading progress event.
 */
class TopLoadingProgressEvent(viewId: Int, private val mEventData: WritableMap) :
  Event<TopLoadingProgressEvent>(viewId) {
  companion object {
    const val EVENT_NAME = "topLoadingProgress"
  }

  override fun getEventName(): String = EVENT_NAME

  override fun canCoalesce(): Boolean = false

  override fun getCoalescingKey(): Short = 0

  override fun dispatch(rctEventEmitter: RCTEventEmitter) =
    rctEventEmitter.receiveEvent(viewTag, eventName, mEventData)
}
