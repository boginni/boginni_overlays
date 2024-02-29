import 'dart:async';
import 'package:flutter/material.dart';

class OverlayEntryWidget extends StatefulWidget {
  const OverlayEntryWidget({
    required this.widgetKey,
    required this.builder,
    required this.close,
    super.key,
    this.width,
    this.height,
  });

  final GlobalKey widgetKey;
  final WidgetBuilder builder;
  final double? width;
  final double? height;
  final VoidCallback close;

  @override
  State<OverlayEntryWidget> createState() => _OverlayEntryWidgetState();
}

class _OverlayEntryWidgetState extends State<OverlayEntryWidget> {
  Timer? _positionCheckTimer;
  Offset? _lastPosition;

  @override
  void initState() {
    super.initState();
    _startPositionCheck();
  }

  void _startPositionCheck() {
    _positionCheckTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      // 60fps
      _checkPosition();
    });
  }

  void _checkPosition() {
    final RenderBox? renderBox = widget.widgetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final Offset newPosition = renderBox.localToGlobal(Offset.zero);
      if (_lastPosition == null || _lastPosition != newPosition) {
        setState(() {
          _lastPosition = newPosition;
        });
      }
    }
  }

  @override
  void dispose() {
    _positionCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RenderBox renderBox = widget.widgetKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    // check if the overlay is going to be out of the screen
    double left = offset.dx;
    double width = widget.width ?? size.width;
    if (width < size.width) {
      width = size.width;
    }

    if (offset.dx + width > MediaQuery.of(context).size.width) {
      left = offset.dx - width + size.width;
    }

    Widget child = Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {},
        behavior: HitTestBehavior.opaque,
        child: widget.builder(context),
      ),
    );

    final screenHeight = MediaQuery.of(context).size.height;
    final higherThanHalf = (offset.dy + size.height) > screenHeight / 2;

    if (higherThanHalf) {
      child = Positioned(
        left: left,
        bottom: screenHeight - offset.dy,
        width: width,
        child: child,
      );
    } else {
      child = Positioned(
        left: left,
        top: offset.dy + size.height,
        width: width,
        child: child,
      );
    }

    return GestureDetector(
      onTap: widget.close,
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: [
            child,
          ],
        ),
      ),
    );
  }
}
