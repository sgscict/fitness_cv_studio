import 'package:flutter/material.dart';
import '../models/user_fitness_profile.dart';
import '../models/workout_plan.dart';
import '../theme/studio_colors.dart';
import '../widgets/exercise_demo.dart';
import 'algorithm_sandbox_screen.dart';
import 'animated_workout_player_screen.dart';
import 'cv_fitness_studio_screen.dart';
import 'exercise_guide_screen.dart';

class MovementHubScreen extends StatefulWidget {
  const MovementHubScreen({super.key});

  @override
  State<MovementHubScreen> createState() => _MovementHubScreenState();
}

class _MovementHubScreenState extends State<MovementHubScreen> {
  UserFitnessProfile _profile = const UserFitnessProfile();
  FitnessCategory? _filterCategory;
  int _selectedDuration = 15;
  bool _preferDumbbells = false;

  // Daily aggregate stats
  int _dailyReps = 0;
  int _dailySeconds = 0;
  double _dailyKcal = 0.0;
  int _completedSessions = 0;

  @override
  Widget build(BuildContext context) {
    final workouts = WorkoutPlan.defaultCatalog.where((w) {
      if (_filterCategory != null && w.category != _filterCategory) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF090A10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10121C),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: StudioColors.volt, size: 24),
            SizedBox(width: 8),
            Text(
              'MOVEMENT & CV STUDIO',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Biomechanical Guide',
            icon: const Icon(Icons.menu_book_rounded, color: StudioColors.electricBlue, size: 20),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExerciseGuideScreen()),
            ),
          ),
          IconButton(
            tooltip: 'AI Calibration Sandbox',
            icon: const Icon(Icons.science_rounded, color: StudioColors.volt, size: 20),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AlgorithmSandboxScreen(
                  profile: _profile,
                  onProfileChanged: (p) => setState(() => _profile = p),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
        children: [
          // 1. Daily Activity Metrics Bento Card (Gen Z High Voltage)
          _buildDailyActivityBento(),
          const SizedBox(height: 14),

          // 2. Smart Heuristic Session Picker Card
          _buildSmartPickerCard(),
          const SizedBox(height: 14),

          // 3. Category Filter Chips
          _buildCategoryFilters(),
          const SizedBox(height: 12),

          // 4. Workout Catalog Cards
          ...workouts.map((w) => _buildWorkoutCard(w)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: StudioColors.volt,
        foregroundColor: Colors.black,
        elevation: 6,
        icon: const Icon(Icons.videocam_rounded, color: Colors.black),
        label: const Text(
          'OPEN AI CAMERA CV',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.6),
        ),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CvFitnessStudioScreen()),
        ),
      ),
    );
  }

  Widget _buildDailyActivityBento() {
    final activeMinutes = (_dailySeconds / 60).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131520),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF262A3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, color: StudioColors.coral, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'DAILY ACTIVITY FUEL',
                    style: TextStyle(
                      color: StudioColors.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: StudioColors.volt.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: StudioColors.volt.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '$_completedSessions WORKOUTS',
                  style: const TextStyle(
                    color: StudioColors.volt,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _GenZBentoTile(
                  emoji: '🔥',
                  value: _dailyKcal.toStringAsFixed(1),
                  unit: 'KCAL',
                  accentColor: StudioColors.coral,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _GenZBentoTile(
                  emoji: '⏱️',
                  value: '$activeMinutes',
                  unit: 'MINS',
                  accentColor: StudioColors.electricBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _GenZBentoTile(
                  emoji: '⚡',
                  value: '$_dailyReps',
                  unit: 'REPS',
                  accentColor: StudioColors.volt,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartPickerCard() {
    final match = WorkoutPlan.defaultCatalog.firstWhere(
      (w) => w.isDumbbell == _preferDumbbells && w.durationMinutes <= _selectedDuration + 3,
      orElse: () => WorkoutPlan.defaultCatalog.first,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131520),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: StudioColors.volt.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: StudioColors.volt, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'ZERO-DATA SMART PICK',
                    style: TextStyle(
                      color: StudioColors.volt,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('HEURISTIC', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Instant routine mapped to your time and gear without tracking baggage.',
            style: TextStyle(color: StudioColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),

          // Duration Selector
          Row(
            children: [
              ...[10, 15, 20].map((d) {
                final isSel = _selectedDuration == d;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('${d}m'),
                    selected: isSel,
                    selectedColor: StudioColors.volt,
                    backgroundColor: Colors.black45,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.black : Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                    onSelected: (_) => setState(() => _selectedDuration = d),
                  ),
                );
              }),
              const Spacer(),
              ChoiceChip(
                label: const Text('🏋️ Dumbbells'),
                selected: _preferDumbbells,
                selectedColor: StudioColors.hotPink,
                backgroundColor: Colors.black45,
                labelStyle: TextStyle(
                  color: _preferDumbbells ? Colors.white : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
                onSelected: (v) => setState(() => _preferDumbbells = v),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Recommended Workout Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${match.durationMinutes} min · ~${match.estimatedCalories} kcal · ${_formatCategory(match.category)}',
                        style: const TextStyle(color: StudioColors.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: StudioColors.volt,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('START', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                  onPressed: () => _launchWorkout(match),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = <(String, FitnessCategory?)>[
      ('All', null),
      ('Strength', FitnessCategory.jointFriendlyStrength),
      ('Chair', FitnessCategory.chairAssisted),
      ('Balance', FitnessCategory.balanceAndFallPrevention),
      ('Mobility', FitnessCategory.mobility),
      ('Walk', FitnessCategory.walking),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isSel = _filterCategory == cat.$2;
          return FilterChip(
            label: Text(cat.$1),
            selected: isSel,
            selectedColor: StudioColors.volt,
            backgroundColor: const Color(0xFF131520),
            side: BorderSide(color: isSel ? StudioColors.volt : const Color(0xFF262A3D)),
            labelStyle: TextStyle(
              color: isSel ? Colors.black : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
            onSelected: (_) => setState(() => _filterCategory = cat.$2),
          );
        },
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutPlan w) {
    final photoKey = w.demoPhotoKey ?? 'Bodyweight_Squat';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131520),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF262A3D)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated Preview Banner (Compact ExerciseDemo)
          Container(
            height: 125,
            color: Colors.black,
            child: Stack(
              children: [
                Center(
                  child: ExerciseDemo.photo(
                    photo: photoKey,
                    sex: _profile.sex,
                    height: 125,
                    showCvOverlay: false,
                    showNoteBelow: false,
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      _formatCategory(w.category).toUpperCase(),
                      style: const TextStyle(color: StudioColors.volt, fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                if (w.cvExercise != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: StudioColors.electricBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: StudioColors.electricBlue.withValues(alpha: 0.6)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam_rounded, size: 12, color: StudioColors.electricBlue),
                          SizedBox(width: 4),
                          Text('AI CV READY', style: TextStyle(color: StudioColors.electricBlue, fontSize: 9, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Workout Info & Start Button
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  w.subtitle,
                  style: const TextStyle(color: StudioColors.textMuted, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _GenZTag(emoji: '⏱️', text: '${w.durationMinutes}m'),
                    const SizedBox(width: 6),
                    _GenZTag(emoji: '🔥', text: '${w.estimatedCalories} kcal'),
                    const SizedBox(width: 6),
                    _GenZTag(emoji: '⚡', text: 'RPE ${w.rpeBorgScore}'),
                    const Spacer(),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: StudioColors.coral,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('START', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                      onPressed: () => _launchWorkout(w),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _launchWorkout(WorkoutPlan w) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnimatedWorkoutPlayerScreen(
          workout: w,
          profile: _profile,
          onWorkoutCompleted: (reps, secs, kcal) {
            setState(() {
              _dailyReps += reps;
              _dailySeconds += secs;
              _dailyKcal += kcal;
              _completedSessions++;
            });
          },
        ),
      ),
    );
  }

  String _formatCategory(FitnessCategory c) {
    switch (c) {
      case FitnessCategory.walking:
        return 'Cardio Walk';
      case FitnessCategory.mobility:
        return 'Mobility';
      case FitnessCategory.jointFriendlyStrength:
        return 'Strength';
      case FitnessCategory.swimming:
        return 'Aquatics';
      case FitnessCategory.chairAssisted:
        return 'Chair-Assisted';
      case FitnessCategory.balanceAndFallPrevention:
        return 'Balance';
    }
  }
}

class _GenZBentoTile extends StatelessWidget {
  final String emoji;
  final String value;
  final String unit;
  final Color accentColor;

  const _GenZBentoTile({
    required this.emoji,
    required this.value,
    required this.unit,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const Spacer(),
              Text(
                unit,
                style: const TextStyle(color: StudioColors.textMuted, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: accentColor, fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _GenZTag extends StatelessWidget {
  final String emoji;
  final String text;

  const _GenZTag({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
