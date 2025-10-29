import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quran_hadith/controller/audio_controller.dart';
import 'package:quran_hadith/services/playback_state_service.dart';

/// A comprehensive live audio player with visualizer - only shows when audio is playing
class LiveAudioPlayer extends StatefulWidget {
  final AudioController audioController;

  const LiveAudioPlayer({
    super.key,
    required this.audioController,
  });

  @override
  State<LiveAudioPlayer> createState() => _LiveAudioPlayerState();
}

class _LiveAudioPlayerState extends State<LiveAudioPlayer>
    with TickerProviderStateMixin {
  late AnimationController _visualizerController;
  late AnimationController _pulseController;
  final List<double> _barHeights = [];
  static const int barCount = 50;

  @override
  void initState() {
    super.initState();

    // Visualizer animation - updates bars
    _visualizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _updateBarHeights();
          });
        }
      });

    // Pulse animation for glow effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Initialize bar heights
    for (int i = 0; i < barCount; i++) {
      _barHeights.add(0.2 + math.Random().nextDouble() * 0.3);
    }

    // Start animation when playing
    widget.audioController.buttonNotifier.addListener(_onPlaybackStateChanged);
    _onPlaybackStateChanged();
  }

  void _onPlaybackStateChanged() {
    final isPlaying =
        widget.audioController.buttonNotifier.value == ButtonState.playing;

    if (isPlaying) {
      if (!_visualizerController.isAnimating) {
        _visualizerController.repeat();
      }
    } else {
      _visualizerController.stop();
    }
  }

  void _updateBarHeights() {
    final random = math.Random();
    final progress = widget.audioController.progressNotifier.value;
    final position = progress.current.inMilliseconds;

    // Create flowing wave based on playback position
    final time = DateTime.now().millisecondsSinceEpoch / 50;

    for (int i = 0; i < _barHeights.length; i++) {
      // Multi-layered wave for complex movement
      final wave1 = math.sin((i * 0.15) + (time * 0.02)) * 0.25;
      final wave2 = math.sin((i * 0.08) + (time * 0.03) + 1.5) * 0.15;
      final wave3 = math.sin((i * 0.12) + (position / 1000)) * 0.1;

      // Random flutter for liveliness
      final flutter = (random.nextDouble() - 0.5) * 0.15;

      final targetHeight = (0.3 + wave1 + wave2 + wave3 + flutter).clamp(0.1, 0.95);

      // Smooth interpolation with momentum
      _barHeights[i] += (targetHeight - _barHeights[i]) * 0.25;
      _barHeights[i] = _barHeights[i].clamp(0.1, 0.95);
    }
  }

  @override
  void dispose() {
    widget.audioController.buttonNotifier
        .removeListener(_onPlaybackStateChanged);
    _visualizerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ButtonState>(
      valueListenable: widget.audioController.buttonNotifier,
      builder: (context, buttonState, _) {
        // Only show when playing or loading
        if (buttonState == ButtonState.paused) {
          return const SizedBox.shrink();
        }

        return AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: _buildPlayerWidget(context, buttonState),
        );
      },
    );
  }

  Widget _buildPlayerWidget(BuildContext context, ButtonState buttonState) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = _pulseController.value;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withValues(alpha: 0.08 + pulseValue * 0.04),
                accentColor.withValues(alpha: 0.06 + pulseValue * 0.03),
                theme.colorScheme.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.2 + pulseValue * 0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.15 + pulseValue * 0.1),
                blurRadius: 20 + pulseValue * 10,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Visualizer bars
              Container(
                height: 140,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(
                    barCount,
                    (index) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 0.8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              primaryColor.withValues(alpha: 0.9),
                              accentColor.withValues(alpha: 0.7),
                              primaryColor.withValues(alpha: 0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        height: 140 * _barHeights[index],
                      ),
                    ),
                  ),
                ),
              ),

              // Playback info
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  children: [
                    // Current playing info
                    ValueListenableBuilder<PlaybackInfo?>(
                      valueListenable: PlaybackStateService().currentPlayback,
                      builder: (context, playbackInfo, _) {
                        if (playbackInfo == null) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: FaIcon(
                                  FontAwesomeIcons.bookQuran,
                                  size: 16,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      playbackInfo.surahEnglishName,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Ayah ${playbackInfo.ayahNumber} • ${playbackInfo.reciter}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Progress bar
                    ValueListenableBuilder<ProgressBarState>(
                      valueListenable: widget.audioController.progressNotifier,
                      builder: (context, progress, _) {
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14,
                                ),
                                activeTrackColor: primaryColor,
                                inactiveTrackColor:
                                    primaryColor.withValues(alpha: 0.2),
                                thumbColor: primaryColor,
                                overlayColor:
                                    primaryColor.withValues(alpha: 0.2),
                              ),
                              child: Slider(
                                value: progress.total.inMilliseconds > 0
                                    ? progress.current.inMilliseconds /
                                        progress.total.inMilliseconds
                                    : 0.0,
                                onChanged: (value) {
                                  final position = Duration(
                                    milliseconds: (value *
                                            progress.total.inMilliseconds)
                                        .round(),
                                  );
                                  widget.audioController.seek(position);
                                },
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(progress.current),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(progress.total),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Playback controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: buttonState == ButtonState.playing
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: buttonState == ButtonState.playing
                                  ? Colors.green
                                  : Colors.orange,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                buttonState == ButtonState.playing
                                    ? FontAwesomeIcons.play
                                    : FontAwesomeIcons.spinner,
                                size: 12,
                                color: buttonState == ButtonState.playing
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                buttonState == ButtonState.playing
                                    ? 'Now Playing'
                                    : 'Loading...',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: buttonState == ButtonState.playing
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Play/Pause button
                        IconButton(
                          onPressed: () {
                            if (buttonState == ButtonState.playing) {
                              widget.audioController.pause();
                            } else if (buttonState == ButtonState.paused) {
                              widget.audioController.play();
                            }
                          },
                          icon: FaIcon(
                            buttonState == ButtonState.playing
                                ? FontAwesomeIcons.pause
                                : FontAwesomeIcons.play,
                            size: 20,
                          ),
                          color: primaryColor,
                          tooltip: buttonState == ButtonState.playing
                              ? 'Pause'
                              : 'Play',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
