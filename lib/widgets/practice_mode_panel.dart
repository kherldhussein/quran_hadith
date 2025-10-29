import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quran_hadith/services/practice_mode_service.dart';

/// Panel widget for practice mode controls
class PracticeModePanel extends StatelessWidget {
  final PracticeModeService service;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const PracticeModePanel({
    super.key,
    required this.service,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        if (!service.isPracticeModeActive) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildProgressBar(context),
              const SizedBox(height: 16),
              _buildControls(context),
              const SizedBox(height: 12),
              _buildRecordingControls(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                FontAwesomeIcons.graduationCap,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Practice Mode',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          'Surah ${service.practiceSurahNumber}, Ayah ${service.practiceAyahNumber}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.gear, size: 16),
          onPressed: () => _showSettings(context),
        ),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.xmark, size: 16),
          onPressed: () => service.stopPracticeMode(),
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final theme = Theme.of(context);
    final progress = service.getProgress();
    final isCompleted = service.isTargetCompleted();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Repetitions',
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            Row(
              children: [
                if (isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FaIcon(
                      FontAwesomeIcons.solidCircleCheck,
                      size: 14,
                      color: Colors.green,
                    ),
                  ),
                Text(
                  '${service.loopCount} / ${service.targetLoops}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            isCompleted ? Colors.green : theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.backwardStep),
          onPressed: onPrevious,
          tooltip: 'Previous Ayah',
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: onPlayPause,
          icon: const FaIcon(FontAwesomeIcons.repeat, size: 16),
          label: const Text('Repeat'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.forwardStep),
          onPressed: onNext,
          tooltip: 'Next Ayah',
        ),
      ],
    );
  }

  Widget _buildRecordingControls(BuildContext context) {
    final theme = Theme.of(context);
    final isRecording = service.isRecording;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isRecording)
          OutlinedButton.icon(
            onPressed: () => service.startRecording(),
            icon: const FaIcon(FontAwesomeIcons.microphone, size: 14),
            label: const Text('Record'),
          )
        else
          FilledButton.tonalIcon(
            onPressed: () => service.stopRecording(),
            icon: FaIcon(
              FontAwesomeIcons.stop,
              size: 14,
              color: Colors.red,
            ),
            label: Text(
              'Stop Recording',
              style: TextStyle(color: Colors.red),
            ),
          ),
        if (service.recordings.isNotEmpty) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => _showRecordings(context),
            icon: const FaIcon(FontAwesomeIcons.listUl, size: 14),
            label: Text('Recordings (${service.recordings.length})'),
          ),
        ],
      ],
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _PracticeModeSettings(service: service),
    );
  }

  void _showRecordings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _RecordingsList(service: service),
    );
  }
}

/// Settings modal for practice mode
class _PracticeModeSettings extends StatefulWidget {
  final PracticeModeService service;

  const _PracticeModeSettings({required this.service});

  @override
  State<_PracticeModeSettings> createState() => _PracticeModeSettingsState();
}

class _PracticeModeSettingsState extends State<_PracticeModeSettings> {
  late int _targetLoops;
  late int _pauseDuration;
  late bool _showTranslation;
  late bool _autoAdvance;

  @override
  void initState() {
    super.initState();
    _targetLoops = widget.service.targetLoops;
    _pauseDuration = widget.service.pauseDuration;
    _showTranslation = widget.service.showTranslation;
    _autoAdvance = widget.service.autoAdvance;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Practice Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),

          // Target loops
          Text(
            'Target Repetitions: $_targetLoops',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _targetLoops.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            label: '$_targetLoops times',
            onChanged: (value) {
              setState(() => _targetLoops = value.toInt());
            },
            onChangeEnd: (value) {
              widget.service.setTargetLoops(value.toInt());
            },
          ),
          const SizedBox(height: 16),

          // Pause duration
          Text(
            'Pause Between Repetitions: $_pauseDuration seconds',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _pauseDuration.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: '$_pauseDuration sec',
            onChanged: (value) {
              setState(() => _pauseDuration = value.toInt());
            },
            onChangeEnd: (value) {
              widget.service.setPauseDuration(value.toInt());
            },
          ),
          const SizedBox(height: 16),

          // Show translation toggle
          SwitchListTile(
            title: const Text('Show Translation'),
            subtitle: const Text('Display translation during practice'),
            value: _showTranslation,
            onChanged: (value) {
              setState(() => _showTranslation = value);
              widget.service.toggleShowTranslation();
            },
          ),

          // Auto-advance toggle
          SwitchListTile(
            title: const Text('Auto-Advance'),
            subtitle: const Text('Move to next ayah after target repetitions'),
            value: _autoAdvance,
            onChanged: (value) {
              setState(() => _autoAdvance = value);
              widget.service.toggleAutoAdvance();
            },
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recordings list modal
class _RecordingsList extends StatelessWidget {
  final PracticeModeService service;

  const _RecordingsList({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Recordings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          if (service.recordings.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No recordings yet',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              itemCount: service.recordings.length,
              itemBuilder: (context, index) {
                final recording = service.recordings[index];
                return ListTile(
                  leading: const FaIcon(FontAwesomeIcons.fileAudio),
                  title: Text('Recording ${index + 1}'),
                  subtitle: Text(recording),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.play, size: 16),
                        onPressed: () {
                          // TODO: Play recording
                        },
                      ),
                      IconButton(
                        icon: FaIcon(
                          FontAwesomeIcons.trash,
                          size: 16,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Recording?'),
                              content: const Text(
                                  'Are you sure you want to delete this recording?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            await service.deleteRecording(recording);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
