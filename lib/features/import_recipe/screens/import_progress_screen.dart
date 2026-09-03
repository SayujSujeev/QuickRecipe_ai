import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/recipe_import_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/kitchen_app_bar.dart';
import '../../../data/models/recipe_import_job.dart';
import 'import_error_screen.dart';
import 'import_review_screen.dart';

const _stages = [
  ('queued', 'Preparing source'),
  ('acquiring_source', 'Preparing source'),
  ('preprocessing', 'Processing video'),
  ('transcribing', 'Transcribing audio'),
  ('analyzing', 'Creating recipe'),
  ('validating', 'Creating recipe'),
];

/// Restorable by [jobId] alone: reopening this screen (including after an
/// app restart) just re-subscribes to the Firestore job document.
class ImportProgressScreen extends StatefulWidget {
  const ImportProgressScreen({super.key, required this.jobId});

  final String jobId;

  @override
  State<ImportProgressScreen> createState() => _ImportProgressScreenState();
}

class _ImportProgressScreenState extends State<ImportProgressScreen> {
  bool _navigatedAway = false;

  void _maybeNavigate(RecipeImportJob job) {
    if (_navigatedAway || !mounted) return;

    if (job.isReadyForReview && job.draftId != null) {
      _navigatedAway = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              ImportReviewScreen(jobId: job.jobId, draftId: job.draftId!),
        ),
      );
    } else if (job.isTerminalFailure) {
      _navigatedAway = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ImportErrorScreen(message: job.errorMessage),
        ),
      );
    } else if (job.isCancelled) {
      _navigatedAway = true;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KitchenAppBar(title: 'Importing Recipe'),
      body: StreamBuilder<RecipeImportJob?>(
        stream: RecipeImportService.instance.watchJob(widget.jobId),
        builder: (context, snapshot) {
          final job = snapshot.data;
          if (job == null) {
            return const Center(child: CircularProgressIndicator());
          }

          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _maybeNavigate(job),
          );

          if (job.isRetryable) {
            return _RetryPanel(
              job: job,
              onRetry: () => RecipeImportService.instance.retry(job.jobId),
            );
          }

          if (job.isRecoverable) {
            return _UploadRecoveryPanel(job: job);
          }

          return _ProgressPanel(job: job);
        },
      ),
    );
  }
}

class _UploadRecoveryPanel extends StatefulWidget {
  const _UploadRecoveryPanel({required this.job});

  final RecipeImportJob job;

  @override
  State<_UploadRecoveryPanel> createState() => _UploadRecoveryPanelState();
}

class _UploadRecoveryPanelState extends State<_UploadRecoveryPanel> {
  bool _uploading = false;
  String? _error;

  Future<void> _chooseVideo() async {
    const videos = XTypeGroup(
      label: 'Videos',
      extensions: ['mp4', 'mov', 'm4v', 'webm'],
      mimeTypes: ['video/mp4', 'video/quicktime', 'video/webm'],
      uniformTypeIdentifiers: ['public.movie'],
    );
    final file = await openFile(acceptedTypeGroups: [videos]);
    if (file == null || !mounted) return;

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await RecipeImportService.instance.continueWithVideo(
        widget.job,
        file.path,
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.video_file_outlined,
            size: 64,
            color: AppColors.terracotta,
          ),
          const SizedBox(height: 18),
          Text(
            'We need the video for this one',
            style: GoogleFonts.fraunces(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.job.errorMessage ??
                'The social post did not expose enough recipe detail.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: AppColors.terracottaDark),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _uploading ? null : _chooseVideo,
              icon: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_rounded),
              label: Text(_uploading ? 'Uploading…' : 'Choose Video'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'MP4, MOV, M4V or WebM • up to 150 MB',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.job});
  final RecipeImportJob job;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: job.progressPercent / 100,
              minHeight: 10,
              backgroundColor: AppColors.progressTrack,
              color: AppColors.terracotta,
            ),
          ),
          const SizedBox(height: 28),
          ..._stages.map(
            (stage) => _StageRow(
              label: stage.$2,
              done:
                  _stageIndex(job.state) >
                  _stages.indexWhere((s) => s.$1 == stage.$1),
              active: job.state == stage.$1,
            ),
          ),
        ],
      ),
    );
  }

  int _stageIndex(String state) {
    final idx = _stages.indexWhere((s) => s.$1 == state);
    return idx == -1 ? _stages.length : idx;
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.label,
    required this.done,
    required this.active,
  });
  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = done || active ? AppColors.terracotta : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle
                : (active ? Icons.autorenew : Icons.circle_outlined),
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: done || active
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RetryPanel extends StatelessWidget {
  const _RetryPanel({required this.job, required this.onRetry});
  final RecipeImportJob job;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.refresh_rounded,
            size: 56,
            color: AppColors.terracotta,
          ),
          const SizedBox(height: 16),
          Text(
            job.errorMessage ?? 'Something went wrong. You can try again.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ),
        ],
      ),
    );
  }
}
