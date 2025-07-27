import 'package:flutter/material.dart';

class StatusDots extends StatelessWidget {
  final Color color;
  final Animation<double> animation;
  final int count;
  final double size;
  final double blurRadius;
  final double spreadRadius;
  final EdgeInsetsGeometry? margin;

  const StatusDots({
    super.key,
    required this.color,
    required this.animation,
    this.count = 3,
    this.size = 8.0,
    this.blurRadius = 30.0,
    this.spreadRadius = 2.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (i) => Container(
          width: size,
          height: size,
          margin: margin ?? (i < count - 1 ? const EdgeInsets.only(right: 4) : null),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: animation.value * 0.8),
                blurRadius: blurRadius,
                spreadRadius: spreadRadius,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
