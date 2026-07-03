import 'dart:math';
import 'package:flutter/material.dart';

class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final double width;
  final double height;

  const FlipCard({
    Key? key,
    required this.front,
    required this.back,
    this.width = double.infinity,
    this.height = 350,
  }) : super(key: key);

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutBack, // Gives a slight, premium elastic bounce at the end of the flip
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final angle = _animation.value;
            
            // Build 3D rotation transform matrix with perspective
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // Depth perspective value
              ..rotateY(angle);

            final showBack = angle >= pi / 2;

            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: showBack
                  ? Transform(
                      // Counter-rotate the back side so contents are readable (not mirrored)
                      transform: Matrix4.identity()..rotateY(pi),
                      alignment: Alignment.center,
                      child: widget.back,
                    )
                  : widget.front,
            );
          },
        ),
      ),
    );
  }
}
