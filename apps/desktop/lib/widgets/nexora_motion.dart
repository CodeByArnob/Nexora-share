import 'package:flutter/material.dart';
import '../theme/nexora_theme.dart';

/// 1. Lightweight, GPU-friendly discovery radar pulse ring.
/// Respects reduced-motion accessibility settings.
class NexoraPulseRing extends StatefulWidget {
  final Widget child;
  final bool isScanning;

  const NexoraPulseRing({
    super.key,
    required this.child,
    this.isScanning = true,
  });

  @override
  State<NexoraPulseRing> createState() => _NexoraPulseRingState();
}

class _NexoraPulseRingState extends State<NexoraPulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.45,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _opacityAnimation = Tween<double>(
      begin: 0.35,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.isScanning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant NexoraPulseRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isScanning && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations || !widget.isScanning) {
      return widget.child;
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: NexoraColors.electricBlue.withValues(
                        alpha: _opacityAnimation.value,
                      ),
                      width: 2.5,
                    ),
                  ),
                ),
              ),
              widget.child,
            ],
          );
        },
      ),
    );
  }
}

/// 2. Fluid animated transfer progress bar with speed badge.
class NexoraAnimatedProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String speedText;

  const NexoraAnimatedProgressBar({
    super.key,
    required this.progress,
    this.speedText = '',
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(clamped * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: NexoraColors.electricBlue,
              ),
            ),
            if (speedText.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: NexoraColors.signalTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  speedText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: NexoraColors.signalTeal,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 10,
            width: double.infinity,
            color: Colors.grey.withValues(alpha: 0.2),
            child: disableAnimations
                ? FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: clamped,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            NexoraColors.electricBlue,
                            NexoraColors.signalTeal,
                          ],
                        ),
                      ),
                    ),
                  )
                : TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: clamped),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                NexoraColors.electricBlue,
                                NexoraColors.signalTeal,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

/// 3. Subtle animated success badge on transfer completion.
class NexoraSuccessBadge extends StatefulWidget {
  final double size;

  const NexoraSuccessBadge({super.key, this.size = 28});

  @override
  State<NexoraSuccessBadge> createState() => _NexoraSuccessBadgeState();
}

class _NexoraSuccessBadgeState extends State<NexoraSuccessBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          color: NexoraColors.signalTeal,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, size: widget.size * 0.65, color: Colors.white),
      );
    }

    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          color: NexoraColors.signalTeal,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, size: widget.size * 0.65, color: Colors.white),
      ),
    );
  }
}
