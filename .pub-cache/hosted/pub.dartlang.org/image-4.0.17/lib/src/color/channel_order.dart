/// Ordering of the channels in a pixel, used with Image.fromBytes and
/// Image.getBytes to support alternative channel ordering.
enum ChannelOrder {
  rgba,
  bgra,
  abgr,
  argb,
  rgb,
  bgr,
  grayAlpha,
  red,
}

/// The number of channels for each ChannelOrder.
const channelOrderLength = <ChannelOrder, int>{
  ChannelOrder.rgba: 4,
  ChannelOrder.bgra: 4,
  ChannelOrder.abgr: 4,
  ChannelOrder.argb: 4,
  ChannelOrder.rgb: 3,
  ChannelOrder.bgr: 3,
  ChannelOrder.grayAlpha: 2,
  ChannelOrder.red: 1
};
