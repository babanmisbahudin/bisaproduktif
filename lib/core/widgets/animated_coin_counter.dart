import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedCoinCounter extends StatefulWidget {
  final int coins;
  final TextStyle? style;

  const AnimatedCoinCounter({
    super.key,
    required this.coins,
    this.style,
  });

  @override
  State<AnimatedCoinCounter> createState() => _AnimatedCoinCounterState();
}

class _AnimatedCoinCounterState extends State<AnimatedCoinCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousCoins = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.coins.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCoinCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coins != widget.coins) {
      _previousCoins = oldWidget.coins;
      _animation = Tween<double>(
        begin: _previousCoins.toDouble(),
        end: widget.coins.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatCoins(double value) {
    final intVal = value.toInt();
    if (intVal >= 1000000) {
      return '${(intVal / 1000000).toStringAsFixed(1)}M';
    }
    final s = intVal.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write(',');
      result.write(s[i]);
    }
    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Text(
          _formatCoins(_animation.value),
          style: widget.style ??
              GoogleFonts.poppins(
                fontSize: 52,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
        );
      },
    );
  }
}
