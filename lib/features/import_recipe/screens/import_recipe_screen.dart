import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/recipe_import_error.dart';
import '../../../core/services/recipe_import_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/kitchen_app_bar.dart';
import 'import_progress_screen.dart';

class ImportRecipeScreen extends StatefulWidget {
  const ImportRecipeScreen({
    super.key,
    this.initialSharedText,
    this.sharedVideoPath,
    this.autoStart = false,
  });

  final String? initialSharedText;
  final String? sharedVideoPath;
  final bool autoStart;

  @override
  State<ImportRecipeScreen> createState() => _ImportRecipeScreenState();
}

class _ImportRecipeScreenState extends State<ImportRecipeScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _autoStarted = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialSharedText?.trim() ?? '';
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startSharedImport());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (mounted && text != null && text.isNotEmpty) {
      setState(() => _controller.text = text);
    }
  }

  Future<void> _startUrlImport() async {
    if (_busy) return;
    final url = _controller.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Paste a recipe video link first.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final job = await RecipeImportService.instance.createFromUrl(url);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImportProgressScreen(jobId: job.jobId),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = recipeImportErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startSharedImport() async {
    if (_autoStarted || !mounted) return;
    _autoStarted = true;
    final videoPath = widget.sharedVideoPath;
    if (videoPath == null) {
      await _startUrlImport();
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final job = await RecipeImportService.instance.createFromVideo(
        videoPath,
        caption: widget.initialSharedText,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImportProgressScreen(jobId: job.jobId),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = recipeImportErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KitchenAppBar(title: 'Import Recipe', showClose: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            height: 120,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.searchFill,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Stack(
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText:
                        'Paste a link from TikTok, Instagram, or YouTube...',
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 15,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _pasteFromClipboard,
                    child: const Icon(
                      Icons.link_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.terracottaDark,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _startUrlImport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Paste Link',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFDCD5CC))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'OR',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFDCD5CC))),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Or share directly',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                _StepRow(
                  number: '1',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                          children: const [
                            TextSpan(text: 'Tap '),
                            TextSpan(
                              text: 'Share',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: ' on your favorite video app.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(
                          3,
                          (i) => Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: const BoxDecoration(
                              color: AppColors.chipInactive,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              [
                                Icons.music_note_rounded,
                                Icons.camera_alt_outlined,
                                Icons.play_circle_outline,
                              ][i],
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _StepRow(
                  number: '2',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                          children: const [
                            TextSpan(text: 'Select '),
                            TextSpan(
                              text: 'CookSense',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFD5CEC4),
                            style: BorderStyle.solid,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.terracotta,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CookSense',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Importing deliciousness...',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.grey,
                BlendMode.saturation,
              ),
              child: Image.network(
                'https://images.unsplash.com/photo-1556911220-bff31c875db3?w=900&q=80',
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(height: 140, color: AppColors.searchFill),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "We'll automatically extract ingredients, steps, and nutritional info from the video.",
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.child});

  final String number;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.terracotta,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}
