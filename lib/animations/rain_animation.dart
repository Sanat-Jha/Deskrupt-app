

import 'dart:math';

import 'package:flutter/material.dart';

class RainBackgroundWidget extends StatefulWidget {
  final Widget child;
  final Widget imageWidget;

  const RainBackgroundWidget({
    Key? key,
    required this.child,
    required this.imageWidget,
  }) : super(key: key);

  @override
  _RainBackgroundWidgetState createState() => _RainBackgroundWidgetState();
}

class _RainBackgroundWidgetState extends State<RainBackgroundWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<RainDrop> _raindrops = [];
  final int _numDrops = 100;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();

    // Initialize raindrops with random positions and velocities
    for (int i = 0; i < _numDrops; i++) {
      _raindrops.add(RainDrop.random());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Stack(
    children: [
      Positioned.fill(
        child: 
          widget.imageWidget,
      ),
      Positioned.fill(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: RainPainter(_raindrops),
            );
          },
        ),
      ),
      Center(child: widget.child),
    ],
  );
}

}

class RainDrop {
  double x;
  double y;
  double speed;
  double length;

  RainDrop({
    required this.x,
    required this.y,
    required this.speed,
    required this.length,
  });

  // Generate a random raindrop
  factory RainDrop.random() {
    final random = Random();
    return RainDrop(
      x: random.nextDouble() * 1500, // Adjust for your screen size
      y: random.nextDouble() * 20, // Adjust for your screen size
      speed: random.nextDouble() * 3 + 2, // Rain speed
      length: random.nextDouble() * 20 + 10, // Rain length
    );
  }

  void fall() {
    y += speed;
    if (y > 600) { // Reset if off-screen (adjust for your screen size)
      y = -length;
    }
  }
}

class RainPainter extends CustomPainter {
  final List<RainDrop> raindrops;
  RainPainter(this.raindrops);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2.0;

    for (final drop in raindrops) {
      canvas.drawLine(
        Offset(drop.x, drop.y),
        Offset(drop.x, drop.y + drop.length),
        paint,
      );
      drop.fall();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}