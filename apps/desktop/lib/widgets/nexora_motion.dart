import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/nexora_theme.dart';

/// 1. Lightweight, GPU-friendly discovery radar pulse ring.
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: NexoraColors.signalTeal.withValues(
                        alpha: _opacityAnimation.value,
                      ),
                      width: 2.0,
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
                        gradient: NexoraColors.brandGradient,
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
                            gradient: NexoraColors.brandGradient,
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
      duration: const Duration(milliseconds: 500),
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
        decoration: BoxDecoration(
          gradient: NexoraColors.brandGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: NexoraColors.signalTeal.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(Icons.check, size: widget.size * 0.65, color: Colors.white),
      ),
    );
  }
}

/// 4. Large Glowing Circular Progress Indicator with fluid animation.
class NexoraGlowingCircularProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final String? centerLabel;
  final String? subLabel;

  const NexoraGlowingCircularProgress({
    super.key,
    required this.progress,
    this.size = 180,
    this.centerLabel,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: RepaintBoundary(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient outer glow
              Container(
                width: size * 0.88,
                height: size * 0.88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: NexoraColors.electricBlue.withValues(
                        alpha: isDark ? 0.25 : 0.15,
                      ),
                      blurRadius: 36,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),

              // Background track
              CustomPaint(
                size: Size(size, size),
                painter: _CircularTrackPainter(
                  trackColor: isDark
                      ? const Color(0xFF1E2D4A)
                      : const Color(0xFFE2E8F0),
                  strokeWidth: 12,
                ),
              ),

              // Animated progress arc
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: clamped),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return CustomPaint(
                    size: Size(size, size),
                    painter: _CircularProgressPainter(
                      progress: value,
                      strokeWidth: 12,
                      gradient: NexoraColors.brandGradient,
                    ),
                  );
                },
              ),

              // Center text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerLabel ?? '${(clamped * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (subLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subLabel!,
                      style: TextStyle(
                        fontSize: size * 0.08,
                        fontWeight: FontWeight.w600,
                        color: NexoraColors.signalTeal,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularTrackPainter extends CustomPainter {
  final Color trackColor;
  final double strokeWidth;

  _CircularTrackPainter({required this.trackColor, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _CircularTrackPainter oldDelegate) =>
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Gradient gradient;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final sweepAngle = 2 * math.pi * progress;
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Start at 12 o'clock (-pi / 2)
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 5. Animated Scanning Laser for QR Scanner Screen.
class NexoraAnimatedLaserScanner extends StatefulWidget {
  final double width;
  final double height;

  const NexoraAnimatedLaserScanner({
    super.key,
    this.width = 260,
    this.height = 260,
  });

  @override
  State<NexoraAnimatedLaserScanner> createState() =>
      _NexoraAnimatedLaserScannerState();
}

class _NexoraAnimatedLaserScannerState extends State<NexoraAnimatedLaserScanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _laserPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _laserPosition = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          // Corner brackets
          CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _CornerBracketPainter(),
          ),

          // Sweeping Laser Beam
          AnimatedBuilder(
            animation: _laserPosition,
            builder: (context, _) {
              final top = _laserPosition.value * (widget.height - 4);
              return Positioned(
                top: top,
                left: 12,
                right: 12,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        NexoraColors.signalTeal,
                        NexoraColors.electricBlue,
                        NexoraColors.signalTeal,
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: NexoraColors.signalTeal.withValues(alpha: 0.8),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 28.0;
    const strokeWidth = 3.5;
    const radius = 8.0;

    final paint = Paint()
      ..color = NexoraColors.signalTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Top-Left
    final pathTL = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(cornerLength, 0);
    canvas.drawPath(pathTL, paint);

    // Top-Right
    final pathTR = Path()
      ..moveTo(w - cornerLength, 0)
      ..lineTo(w - radius, 0)
      ..quadraticBezierTo(w, 0, w, radius)
      ..lineTo(w, cornerLength);
    canvas.drawPath(pathTR, paint);

    // Bottom-Left
    final pathBL = Path()
      ..moveTo(0, h - cornerLength)
      ..lineTo(0, h - radius)
      ..quadraticBezierTo(0, h, radius, h)
      ..lineTo(cornerLength, h);
    canvas.drawPath(pathBL, paint);

    // Bottom-Right
    final pathBR = Path()
      ..moveTo(w - cornerLength, h)
      ..lineTo(w - radius, h)
      ..quadraticBezierTo(w, h, w, h - radius)
      ..lineTo(w, h - cornerLength);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 6. Animated Connection Beam connecting two device profile cards.
class NexoraConnectionBeam extends StatefulWidget {
  final double width;
  final double height;

  const NexoraConnectionBeam({
    super.key,
    this.width = double.infinity,
    this.height = 40,
  });

  @override
  State<NexoraConnectionBeam> createState() => _NexoraConnectionBeamState();
}

class _NexoraConnectionBeamState extends State<NexoraConnectionBeam>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _BeamPainter(offset: _controller.value),
          );
        },
      ),
    );
  }
}

class _BeamPainter extends CustomPainter {
  final double offset;

  _BeamPainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    // Background beam line
    final bgPaint = Paint()
      ..color = NexoraColors.electricBlue.withValues(alpha: 0.25)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), bgPaint);

    // Moving energy pulse packet
    final packetPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          NexoraColors.signalTeal,
          Colors.white,
          NexoraColors.signalTeal,
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final packetWidth = size.width * 0.35;
    final startX = (offset * (size.width + packetWidth)) - packetWidth;
    final endX = (startX + packetWidth).clamp(0.0, size.width);

    if (startX < size.width && endX > 0) {
      canvas.drawLine(
        Offset(math.max(0.0, startX), centerY),
        Offset(endX, centerY),
        packetPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BeamPainter oldDelegate) =>
      oldDelegate.offset != offset;
}

/// 7. Lightweight Celebration Confetti Particles for Transfer Completion.
class NexoraCelebrationParticles extends StatefulWidget {
  final double size;

  const NexoraCelebrationParticles({super.key, this.size = 200});

  @override
  State<NexoraCelebrationParticles> createState() =>
      _NexoraCelebrationParticlesState();
}

class _NexoraCelebrationParticlesState extends State<NexoraCelebrationParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ParticlesPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double progress;

  _ParticlesPainter({required this.progress});

  static const List<Color> particleColors = [
    NexoraColors.electricBlue,
    NexoraColors.signalTeal,
    Color(0xFF38BDF8),
    Color(0xFF34D399),
    Color(0xFFA78BFA),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final count = 16;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi / count) + (i * 0.1);
      final distance = progress * (size.width * 0.45);
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;

      final paint = Paint()
        ..color = particleColors[i % particleColors.length].withValues(
          alpha: opacity,
        )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), (1.0 - progress * 0.6) * 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
