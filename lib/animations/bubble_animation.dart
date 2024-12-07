import 'dart:math';
import 'package:flutter/material.dart';

class BubbleBackgroundContainer extends StatefulWidget {
  final Widget child;
  final Widget backgroundImageWidget;

  const BubbleBackgroundContainer({
    Key? key,
    required this.child,
    required this.backgroundImageWidget,
  }) : super(key: key);

  @override
  State<BubbleBackgroundContainer> createState() =>
      _BubbleBackgroundContainerState();
}

class _BubbleBackgroundContainerState extends State<BubbleBackgroundContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _bubbles = List.generate(10, (index) => _Bubble(size: 40 + index * 10));
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
        // Background image
        Positioned.fill(
          child: widget.backgroundImageWidget,
        ),
        // Moving bubbles
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            for (var bubble in _bubbles) {
              bubble.updatePosition(MediaQuery.of(context).size, _bubbles);
            }

            return Stack(
              children: _bubbles
                  .map(
                    (bubble) => Positioned(
                      left: bubble.position.dx,
                      top: bubble.position.dy,
                      child: Image.asset(
                        'assets/img/water-bubble.png',
                        width: bubble.size,
                        height: bubble.size,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        // Child widget
        Positioned.fill(
          child: widget.child,
        ),
      ],
    );
  }
}

class _Bubble {
  final double size;
  Offset position;
  Offset velocity;

  _Bubble({required this.size})
      : position = Offset(
          Random().nextDouble() * 300,
          Random().nextDouble() * 600,
        ),
        velocity = Offset(
          (Random().nextDouble() - 0.5) ,
          (Random().nextDouble() - 0.5) ,
        );

  void updatePosition(Size screenSize, List<_Bubble> allBubbles) {
    // Update position
    position = Offset(position.dx + velocity.dx, position.dy + velocity.dy);

    // Bounce off walls
    if (position.dx <= 0 || position.dx + size >= screenSize.width) {
      velocity = Offset(-velocity.dx, velocity.dy);
    }
    if (position.dy <= 0 || position.dy + size >= screenSize.height) {
      velocity = Offset(velocity.dx, -velocity.dy);
    }

    // Check for collisions with other bubbles
    for (var other in allBubbles) {
      if (other == this) continue;

      final dx = other.position.dx - position.dx;
      final dy = other.position.dy - position.dy;
      final distance = sqrt(dx * dx + dy * dy);

      if (distance < size / 2 + other.size / 2) {
        final angle = atan2(dy, dx);
        final targetX = position.dx + cos(angle) * (size / 2 + other.size / 2);
        final targetY = position.dy + sin(angle) * (size / 2 + other.size / 2);

        final ax = (targetX - other.position.dx) * 0.01;
        final ay = (targetY - other.position.dy) * 0.01;

        velocity = Offset(velocity.dx - ax, velocity.dy - ay);
        other.velocity = Offset(other.velocity.dx + ax, other.velocity.dy + ay);
      }
    }
  }
}
