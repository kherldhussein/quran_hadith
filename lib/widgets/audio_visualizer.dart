import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quran_hadith/controller/audio_controller.dart';

/// A futuristic audio visualizer with advanced animations and real-time effects
class AudioVisualizer extends StatefulWidget {
  final AudioController audioController;
  final Color? primaryColor;
  final Color? accentColor;
  final double height;
  final int barCount;

  const AudioVisualizer({
    super.key,
    required this.audioController,
    this.primaryColor,
    this.accentColor,
    this.height = 220,
    this.barCount = 48,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  final List<double> _barHeights = [];
  final List<double> _barTargets = [];
  final List<double> _barVelocities = [];
  bool _isPlaying = false;
  double _energyLevel = 0.0;
  double _wavePhase = 0.0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps
    )..addListener(_onAnimationTick);

    _pulseAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 0.8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.3), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Initialize bars with physics
    for (int i = 0; i < widget.barCount; i++) {
      _barHeights.add(0.05);
      _barTargets.add(0.05);
      _barVelocities.add(0.0);
    }

    widget.audioController.buttonNotifier.addListener(_onAudioStateChanged);
    _onAudioStateChanged();
  }

  void _onAnimationTick() {
    if (!mounted) return;

    setState(() {
      _updateBarHeights();
      _wavePhase += 0.1;
      _energyLevel = _calculateEnergyLevel();
    });
  }

  void _onAudioStateChanged() {
    final state = widget.audioController.buttonNotifier.value;
    final wasPlaying = _isPlaying;
    _isPlaying = state == ButtonState.playing;

    if (_isPlaying && !wasPlaying) {
      _animationController.repeat();
    } else if (!_isPlaying && wasPlaying) {
      _animationController.stop();
      // Smooth transition to idle state
      for (int i = 0; i < _barTargets.length; i++) {
        _barTargets[i] = 0.05;
      }
      _energyLevel = 0.0;
    }
  }

  double _calculateEnergyLevel() {
    if (_barHeights.isEmpty) return 0.0;
    final averageHeight =
        _barHeights.reduce((a, b) => a + b) / _barHeights.length;
    return averageHeight.clamp(0.0, 1.0);
  }

  void _updateBarHeights() {
    if (!_isPlaying) {
      // Gentle floating animation when idle
      for (int i = 0; i < _barHeights.length; i++) {
        final wave = math.sin(_wavePhase + i * 0.2) * 0.02;
        _barTargets[i] = 0.05 + wave;
      }
    } else {
      final random = math.Random();
      // final progress = widget.audioController.progressNotifier.value;
      // final currentPosition = progress.current.inMilliseconds;

      // Create multiple frequency bands
      final bassWave = math.sin(_wavePhase * 0.5) * 0.3;
      final midWave = math.sin(_wavePhase * 1.2 + 2) * 0.4;
      final trebleWave = math.sin(_wavePhase * 2.0 + 4) * 0.3;

      for (int i = 0; i < _barHeights.length; i++) {
        final position = i / widget.barCount;

        // Combine multiple frequency bands
        final bass = bassWave * math.sin(position * math.pi);
        final mid = midWave * math.sin(position * math.pi * 2);
        final treble =
            trebleWave * (0.5 + 0.5 * math.sin(position * math.pi * 4));

        // Add some randomness for organic feel
        final noise = random.nextDouble() * 0.2 * _energyLevel;

        _barTargets[i] = (bass + mid + treble + noise + 0.5).clamp(0.05, 1.0);
      }
    }

    // Physics-based bar movement
    for (int i = 0; i < _barHeights.length; i++) {
      final damping = 0.2;
      final stiffness = 0.3;
      final acceleration = (_barTargets[i] - _barHeights[i]) * stiffness -
          _barVelocities[i] * damping;

      _barVelocities[i] += acceleration * 0.1;
      _barHeights[i] += _barVelocities[i];
      _barHeights[i] = _barHeights[i].clamp(0.05, 1.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    widget.audioController.buttonNotifier.removeListener(_onAudioStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.colorScheme.primary;
    final accentColor = widget.accentColor ?? theme.colorScheme.secondary;
    final isPlaying = _isPlaying;

    return ValueListenableBuilder<ButtonState>(
      valueListenable: widget.audioController.buttonNotifier,
      builder: (context, state, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPlaying
                  ? [
                      primaryColor.withOpacity(0.15),
                      accentColor.withOpacity(0.1),
                      Colors.transparent,
                    ]
                  : [
                      theme.colorScheme.surface.withOpacity(0.3),
                      theme.colorScheme.surface.withOpacity(0.1),
                    ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: GradientBorder(
              gradient: LinearGradient(
                colors: isPlaying
                    ? [
                        primaryColor.withOpacity(0.6),
                        accentColor.withOpacity(0.4),
                        primaryColor.withOpacity(0.2),
                      ]
                    : [
                        theme.dividerColor.withOpacity(0.1),
                        theme.dividerColor.withOpacity(0.05),
                      ],
              ),
              width: 2,
            ),
            boxShadow: isPlaying
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.25 * _energyLevel),
                      blurRadius: 30 + _energyLevel * 20,
                      spreadRadius: 2 + _energyLevel * 3,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: accentColor.withOpacity(0.15 * _energyLevel),
                      blurRadius: 15 + _energyLevel * 10,
                      spreadRadius: 1 + _energyLevel * 2,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: theme.colorScheme.onSurface.withOpacity(0.05),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isPlaying ? _pulseAnimation.value : 1.0,
                child: isPlaying
                    ? _buildVisualizerBars(theme, primaryColor, accentColor)
                    : _buildIdleState(theme, primaryColor),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVisualizerBars(
      ThemeData theme, Color primaryColor, Color accentColor) {
    return Stack(
      children: [
        // Background glow effect
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      primaryColor.withOpacity(
                          0.08 * _glowAnimation.value * _energyLevel),
                      accentColor.withOpacity(
                          0.04 * _glowAnimation.value * _energyLevel),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Main bars
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(
            widget.barCount,
            (index) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  curve: Curves.easeOut,
                  height: widget.height * _barHeights[index],
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        primaryColor.withOpacity(0.9),
                        primaryColor.withOpacity(0.7),
                        accentColor.withOpacity(0.8),
                        accentColor.withOpacity(0.4),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color:
                            primaryColor.withOpacity(0.5 * _barHeights[index]),
                        blurRadius: 6 * _barHeights[index],
                        spreadRadius: 1 * _barHeights[index],
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color:
                            accentColor.withOpacity(0.3 * _barHeights[index]),
                        blurRadius: 4 * _barHeights[index],
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Overlay scanning effect
        if (_isPlaying)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final scanPosition = _animationController.value * widget.height;
                return Container(
                  height: 2,
                  margin: EdgeInsets.only(top: scanPosition),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildIdleState(ThemeData theme, Color primaryColor) {
    return Stack(
      children: [
        // Floating particles in idle state
        ...List.generate(8, (index) {
          return Positioned(
            left:
                math.Random().nextDouble() * MediaQuery.of(context).size.width,
            top: math.Random().nextDouble() * widget.height,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final offset = math.sin(_wavePhase + index) * 10;
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: Container(
                    width: 2,
                    height: 2,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          );
        }),

        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.graphic_eq_rounded,
                size: 72,
                color: primaryColor.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              Text(
                'Play an ayah to activate visualizer',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom gradient border implementation
class GradientBorder extends BoxBorder {
  final Gradient gradient;
  final double width;

  const GradientBorder({
    required this.gradient,
    this.width = 1.0,
  });

  @override
  BorderSide get top => BorderSide(width: width);

  @override
  BorderSide get bottom => BorderSide(width: width);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    final rrect = borderRadius?.toRRect(rect) ??
        RRect.fromRectAndRadius(rect, Radius.zero);
    canvas.drawRRect(rrect, paint);
  }

  @override
  BoxBorder scale(double t) {
    return GradientBorder(
      gradient: gradient,
      width: width * t,
    );
  }

  @override
  bool get isUniform => true;
}
