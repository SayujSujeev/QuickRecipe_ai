import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/recipes.dart';
import '../../../core/theme/app_colors.dart';

class CookingStepScreen extends StatefulWidget {
  const CookingStepScreen({super.key});

  @override
  State<CookingStepScreen> createState() => _CookingStepScreenState();
}

class _CookingStepScreenState extends State<CookingStepScreen> {
  int _stepIndex = 1; // matches design "STEP 2 OF 8"
  Timer? _timer;
  int _remaining = 0;
  bool _running = false;

  CookingStep get _step => cookingSteps[_stepIndex];

  @override
  void initState() {
    super.initState();
    _remaining = _step.timerSeconds ?? 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goTo(int index) {
    _timer?.cancel();
    setState(() {
      _stepIndex = index.clamp(0, cookingSteps.length - 1);
      _remaining = cookingSteps[_stepIndex].timerSeconds ?? 0;
      _running = false;
    });
  }

  void _toggleTimer() {
    if (_step.timerSeconds == null) return;
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    if (_remaining <= 0) {
      _remaining = _step.timerSeconds!;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
        });
      } else {
        setState(() => _remaining--);
      }
    });
  }

  String get _timeLabel {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final hasTimer = _step.timerSeconds != null;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Row(
                children: List.generate(cookingSteps.length, (i) {
                  final active = i == _stepIndex;
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.only(
                        right: i == cookingSteps.length - 1 ? 0 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.terracotta
                            : AppColors.progressTrack,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              Text(
                'STEP ${_stepIndex + 1} OF ${cookingSteps.length}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(flex: 2),
              Text(
                _step.instruction,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(flex: 2),
              if (hasTimer)
                SizedBox(
                  width: 220,
                  height: 220,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.terracotta,
                        width: 10,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _remaining > 0
                              ? _timeLabel
                              : _formatSeconds(_step.timerSeconds!),
                          style: GoogleFonts.dmSans(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            color: AppColors.terracotta,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _toggleTimer,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _running
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 18,
                                color: AppColors.terracotta,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _running ? 'PAUSE TIMER' : 'START TIMER',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.terracotta,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox(height: 220),
              const Spacer(flex: 3),
              Padding(
                padding: EdgeInsets.only(bottom: 12 + bottom),
                child: Row(
                  children: [
                    Material(
                      color: AppColors.surface,
                      shape: const CircleBorder(
                        side: BorderSide(color: Color(0xFFD9CFC4), width: 1.5),
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          if (_stepIndex == 0) {
                            Navigator.of(context).pop();
                          } else {
                            _goTo(_stepIndex - 1);
                          }
                        },
                        child: const SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_stepIndex >= cookingSteps.length - 1) {
                            Navigator.of(context).pop();
                            return;
                          }
                          _goTo(_stepIndex + 1);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _stepIndex >= cookingSteps.length - 1
                                  ? 'Done'
                                  : 'Next Step',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_stepIndex < cookingSteps.length - 1) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSeconds(int total) {
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
