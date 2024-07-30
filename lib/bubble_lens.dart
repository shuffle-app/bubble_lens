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

  final bool fadeEdge;
  final double itemMaxScale;
  final double verticalStepCoefficient;

  BubbleLens({
    Key? key,
    required this.width,
    required this.height,
    required this.widgets,
    this.fadeEdge = true,
    this.itemSize = 120,
    this.paddingX = 0,
    this.paddingY = 0,
    this.itemMaxScale = .99,
    this.verticalStepCoefficient = 1.3,
    this.duration = const Duration(milliseconds: 30),
  }) : super(key: key);

  @override
  BubbleLensState createState() => BubbleLensState();
}

class BubbleLensState extends State<BubbleLens> {
  static const _scaleFactor = .25;
  late Duration moveDuration;
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
    moveDuration = widget.duration;
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
      [-widget.itemSize / 1.05 + -widget.paddingX, 0],
      [
        -(widget.itemSize / 2) + -(widget.paddingX / 2),
        widget.itemSize / widget.verticalStepCoefficient + widget.paddingY
      ],
      [
        (widget.itemSize / 2) + (widget.paddingX / 2),
        widget.itemSize / widget.verticalStepCoefficient + widget.paddingY
      ],
      [widget.itemSize / 1.05 + widget.paddingX, 0],
      [
        (widget.itemSize / 2) + (widget.paddingX / 2),
        -widget.itemSize / widget.verticalStepCoefficient + -widget.paddingY
      ],
    ];
  }

  _recurciveInertion(double x, double y, int iteration) {
    if (iteration > 38) {
      iteration = 38;
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (_offsetX.abs() > widget.width || _offsetY.abs() > widget.height) {
        return;
      }
      setState(() {
        _offsetX += x * pow(0.9, iteration);
        _offsetY += y * pow(0.9, iteration);
      });
      if (iteration > 0) {
        _recurciveInertion(x, y, iteration - 1);
      }
    });
  }

  @override
  void didUpdateWidget(covariant BubbleLens oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.widgets.length != oldWidget.widgets.length) {
      _offsetX = _middleX - widget.itemSize / 2;
      _offsetY = _middleY - widget.itemSize / 2;
    }
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
          double newOffsetX = max(_minLeft, min(_maxLeft, _offsetX + details.delta.dx));
          double newOffsetY = max(_minTop, min(_maxTop, _offsetY + details.delta.dy));
          if (newOffsetX != _offsetX || newOffsetY != _offsetY) {
            setState(() {
              if (moveDuration != widget.duration) {
                moveDuration = widget.duration;
              }
              _offsetX = newOffsetX;
              _offsetY = newOffsetY;
            });
          }
        },
        onPanEnd: (details) {
          final double deltaVelocityX =
              details.velocity.pixelsPerSecond.dx / widget.itemSize / (widget.widgets.length / 2);
          final double deltaVelocityY =
              details.velocity.pixelsPerSecond.dy / widget.itemSize / (widget.widgets.length / 2);

          // print('onPanEnd: deltaVelocityX: $deltaVelocityX deltaVelocityY $deltaVelocityY');

          setState(() {
            moveDuration = Duration(milliseconds: 300);
          });
          _recurciveInertion(deltaVelocityX, deltaVelocityY, 38);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: widget.widgets.map((item) {
            int index = widget.widgets.indexOf(item);
            late double left;
            late double top;
            if (index == 0) {
              left = _offsetX;
              top = _offsetY;
            } else if (index - 1 == _total) {
              left = (_counter + 1) * (widget.itemSize + widget.paddingX) + _offsetX;
              top = _offsetY;
              _lastTotal = _total;
              _counter++;
              _total += _counter * 6;
            } else {
              List step = _steps[((index - _lastTotal - 2) / _counter % _steps.length).floor()];
              left = _lastX + step[0];
              top = _lastY + step[1];
            }
            _minLeft = min(_minLeft, -(left - _offsetX) + _middleX - (widget.itemSize / 2.2));
            _maxLeft = max(_maxLeft, left - _offsetX + _middleX - (widget.itemSize / 2.2));
            _minTop = min(_minTop, -(top - _offsetY) + _middleY - (widget.itemSize / 2.2));
            _maxTop = max(_maxTop, top - _offsetY + _middleY - (widget.itemSize / 2.2));
            _lastX = left;
            _lastY = top;
            final double distance =
                sqrt(pow(_middleX - (left + widget.itemSize / 2), 2) + pow(_middleY - (top + widget.itemSize / 2), 2));
            final double distPercent = distance / (longerSide / 1.9);

            if (distance > widget.itemSize * 1.7) {
              if (top < _middleY) {
                top += widget.itemSize / 4;
              } else {
                top -= widget.itemSize / 4;
              }

              if (left < _middleX) {
                left += widget.itemSize / 4;
              } else {
                left -= widget.itemSize / 4;
              }
              // moveDuration = Duration(microseconds: widget.duration.inMilliseconds * 10);
            }

            double scale = _scaleFactor * log(distPercent * -1 + 0.73) + widget.itemMaxScale;
            scale = max(_scaleFactor, min(1, (scale)));
            if (scale.toString() == double.nan.toString()) scale = _scaleFactor;
            final double fadePercent = distPercent * .7;
            final double fadeValue = .7;

            return AnimatedPositioned(
              duration: moveDuration,
              curve: moveDuration == widget.duration ? Curves.linear : Curves.easeOutCirc,
              // curve: Curves.linear,
              // curve: Curves.linearToEaseOut,
              top: top,
              left: left,
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                    opacity: (widget.fadeEdge && fadePercent > fadeValue)
                        ? max(0, min(1, 1 - (fadePercent - fadeValue) / (1 - fadeValue)))
                        : 1,
                    child: SizedBox(
                      width: widget.itemSize,
                      height: widget.itemSize,
                      child: item,
                    )),
              ),
            );
          }).toList(),
        ),
      ),
    );

    return bubbles;
  }
}
