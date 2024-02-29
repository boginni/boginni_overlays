import 'package:flutter/material.dart';

import '../wigets/overlay_entry_widget.dart';

OverlayEntry? _overlayEntry;

void _closeOverlay() {
  _overlayEntry?.remove();
  _overlayEntry = null;
}

void showOverlay(
  BuildContext context, {
  required GlobalKey key,
  bool opaque = false,
  required Widget Function(BuildContext context, VoidCallback close) builder,
  double? width,
  double? height,
}) {
  _overlayEntry = OverlayEntry(
    opaque: opaque,
    builder: (context) => OverlayEntryWidget(
      widgetKey: key,
      width: width,
      height: height,
      builder: (context) {
        return builder(context, _closeOverlay);
      },
      close: _closeOverlay,
    ),
  );

  Overlay.of(context).insert(_overlayEntry!);
}
