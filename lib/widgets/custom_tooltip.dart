import 'package:flutter/material.dart';

enum TooltipDirection {
  up,
  down,
}

class CustomTooltip extends StatelessWidget {
  final Widget child;
  final String message;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final double verticalOffset;
  final Duration? showDuration;
  final Duration? waitDuration;
  final TooltipDirection tooltipDirection;
  final double? triangleOffset;

  const CustomTooltip({
    Key? key,
    required this.child,
    required this.message,
    this.backgroundColor,
    this.textStyle,
    this.verticalOffset = 20,
    this.showDuration,
    this.waitDuration,
    this.tooltipDirection = TooltipDirection.up,
    this.triangleOffset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tooltipKey = GlobalKey<TooltipState>();
    return GestureDetector(
      onTap: () {
        tooltipKey.currentState?.ensureTooltipVisible();
      },
      child: Tooltip(
        key: tooltipKey,
        message: message,
        decoration: ShapeDecoration(
          color: backgroundColor ??
              (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.grey[800]),
          shape: TooltipShapeBorder(
            arrowArc: 0.0,
            direction: tooltipDirection,
            triangleOffset: triangleOffset,
          ),
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        textStyle: textStyle ??
            TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              fontSize: 14,
            ),
        preferBelow: tooltipDirection == TooltipDirection.down,
        verticalOffset: verticalOffset,
        showDuration: showDuration ?? const Duration(seconds: 2),
        waitDuration: waitDuration ?? const Duration(milliseconds: 0),
        child: child,
      ),
    );
  }
}

class TooltipShapeBorder extends ShapeBorder {
  final double arrowWidth;
  final double arrowHeight;
  final double arrowArc;
  final double radius;
  final TooltipDirection direction;
  final double? triangleOffset;

  const TooltipShapeBorder({
    this.arrowWidth = 20.0,
    this.arrowHeight = 10.0,
    this.arrowArc = 0.0,
    this.radius = 8.0,
    this.direction = TooltipDirection.up,
    this.triangleOffset,
  }) : assert(arrowArc <= 1.0 && arrowArc >= 0.0);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.only(
      bottom: direction == TooltipDirection.up ? arrowHeight : 0,
      top: direction == TooltipDirection.down ? arrowHeight : 0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    if (direction == TooltipDirection.up) {
      rect = Rect.fromPoints(
          rect.topLeft, rect.bottomRight - Offset(0, arrowHeight));

      double arrowX = triangleOffset ?? rect.width / 2;
      double y = rect.height;

      return Path()
        ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)))
        ..moveTo(arrowX - (arrowWidth / 2), y)
        ..lineTo(arrowX, y + arrowHeight)
        ..lineTo(arrowX + (arrowWidth / 2), y)
        ..close();
    } else {
      rect = Rect.fromPoints(
          rect.topLeft + Offset(0, arrowHeight), rect.bottomRight);

      double arrowX = triangleOffset ?? rect.width / 2;

      return Path()
        ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)))
        ..moveTo(arrowX - (arrowWidth / 2), arrowHeight)
        ..lineTo(arrowX, 0)
        ..lineTo(arrowX + (arrowWidth / 2), arrowHeight)
        ..close();
    }
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

final GlobalKey _toolTipKey = GlobalKey();
