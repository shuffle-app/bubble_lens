import 'package:flutter/material.dart';
import 'dart:math';

class BubbleLens extends StatefulWidget {
  final double width;
  final double height;
  final List<Widget> widgets;
  final double itemSize;
  final double paddingX;
  final double paddingY;
  final Duration duration;

  // final Radius radius;
  final bool fadeEdge;
  final double itemMaxScale;
  final double verticalStepCoefficient;

  BubbleLens({
    Key? key,
    required this.width,
    required this.height,
    required this.widgets,
    this.fadeEdge = true,
    this.itemSize = 100,
    this.paddingX = 10,
    this.paddingY = 0,
    this.itemMaxScale = .99,
    this.verticalStepCoefficient = 1.3,
    this.duration = const Duration(milliseconds: 100),
    // this.radius = const Radius.circular(999),
  }) : super(key: key);

  @override
  BubbleLensState createState() => BubbleLensState();
}

class BubbleLensState extends State<BubbleLens> {
  static const _scaleFactor = .2;
  double _middleX = 0;
  double _middleY = 0;
  double _offsetX = 0;
  double _offsetY = 0;
  double _lastX = 0;
  double _lastY = 0;
  List _steps = [];
  int _counter = 0;
  int _total = 0;
  int _lastTotal = 0;

  double _minLeft = double.infinity;
  double _maxLeft = double.negativeInfinity;
  double _minTop = double.infinity;
  double _maxTop = double.negativeInfinity;

  double get longerSide => max(widget.width, widget.height);

  late final step;

  @override
  void initState() {
    super.initState();
    step = widget.itemSize / 2;
    _middleX = widget.width / 2;
    _middleY = widget.height / 2;
    _offsetX = _middleX - widget.itemSize / 2;
    _offsetY = _middleY - widget.itemSize / 2;
    _lastX = 0;
    _lastY = 0;
    _steps = [
      [
        -(widget.itemSize / 2) + -(widget.paddingX / 2),
        -widget.itemSize / widget.verticalStepCoefficient + -widget.paddingY
      ],
      [-widget.itemSize + -widget.paddingX, 0],
      [
        -(widget.itemSize / 2) + -(widget.paddingX / 2),
        widget.itemSize / widget.verticalStepCoefficient + widget.paddingY
      ],
      [
        (widget.itemSize / 2) + (widget.paddingX / 2),
        widget.itemSize / widget.verticalStepCoefficient + widget.paddingY
      ],
      [widget.itemSize + widget.paddingX, 0],
      [
        (widget.itemSize / 2) + (widget.paddingX / 2),
        -widget.itemSize / widget.verticalStepCoefficient + -widget.paddingY
      ],
    ];
  }

  // _findOffsetToCenter() {
  //   double dx = _offsetX;
  //   double dy = _offsetY;
  //   if (dx > _middleX) {
  //     while (dx > _middleX) {
  //       dx -= step;
  //     }
  //   } else if (dx < _middleX) {
  //     while (dx < _middleX) {
  //       dx += step;
  //     }
  //   }
  //   if (dy > _middleY) {
  //     while (dy > _middleY) {
  //       dy -= step;
  //     }
  //   } else if (dy < _middleY) {
  //     while (dy < _middleY) {
  //       dy += step;
  //     }
  //   }
  //   return Offset(dx, dy);
  // }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _counter = 0;
    _total = 0;
    Widget bubbles = SizedBox(
      width: widget.width,
      height: widget.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          double newOffsetX =
              max(_minLeft, min(_maxLeft, _offsetX + details.delta.dx));
          double newOffsetY =
              max(_minTop, min(_maxTop, _offsetY + details.delta.dy));
          if (newOffsetX != _offsetX || newOffsetY != _offsetY) {
            setState(() {
              _offsetX = newOffsetX;
              _offsetY = newOffsetY;
            });
          }
        },
        onPanEnd: (details) {
          final double deltaVelocityX = details.velocity.pixelsPerSecond.dx / widget.itemSize;
          final double deltaVelocityY = details.velocity.pixelsPerSecond.dy / widget.itemSize;

            setState(() {
              _offsetX += (_offsetX + (deltaVelocityX *details.velocity.pixelsPerSecond.distanceSquared))%step;
              _offsetY += (_offsetY+(deltaVelocityY*details.velocity.pixelsPerSecond.distanceSquared))%step;
            });
        },
        child: Stack(
            children: widget.widgets.map((item) {
          int index = widget.widgets.indexOf(item);
          late final double left;
          late final double top;
          if (index == 0) {
            left = _offsetX;
            top = _offsetY;
          } else if (index - 1 == _total) {
            left =
                (_counter + 1) * (widget.itemSize + widget.paddingX) + _offsetX;
            top = _offsetY;
            _lastTotal = _total;
            _counter++;
            _total += _counter * 6;
          } else {
            List step = _steps[
                ((index - _lastTotal - 2) / _counter % _steps.length).floor()];
            left = _lastX + step[0];
            top = _lastY + step[1];
          }
          _minLeft = min(
              _minLeft, -(left - _offsetX) + _middleX - (widget.itemSize / 2.2));
          _maxLeft =
              max(_maxLeft, left - _offsetX + _middleX - (widget.itemSize / 2.2));
          _minTop = min(
              _minTop, -(top - _offsetY) + _middleY - (widget.itemSize / 2.2));
          _maxTop =
              max(_maxTop, top - _offsetY + _middleY - (widget.itemSize / 2.2));
          _lastX = left;
          _lastY = top;
          final double distance = sqrt(
              pow(_middleX - (left + widget.itemSize / 2), 2) +
                  pow(_middleY - (top + widget.itemSize / 2), 2));
          final double distPercent = distance / (longerSide / 2);

          double scale = _scaleFactor * log(distPercent * -1 +0.8) + widget.itemMaxScale;
          scale = max(_scaleFactor, min(1, (scale)));
          if (scale.toString() == double.nan.toString()) scale = _scaleFactor;

          // double originX = min(
          //     widget.itemSize * 1,
          //     max(widget.itemSize * -1, left - _middleX)) / -2;
          // double originY = min(
          //     widget.itemSize * 1,
          //     max(widget.itemSize * -1, top - _middleY)) / -2;

          final double fadePercent = distPercent * .7;
          final double fadeValue = .7;
          return AnimatedPositioned(
              duration: widget.duration,
              curve: Curves.linearToEaseOut,
              top: top,
              left: left,
              child: AnimatedScale(
                  scale: scale,
                  curve: Curves.decelerate,
                  filterQuality: FilterQuality.medium,
                  duration: widget.duration,
                  // origin: Offset(originX, originY),
                  // child: ClipRRect(
                  //   borderRadius: BorderRadius.all(widget.radius),
                  child: Opacity(
                    opacity: (widget.fadeEdge && fadePercent > fadeValue)
                        ? max(
                            0,
                            min(
                                1,
                                1 -
                                    (fadePercent - fadeValue) /
                                        (1 - fadeValue)))
                        : 1,
                    child: SizedBox(
                      width: widget.itemSize,
                      height: widget.itemSize,
                      child: item,
                    ),
                    // ),
                  )));
        }).toList()),
      ),
    );

    return bubbles;
  }
}
