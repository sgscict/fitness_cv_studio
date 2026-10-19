import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/coach_exercise.dart';
import '../models/user_fitness_profile.dart';

/// Recreated Gender-Aware Home Workout Visual Demonstrator.
/// Renders a Woman (`BiologicalSex.female`) or Man (`BiologicalSex.male`) performing
/// the exact exercise inside a home living-room setting (with dumbbells, chair, wall,
/// or mat as appropriate) and highlights the Computer Vision (CV) tracked joints.
class ExerciseDemo extends StatefulWidget {
  final String photo; // exercise visual key
  final String? note;
  final double height;
  final bool filipino;
  final BiologicalSex? sex;
  final bool showCvOverlay;
  final bool showNoteBelow;
  final bool compact;

  ExerciseDemo({
    super.key,
    required CoachExercise exercise,
    this.height = 240,
    this.filipino = true,
    this.sex,
    this.showCvOverlay = true,
    this.showNoteBelow = true,
    this.compact = false,
  })  : photo = _photos[exercise] ?? 'Bodyweight_Squat',
        note = safeNote(exercise, filipino: filipino);

  const ExerciseDemo.photo({
    super.key,
    required this.photo,
    this.note,
    this.height = 240,
    this.filipino = true,
    this.sex,
    this.showCvOverlay = true,
    this.showNoteBelow = true,
    this.compact = false,
  });

  /// Home workout demo for a guided workout category or specific workout id.
  static ExerciseDemo? forCategory(
    String category, {
    String? workoutId,
    double height = 220,
    bool filipino = true,
    BiologicalSex? sex,
    bool showNoteBelow = true,
  }) {
    if (workoutId != null) {
      final specific = _workoutPhotoKey[workoutId];
      if (specific != null) {
        return ExerciseDemo.photo(
          photo: specific,
          note: _workoutNoteFil[workoutId],
          height: height,
          filipino: filipino,
          sex: sex,
          showCvOverlay: category != 'walking',
          showNoteBelow: showNoteBelow,
        );
      }
    }
    switch (category) {
      case 'walking':
        return ExerciseDemo.photo(
          photo: 'Walking_Treadmill',
          note: 'Maglakad sa bahay, bakuran, barangay, o mall sa bilis na nakakapagsalita pa rin (Walang Camera CV — Timer & Steps).',
          height: height,
          filipino: filipino,
          sex: sex,
          showCvOverlay: false,
          showNoteBelow: showNoteBelow,
        );
      case 'jointFriendlyStrength':
        return ExerciseDemo.photo(
          photo: 'Bodyweight_Squat',
          note: safeNote(CoachExercise.squat, filipino: true),
          height: height,
          filipino: filipino,
          sex: sex,
          showNoteBelow: showNoteBelow,
        );
      case 'balanceAndFallPrevention':
        return ExerciseDemo.photo(
          photo: 'Side_Leg_Raises',
          note: 'Laging nakahawak ang isang kamay sa matibay na upuan sa bahay.',
          height: height,
          filipino: filipino,
          sex: sex,
          showNoteBelow: showNoteBelow,
        );
      case 'chairAssisted':
        return ExerciseDemo.photo(
          photo: 'Seated_Dumbbell_Press',
          note: 'Nakaupo nang tuwid sa matibay na upuan sa bahay; huminga palabas sa bawat angat.',
          height: height,
          filipino: filipino,
          sex: sex,
          showNoteBelow: showNoteBelow,
        );
      case 'mobility':
        return ExerciseDemo.photo(
          photo: 'Cat_Stretch',
          note: 'Banayad na pag-unat ng likod at balikat kasabay ng malalim na paghinga.',
          height: height,
          filipino: filipino,
          sex: sex,
          showNoteBelow: showNoteBelow,
        );
      default:
        return ExerciseDemo.photo(
          photo: 'Bodyweight_Squat',
          note: safeNote(CoachExercise.squat, filipino: true),
          height: height,
          filipino: filipino,
          sex: sex,
          showNoteBelow: showNoteBelow,
        );
    }
  }

  static const _workoutPhotoKey = <String, String>{
    'w1': 'Walking_Treadmill',
    'w_pinoy1': 'Walking_Treadmill',
    'w2': 'Incline_Push-Up',
    'w3': 'Bodyweight_Squat',
    'w4': 'Side_Leg_Raises',
    'w5': 'Arm_Circles',
    'w_pinoy2': 'Front_Leg_Raises',
    'w_db1': 'Seated_Dumbbell_Press',
    'w_db2': 'Dumbbell_Squat',
    'w_db3': 'Bent_Over_Two-Dumbbell_Row',
    'w_db4': 'Hammer_Curls',
    'w_db5': 'Front_Two-Dumbbell_Raise',
  };

  static const _workoutNoteFil = <String, String>{
    'w1': 'Zone-2 Lakad: Hindi kailangan ng Camera CV. Gamitin ang timer at panatilihin ang talk-test pace.',
    'w_pinoy1': '15-Min Lakad Pagkatapos Kumain: Walang Camera CV — maglakad nang banayad sa sala o bakuran.',
    'w2': 'Home Core & Wall Push-Up: Puwedeng bantayan ng AI Camera CV ang tuwid ng likod at siko.',
    'w3': 'Home Chair/Wall Squat: Binabantayan ng AI Camera CV ang 90° anggulo ng tuhod.',
    'w4': 'Home Balance & Leg Raise: Humawak sa upuan habang binibilang ng AI Camera CV ang taas ng binti.',
    'w_pinoy2': 'Home Chair Routine: Ligtas na galaw sa upuan na may gabay ng AI Camera CV.',
    'w_db1': 'Home Dumbbell Upper Body: Hawakan ang dumbbells kapantay ng balikat; binabantayan ng CV ang pantay na tulak.',
    'w_db2': 'Home Dumbbell Chair Squat: Hawakan ang dumbbells sa gilid at umupo hanggang ~90° sa upuan.',
    'w_db3': 'Home Dumbbell Back & Row: Yumuko nang 45° nang diretso ang likod at hilahin ang dumbbells sa tadyang.',
    'w_db4': 'Home Dumbbell Arms & Shoulders: Idikit ang siko sa tagiliran habang nagku-curl ng dumbbells.',
    'w_db5': 'Home Dumbbell Full-Body Circuit: Kontroladong galaw ng dumbbell kasabay ng paghinga palabas.',
  };

  static String? safeNote(CoachExercise e, {bool filipino = true}) =>
      filipino ? safeVersionFil[e] : safeVersion[e];

  static const _photos = <CoachExercise, String>{
    CoachExercise.auto: 'Bodyweight_Squat',
    CoachExercise.squat: 'Bodyweight_Squat',
    CoachExercise.dumbbellSquat: 'Dumbbell_Squat',
    CoachExercise.armRaise: 'Side_Lateral_Raise',
    CoachExercise.frontRaise: 'Front_Two-Dumbbell_Raise',
    CoachExercise.bicepCurl: 'Hammer_Curls',
    CoachExercise.shoulderPress: 'Seated_Dumbbell_Press',
    CoachExercise.dumbbellRow: 'Bent_Over_Two-Dumbbell_Row',
    CoachExercise.dumbbellLunge: 'Dumbbell_Lunges',
    CoachExercise.wallPushUp: 'Incline_Push-Up',
    CoachExercise.marching: 'Step-up_with_Knee_Raise',
    CoachExercise.legRaise: 'Side_Leg_Raises',
    CoachExercise.gluteBridge: 'Butt_Lift_Bridge',
  };

  static const safeVersion = <CoachExercise, String>{
    CoachExercise.squat: 'Joint-safe home version: place a sturdy chair behind you and stop at ~90° when you touch the seat.',
    CoachExercise.dumbbellSquat: 'Hold dumbbells at your sides, sit back to a chair (~90° knees), and exhale as you stand.',
    CoachExercise.auto: 'Stand 2–3m from the phone camera in your living room so your body is in view.',
    CoachExercise.wallPushUp: 'Place hands on a wall at shoulder height; keep body straight from shoulders to ankles.',
    CoachExercise.marching: 'March in place at home; hold the back of a chair if you want balance support.',
    CoachExercise.armRaise: 'Raise arms or light dumbbells out to the side up to shoulder height.',
    CoachExercise.frontRaise: 'Lift dumbbells in front of thighs up to shoulder height without swinging.',
    CoachExercise.bicepCurl: 'Keep elbows pinned at your sides while curling dumbbells or water bottles.',
    CoachExercise.shoulderPress: 'Sit tall on a chair and press dumbbells overhead while exhaling.',
    CoachExercise.dumbbellRow: 'Hinge at the hips with a flat back and pull dumbbells to your lower ribs.',
    CoachExercise.dumbbellLunge: 'Step forward with a controlled ~90° knee bend; keep torso upright.',
    CoachExercise.legRaise: 'Hold a sturdy chair with one hand and lift your straight leg smoothly.',
    CoachExercise.gluteBridge: 'Lie on a home mat with knees bent and lift your hips until aligned.',
  };

  static const safeVersionFil = <CoachExercise, String>{
    CoachExercise.squat: 'Gabay sa Bahay: Maglagay ng matibay na upuan sa likod at huminto pag nadikit sa upuan (tuhod ~90°).',
    CoachExercise.dumbbellSquat: 'Gabay sa Bahay: Hawakan ang dumbbells sa tagiliran, umupo hanggang ~90° sa upuan, at ibuga ang hininga pag-angat.',
    CoachExercise.auto: 'Gabay sa Bahay: Pumuwesto 2–3m sa harap ng camera sa sala para kita ang buong katawan.',
    CoachExercise.wallPushUp: 'Gabay sa Bahay: Ilagay ang kamay sa pader kapantay ng balikat at panatilihing diretso ang katawan.',
    CoachExercise.marching: 'Gabay sa Bahay: Iangat ang tuhod nang salitan sa sala; humawak sa upuan kung kailangan ng balanse.',
    CoachExercise.armRaise: 'Gabay sa Bahay: Itaas ang braso o magaan na dumbbells sa gilid hanggang kapantay ng balikat.',
    CoachExercise.frontRaise: 'Gabay sa Bahay: Itaas ang dumbbells sa harap hanggang pantay-balikat nang hindi umiindayog.',
    CoachExercise.bicepCurl: 'Gabay sa Bahay: Idikit ang siko sa tagiliran habang nagku-curl ng dumbbells o bote ng tubig.',
    CoachExercise.shoulderPress: 'Gabay sa Bahay: Umupo nang tuwid sa upuan at itulak ang dumbbells pataas habang bumubuga ng hininga.',
    CoachExercise.dumbbellRow: 'Gabay sa Bahay: Yumuko nang 45° na diretso ang likod at hilahin ang dumbbells papunta sa tadyang.',
    CoachExercise.dumbbellLunge: 'Gabay sa Bahay: Humakbang pa-harap at ibaba ang tuhod (~90°) nang nananatiling tuwid ang dibdib.',
    CoachExercise.legRaise: 'Gabay sa Bahay: Humawak sa sandalan ng upuan at iangat nang tuwid ang binti.',
    CoachExercise.gluteBridge: 'Gabay sa Bahay: Humiga sa home mat nang nakabaluktot ang tuhod at iangat ang balakang.',
  };

  @override
  State<ExerciseDemo> createState() => _ExerciseDemoState();
}

class _ExerciseDemoState extends State<ExerciseDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  BiologicalSex? _overrideSex;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    final isWidgetTest = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    if (isWidgetTest) {
      _ctrl.value = 0.5;
    } else {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _isFemale(BuildContext context) {
    final s = _overrideSex ?? widget.sex;
    if (s != null) return s == BiologicalSex.female;
    return false;
  }

  bool get _hasDumbbells {
    final p = widget.photo;
    return p.contains('Dumbbell') ||
        p.contains('Hammer_Curls') ||
        p.contains('Side_Lateral_Raise');
  }

  bool get _isWalking => widget.photo == 'Walking_Treadmill';

  String get _filipinoActionCue {
    switch (widget.photo) {
      case 'Dumbbell_Squat':
        return '🏋️ Dumbbell Chair Squat: Ibaba sa ~90° upuan → Itulak pataas';
      case 'Bodyweight_Squat':
        return '🪑 Home Chair Squat: Ibaba sa ~90° upuan → Tumayo nang tuwid';
      case 'Seated_Dumbbell_Press':
        return '🏋️ Seated Dumbbell Press: Balikat → Itulak ang dumbbells pataas';
      case 'Bent_Over_Two-Dumbbell_Row':
        return '🏋️ Dumbbell Row: Diretso ang likod → Hilahin ang dumbbell sa tadyang';
      case 'Hammer_Curls':
      case 'Dumbbell_Bicep_Curl':
        return '🏋️ Dumbbell Curl: Siko sa gilid → I-curl ang dumbbell sa balikat';
      case 'Front_Two-Dumbbell_Raise':
        return '🏋️ Dumbbell Front Raise: Hita → Itaas sa harap hanggang balikat';
      case 'Side_Lateral_Raise':
        return '🏋️ Dumbbell Side Raise: Gilid → Itaas patagilid hanggang balikat';
      case 'Dumbbell_Lunges':
        return '🏋️ Dumbbell Step Lunge: Hakbang pa-harap (~90°) → Balik sa tayo';
      case 'Incline_Push-Up':
        return '🧱 Home Wall Push-Up: Kamay sa pader → Ilapit ang dibdib → Itulak';
      case 'Butt_Lift_Bridge':
        return '🧘 Home Glute Bridge: Nakabaluktot tuhod → Iangat ang balakang';
      case 'Step-up_with_Knee_Raise':
        return '🦵 Home Standing March: Salitang iangat ang kaliwa at kanang tuhod';
      case 'Plank':
        return '🧘 Home Knee Plank: Tuwid ang balikat hanggang tuhod, tuloy ang hinga';
      case 'Front_Leg_Raises':
        return '🪑 Home Front Leg Raise: Hawak sa upuan → Iangat ang tuwid na binti';
      case 'Side_Leg_Raises':
        return '🪑 Home Side Leg Raise: Hawak sa upuan → Iangat sa gilid ang binti';
      case 'Arm_Circles':
        return '🙆 Home Arm Circles: Iunat ang braso sa gilid at paikutin nang marahan';
      case 'Cat_Stretch':
        return '🧘 Home Cat-Cow Stretch: Iarko pataas ang likod → Dahan-dahang i-relax';
      case 'Hamstring_Stretch':
        return '🧘 Home Hamstring Stretch: Iunat ang likod ng hita nang walang sakit';
      case 'Walking_Treadmill':
        return '🚶 Home / Barangay Brisk Walk: Bilis na nakakapagsalita (Walang CV)';
      default:
        return '🏠 Home Workout Guide: Sundan ang simulang at huling posisyon';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFemale = _isFemale(context);
    if (widget.compact) {
      return SizedBox.expand(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_ctrl.value);
            return CustomPaint(
              painter: _HomeExerciseStudioPainter(
                photoKey: widget.photo,
                progress: t,
                isFemale: isFemale,
                showCvOverlay: widget.showCvOverlay && !_isWalking,
              ),
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(_ctrl.value);
                final isEnd = t > 0.5;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _HomeExerciseStudioPainter(
                        photoKey: widget.photo,
                        progress: t,
                        isFemale: isFemale,
                        showCvOverlay: widget.showCvOverlay && !_isWalking,
                      ),
                    ),
                    // Top HUD Row (Phase pill on left, Equipment + Gender toggle on right — never collides)
                    Positioned(
                      left: 8,
                      right: 8,
                      top: 8,
                      child: Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A)
                                    .withValues(alpha: 0.90),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isEnd
                                        ? Icons.check_circle_rounded
                                        : Icons.play_circle_fill_rounded,
                                    color: const Color(0xFFFF5C38),
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      isEnd
                                          ? 'Huling Posisyon (End)'
                                          : 'Simulang Posisyon (Start)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (_hasDumbbells)
                            Container(
                              margin: const EdgeInsets.only(right: 5),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A)
                                    .withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '🏋️ Dumbbell',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _overrideSex = isFemale
                                    ? BiologicalSex.male
                                    : BiologicalSex.female;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.68),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isFemale ? '👩 Babae' : '👨 Lalaki',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bottom Filipino action & CV bar
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isWalking
                                  ? Icons.timer_outlined
                                  : Icons.center_focus_strong_rounded,
                              color: _isWalking
                                  ? const Color(0xFFFCD34D)
                                  : const Color(0xFF34D399),
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _filipinoActionCue,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (!_isWalking && widget.showCvOverlay)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5C38),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'CV Active',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        if (widget.note != null && widget.showNoteBelow)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '🇵🇭 ${widget.note}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF992208),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
      ],
    );
  }
}

class _PoseRig {
  final Offset head;
  final Offset neck;
  final Offset shoulderL;
  final Offset shoulderR;
  final Offset elbowL;
  final Offset elbowR;
  final Offset wristL;
  final Offset wristR;
  final Offset hipL;
  final Offset hipR;
  final Offset kneeL;
  final Offset kneeR;
  final Offset ankleL;
  final Offset ankleR;
  final bool hasChair;
  final bool hasWall;
  final bool hasDumbbells;
  final List<Offset> cvFocusPoints;
  final String cvAngleLabel;

  const _PoseRig({
    required this.head,
    required this.neck,
    required this.shoulderL,
    required this.shoulderR,
    required this.elbowL,
    required this.elbowR,
    required this.wristL,
    required this.wristR,
    required this.hipL,
    required this.hipR,
    required this.kneeL,
    required this.kneeR,
    required this.ankleL,
    required this.ankleR,
    this.hasChair = false,
    this.hasWall = false,
    this.hasDumbbells = false,
    this.cvFocusPoints = const [],
    this.cvAngleLabel = '',
  });
}

class _HomeExerciseStudioPainter extends CustomPainter {
  final String photoKey;
  final double progress;
  final bool isFemale;
  final bool showCvOverlay;

  const _HomeExerciseStudioPainter({
    required this.photoKey,
    required this.progress,
    required this.isFemale,
    required this.showCvOverlay,
  });

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
  static Offset _lerpPt(Offset a, Offset b, double t) =>
      Offset(_lerp(a.dx, b.dx, t), _lerp(a.dy, b.dy, t));

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Cozy Filipino Home Living Room Backdrop (Sala)
    final wallPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF8FAFC), Color(0xFFFFF1EE)],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.74));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.74), wallPaint);

    // Home Window with daylight on top-left
    final winRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.16, w * 0.18, h * 0.28),
      const Radius.circular(8),
    );
    canvas.drawRRect(winRect, Paint()..color = const Color(0xFFE0F2FE));
    canvas.drawRRect(
      winRect,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(w * 0.17, h * 0.16),
      Offset(w * 0.17, h * 0.44),
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 1.5,
    );
    canvas.drawLine(
      Offset(w * 0.08, h * 0.30),
      Offset(w * 0.26, h * 0.30),
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 1.5,
    );

    // Floor & Baseboard
    final floorY = h * 0.74;
    canvas.drawRect(
      Rect.fromLTWH(0, floorY, w, h - floorY),
      Paint()..color = const Color(0xFFE2E8F0),
    );
    canvas.drawLine(
      Offset(0, floorY),
      Offset(w, floorY),
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..strokeWidth = 2,
    );

    // Home Yoga / Workout Mat on Floor
    final matRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, floorY + h * 0.045),
        width: w * 0.62,
        height: h * 0.065,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      matRect,
      Paint()..color = isFemale ? const Color(0xFF8B5CF6) : const Color(0xFFFF5C38),
    );
    canvas.drawRRect(
      matRect,
      Paint()
        ..color = isFemale ? const Color(0xFFC4B5FD) : const Color(0xFFFF8A70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Build animated pose rig for the exercise
    final rig = _buildRig(photoKey, progress);

    Offset pt(Offset norm) => Offset(norm.dx * w, norm.dy * h);

    // 2. Draw Home Chair or Wall if used by this exercise
    if (rig.hasChair) {
      final chairPaint = Paint()
        ..color = const Color(0xFF78350F)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      // Seat & Backrest on the left/behind
      final seatY = h * 0.59;
      final chairX = w * 0.36;
      canvas.drawLine(Offset(chairX, h * 0.36), Offset(chairX, h * 0.74), chairPaint);
      canvas.drawLine(Offset(chairX, seatY), Offset(chairX + w * 0.11, seatY), chairPaint);
      canvas.drawLine(Offset(chairX + w * 0.11, seatY), Offset(chairX + w * 0.11, h * 0.74), chairPaint);
    }

    if (rig.hasWall) {
      final wallX = w * 0.72;
      canvas.drawRect(
        Rect.fromLTWH(wallX, h * 0.12, w * 0.04, h * 0.62),
        Paint()..color = const Color(0xFF94A3B8),
      );
    }

    // 3. Draw Gender-Aware Avatar (Woman vs Man)
    final skinPaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.85)
      ..strokeWidth = isFemale ? 9 : 11
      ..strokeCap = StrokeCap.round;

    final topColor = isFemale ? const Color(0xFFDB2777) : const Color(0xFF0284C7);
    final pantsColor = isFemale ? const Color(0xFF4C1D95) : const Color(0xFF1E293B);

    final legPaint = Paint()
      ..color = pantsColor
      ..strokeWidth = isFemale ? 11.5 : 13.5
      ..strokeCap = StrokeCap.round;

    final armPaint = Paint()
      ..color = topColor
      ..strokeWidth = isFemale ? 9.5 : 11.5
      ..strokeCap = StrokeCap.round;

    // Legs (Hip -> Knee -> Ankle + Shoes)
    canvas.drawLine(pt(rig.hipL), pt(rig.kneeL), legPaint);
    canvas.drawLine(pt(rig.kneeL), pt(rig.ankleL), legPaint);
    canvas.drawLine(pt(rig.hipR), pt(rig.kneeR), legPaint);
    canvas.drawLine(pt(rig.kneeR), pt(rig.ankleR), legPaint);

    final shoePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final shoeBorder = Paint()
      ..color = topColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final a in [pt(rig.ankleL), pt(rig.ankleR)]) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: a.translate(4, 2), width: 18, height: 9),
        const Radius.circular(5),
      );
      canvas.drawRRect(r, shoePaint);
      canvas.drawRRect(r, shoeBorder);
    }

    // Torso Polygon (Feminine tapered waist vs Masculine broader shoulders)
    final sL = pt(rig.shoulderL);
    final sR = pt(rig.shoulderR);
    final hL = pt(rig.hipL);
    final hR = pt(rig.hipR);
    final torsoPath = Path()
      ..moveTo(sL.dx, sL.dy)
      ..lineTo(sR.dx, sR.dy)
      ..lineTo(hR.dx, hR.dy)
      ..lineTo(hL.dx, hL.dy)
      ..close();
    canvas.drawPath(torsoPath, Paint()..color = topColor);

    // Core spine line
    final midShoulder = Offset((sL.dx + sR.dx) / 2, (sL.dy + sR.dy) / 2);
    final midHip = Offset((hL.dx + hR.dx) / 2, (hL.dy + hR.dy) / 2);
    canvas.drawLine(
      midShoulder,
      midHip,
      Paint()
        ..color = topColor
        ..strokeWidth = isFemale ? 18 : 22
        ..strokeCap = StrokeCap.round,
    );

    // Neck & Head
    final headPt = pt(rig.head);
    final neckPt = pt(rig.neck);
    canvas.drawLine(neckPt, headPt, skinPaint);

    // Hair (Woman ponytail/bun vs Man short crop)
    final hairPaint = Paint()..color = const Color(0xFF1E293B);
    if (isFemale) {
      // Ponytail arc
      canvas.drawCircle(headPt.translate(-12, -2), 7.5, hairPaint);
      canvas.drawCircle(headPt.translate(-17, 4), 5.5, hairPaint);
    }
    canvas.drawCircle(headPt, 13, Paint()..color = const Color(0xFFFBBF24));
    // Hair cap on top of head
    canvas.drawArc(
      Rect.fromCircle(center: headPt.translate(0, -2), radius: 13.5),
      math.pi * 0.95,
      math.pi * 1.1,
      true,
      hairPaint,
    );

    // Arms (Shoulder -> Elbow -> Wrist)
    canvas.drawLine(sL, pt(rig.elbowL), armPaint);
    canvas.drawLine(pt(rig.elbowL), pt(rig.wristL), skinPaint);
    canvas.drawLine(sR, pt(rig.elbowR), armPaint);
    canvas.drawLine(pt(rig.elbowR), pt(rig.wristR), skinPaint);

    // 4. Draw Dumbbells in Both Hands when it's a Dumbbell Exercise!
    if (rig.hasDumbbells) {
      for (final wPt in [pt(rig.wristL), pt(rig.wristR)]) {
        _drawDumbbell(canvas, wPt);
      }
    }

    // 5. Draw Computer Vision Joint Tracking Overlay & Target Angle Badge
    if (showCvOverlay) {
      final cvLinePaint = Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: 0.65)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(sL, pt(rig.elbowL), cvLinePaint);
      canvas.drawLine(pt(rig.elbowL), pt(rig.wristL), cvLinePaint);
      canvas.drawLine(sR, pt(rig.elbowR), cvLinePaint);
      canvas.drawLine(pt(rig.elbowR), pt(rig.wristR), cvLinePaint);
      canvas.drawLine(midShoulder, midHip, cvLinePaint);
      canvas.drawLine(hL, pt(rig.kneeL), cvLinePaint);
      canvas.drawLine(pt(rig.kneeL), pt(rig.ankleL), cvLinePaint);
      canvas.drawLine(hR, pt(rig.kneeR), cvLinePaint);
      canvas.drawLine(pt(rig.kneeR), pt(rig.ankleR), cvLinePaint);

      for (final focus in rig.cvFocusPoints) {
        final fp = pt(focus);
        canvas.drawCircle(
          fp,
          9,
          Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.28),
        );
        canvas.drawCircle(
          fp,
          4.5,
          Paint()..color = const Color(0xFF10B981),
        );
        canvas.drawCircle(
          fp,
          4.5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }

      if (rig.cvAngleLabel.isNotEmpty && rig.cvFocusPoints.isNotEmpty) {
        final anchor = pt(rig.cvFocusPoints.first).translate(14, -12);
        final tp = TextPainter(
          text: TextSpan(
            text: rig.cvAngleLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final pill = RRect.fromRectAndRadius(
          Rect.fromLTWH(anchor.dx, anchor.dy, tp.width + 12, tp.height + 6),
          const Radius.circular(6),
        );
        canvas.drawRRect(pill, Paint()..color = const Color(0xFFFF5C38));
        tp.paint(canvas, anchor.translate(6, 3));
      }
    }
  }

  void _drawDumbbell(Canvas canvas, Offset center) {
    final barPaint = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final platePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    final plateHighlight = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawLine(center.translate(-11, 0), center.translate(11, 0), barPaint);
    for (final dx in [-11.0, 11.0]) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(dx, 0), width: 6.5, height: 15),
        const Radius.circular(2.5),
      );
      canvas.drawRRect(r, platePaint);
      canvas.drawRRect(r, plateHighlight);
    }
  }

  _PoseRig _buildRig(String key, double t) {
    final shoulderSpan = isFemale ? 0.055 : 0.07;
    final hipSpan = isFemale ? 0.05 : 0.048;

    switch (key) {
      case 'Dumbbell_Squat':
      case 'Bodyweight_Squat':
        final hasDb = key == 'Dumbbell_Squat';
        final drop = _lerp(0.0, 0.13, t);
        final hipBack = _lerp(0.0, -0.06, t);
        final head = Offset(0.50 + hipBack * 0.3, 0.24 + drop);
        final neck = Offset(0.50 + hipBack * 0.3, 0.30 + drop);
        final sL = Offset(0.50 - shoulderSpan * 0.4, 0.32 + drop);
        final sR = Offset(0.50 + shoulderSpan * 0.4, 0.32 + drop);
        final hL = Offset(0.48 + hipBack, 0.50 + drop);
        final hR = Offset(0.52 + hipBack, 0.50 + drop);
        final kL = Offset(0.52, _lerp(0.62, 0.60, t));
        final kR = Offset(0.55, _lerp(0.62, 0.60, t));
        const aL = Offset(0.50, 0.74);
        const aR = Offset(0.54, 0.74);
        final eL = Offset(sL.dx, sL.dy + 0.10);
        final eR = Offset(sR.dx, sR.dy + 0.10);
        final wL = hasDb
            ? Offset(sL.dx + 0.01, sL.dy + 0.19)
            : Offset(_lerp(sL.dx, sL.dx + 0.11, t), _lerp(sL.dy + 0.18, sL.dy + 0.04, t));
        final wR = hasDb
            ? Offset(sR.dx + 0.01, sR.dy + 0.19)
            : Offset(_lerp(sR.dx, sR.dx + 0.11, t), _lerp(sR.dy + 0.18, sR.dy + 0.04, t));
        final deg = _lerp(165, 90, t).round();
        return _PoseRig(
          head: head,
          neck: neck,
          shoulderL: sL,
          shoulderR: sR,
          elbowL: eL,
          elbowR: eR,
          wristL: wL,
          wristR: wR,
          hipL: hL,
          hipR: hR,
          kneeL: kL,
          kneeR: kR,
          ankleL: aL,
          ankleR: aR,
          hasChair: true,
          hasDumbbells: hasDb,
          cvFocusPoints: [kR, hR, sR],
          cvAngleLabel: 'Tuhod: $deg°',
        );

      case 'Seated_Dumbbell_Press':
        const head = Offset(0.50, 0.25);
        const neck = Offset(0.50, 0.31);
        final sL = Offset(0.50 - shoulderSpan, 0.33);
        final sR = Offset(0.50 + shoulderSpan, 0.33);
        final hL = Offset(0.50 - hipSpan, 0.53);
        final hR = Offset(0.50 + hipSpan, 0.53);
        const kL = Offset(0.45, 0.60);
        const kR = Offset(0.55, 0.60);
        const aL = Offset(0.45, 0.74);
        const aR = Offset(0.55, 0.74);
        final eL = _lerpPt(Offset(sL.dx - 0.05, 0.38), Offset(sL.dx - 0.02, 0.24), t);
        final eR = _lerpPt(Offset(sR.dx + 0.05, 0.38), Offset(sR.dx + 0.02, 0.24), t);
        final wL = _lerpPt(Offset(sL.dx - 0.05, 0.31), Offset(sL.dx - 0.01, 0.14), t);
        final wR = _lerpPt(Offset(sR.dx + 0.05, 0.31), Offset(sR.dx + 0.01, 0.14), t);
        final deg = _lerp(75, 165, t).round();
        return _PoseRig(
          head: head,
          neck: neck,
          shoulderL: sL,
          shoulderR: sR,
          elbowL: eL,
          elbowR: eR,
          wristL: wL,
          wristR: wR,
          hipL: hL,
          hipR: hR,
          kneeL: kL,
          kneeR: kR,
          ankleL: aL,
          ankleR: aR,
          hasChair: true,
          hasDumbbells: true,
          cvFocusPoints: [sR, eR, wR],
          cvAngleLabel: 'Press: $deg°',
        );

      case 'Bent_Over_Two-Dumbbell_Row':
        const head = Offset(0.58, 0.30);
        const neck = Offset(0.55, 0.34);
        const sL = Offset(0.53, 0.36);
        const sR = Offset(0.55, 0.36);
        const hL = Offset(0.43, 0.49);
        const hR = Offset(0.45, 0.49);
        const kL = Offset(0.47, 0.62);
        const kR = Offset(0.49, 0.62);
        const aL = Offset(0.46, 0.74);
        const aR = Offset(0.48, 0.74);
        final eL = _lerpPt(const Offset(0.54, 0.48), const Offset(0.46, 0.39), t);
        final eR = _lerpPt(const Offset(0.56, 0.48), const Offset(0.48, 0.39), t);
        final wL = _lerpPt(const Offset(0.55, 0.58), const Offset(0.49, 0.46), t);
        final wR = _lerpPt(const Offset(0.57, 0.58), const Offset(0.51, 0.46), t);
        final deg = _lerp(160, 85, t).round();
        return _PoseRig(
          head: head,
          neck: neck,
          shoulderL: sL,
          shoulderR: sR,
          elbowL: eL,
          elbowR: eR,
          wristL: wL,
          wristR: wR,
          hipL: hL,
          hipR: hR,
          kneeL: kL,
          kneeR: kR,
          ankleL: aL,
          ankleR: aR,
          hasDumbbells: true,
          cvFocusPoints: [eR, hR, sR],
          cvAngleLabel: 'Siko: $deg°',
        );

      case 'Hammer_Curls':
      case 'Dumbbell_Bicep_Curl':
        const head = Offset(0.50, 0.22);
        const neck = Offset(0.50, 0.28);
        final sL = Offset(0.50 - shoulderSpan, 0.30);
        final sR = Offset(0.50 + shoulderSpan, 0.30);
        final eL = Offset(sL.dx - 0.01, 0.43);
        final eR = Offset(sR.dx + 0.01, 0.43);
        final wL = _lerpPt(Offset(eL.dx - 0.01, 0.55), Offset(sL.dx + 0.01, 0.33), t);
        final wR = _lerpPt(Offset(eR.dx + 0.01, 0.55), Offset(sR.dx - 0.01, 0.33), t);
        final hL = Offset(0.50 - hipSpan, 0.50);
        final hR = Offset(0.50 + hipSpan, 0.50);
        final kL = Offset(hL.dx, 0.62);
        final kR = Offset(hR.dx, 0.62);
        final aL = Offset(hL.dx, 0.74);
        final aR = Offset(hR.dx, 0.74);
        final deg = _lerp(155, 55, t).round();
        return _PoseRig(
          head: head,
          neck: neck,
          shoulderL: sL,
          shoulderR: sR,
          elbowL: eL,
          elbowR: eR,
          wristL: wL,
          wristR: wR,
          hipL: hL,
          hipR: hR,
          kneeL: kL,
          kneeR: kR,
          ankleL: aL,
          ankleR: aR,
          hasDumbbells: true,
          cvFocusPoints: [eL, eR, wR],
          cvAngleLabel: 'Curl: $deg°',
        );

      case 'Side_Lateral_Raise':
      case 'Arm_Circles':
        final hasDb = key == 'Side_Lateral_Raise';
        const head = Offset(0.50, 0.22);
        const neck = Offset(0.50, 0.28);
        final sL = Offset(0.50 - shoulderSpan, 0.30);
        final sR = Offset(0.50 + shoulderSpan, 0.30);
        final eL = _lerpPt(Offset(sL.dx - 0.02, 0.42), Offset(sL.dx - 0.10, 0.30), t);
        final eR = _lerpPt(Offset(sR.dx + 0.02, 0.42), Offset(sR.dx + 0.10, 0.30), t);
        final wL = _lerpPt(Offset(sL.dx - 0.03, 0.52), Offset(sL.dx - 0.19, 0.30), t);
        final wR = _lerpPt(Offset(sR.dx + 0.03, 0.52), Offset(sR.dx + 0.19, 0.30), t);
        final hL = Offset(0.50 - hipSpan, 0.50);
        final hR = Offset(0.50 + hipSpan, 0.50);
        final kL = Offset(hL.dx, 0.62);
        final kR = Offset(hR.dx, 0.62);
        final aL = Offset(hL.dx, 0.74);
        final aR = Offset(hR.dx, 0.74);
        final deg = _lerp(18, 90, t).round();
        return _PoseRig(
          head: head,
          neck: neck,
          shoulderL: sL,
          shoulderR: sR,
          elbowL: eL,
          elbowR: eR,
          wristL: wL,
          wristR: wR,
          hipL: hL,
          hipR: hR,
          kneeL: kL,
          kneeR: kR,
          ankleL: aL,
          ankleR: aR,
          hasDumbbells: hasDb,
          cvFocusPoints: [sL, sR, wR],
          cvAngleLabel: 'Balikat: $deg°',
        );

      case 'Front_Two-Dumbbell_Raise':
        const head = Offset(0.48, 0.22);
        const neck = Offset(0.48, 0.28);
        const sL = Offset(0.46, 0.30);
        const sR = Offset(0.50, 0.30);
        final eL = _lerpPt(const Offset(0.47, 0.42), const Offset(0.56, 0.30), t);
        final eR = _lerpPt(const Offset(0.51, 0.42), const Offset(0.60, 0.30), t);
        final wL = _lerpPt(const Offset(0.49, 0.52), const Offset(0.65, 0.30), t);
        final wR = _lerpPt(const Offset(0.53, 0.52), const Offset(0.69, 0.30), t);
        const hL = Offset(0.46, 0.50);
        const hR = Offset(0.50, 0.50);
        const kL = Offset(0.46, 0.62);
        const kR = Offset(0.50, 0.62);
        const aL = Offset(0.46, 0.74);
        const aR = Offset(0.50, 0.74);
        final deg = _lerp(15, 88, t).round();
        return _PoseRig(
          head: head,
          neck: neck,
          shoulderL: sL,
          shoulderR: sR,
          elbowL: eL,
          elbowR: eR,
          wristL: wL,
          wristR: wR,
          hipL: hL,
          hipR: hR,
          kneeL: kL,
          kneeR: kR,
          ankleL: aL,
          ankleR: aR,
          hasDumbbells: true,
          cvFocusPoints: [sR, eR, wR],
          cvAngleLabel: 'Harap: $deg°',
        );

      case 'Dumbbell_Lunges':
        final drop = _lerp(0.0, 0.11, t);
        final step = _lerp(0.0, 0.09, t);
        final head = Offset(0.50, 0.23 + drop);
        final neck = Offset(0.50, 0.29 + drop);
        final sL = Offset(0.48, 0.31 + drop);
        final sR = Offset(0.52, 0.31 + drop);
        final eL = Offset(0.48, 0.42 + drop);
        final eR = Offset(0.52, 0.42 + drop);
        final wL = Offset(0.48, 0.52 + drop);
        final wR = Offset(0.52, 0.52 + drop);
        final hL = Offset(0.48, 0.50 + drop);
        final hR = Offset(0.52, 0.50 + drop);
        final kL = Offset(0.48 - step * 0.7, _lerp(0.62, 0.69, t));
        final kR = Offset(0.52 + step, _lerp(0.62, 0.60, t));
        final aL = Offset(0.46 - step, 0.74);
        final aR = Offset(0.53 + step, 0.74);
        final deg = _lerp(165, 92, t).round();
        return _PoseRig(
          head: head,
          neck: neck,
          shoulderL: sL,
          shoulderR: sR,
          elbowL: eL,
          elbowR: eR,
          wristL: wL,
          wristR: wR,
          hipL: hL,
          hipR: hR,
          kneeL: kL,
          kneeR: kR,
          ankleL: aL,
          ankleR: aR,
          hasDumbbells: true,
          cvFocusPoints: [kR, kL, hR],
          cvAngleLabel: 'Lunge: $deg°',
        );

      case 'Incline_Push-Up':
        final lean = _lerp(0.0, 0.08, t);
        final head = Offset(0.52 + lean, 0.24);
        final neck = Offset(0.50 + lean, 0.30);
        final sL = Offset(0.49 + lean, 0.32);
        final sR = Offset(0.51 + lean, 0.32);
        final eL = _lerpPt(const Offset(0.61, 0.34), const Offset(0.62, 0.41), t);
        final eR = _lerpPt(const Offset(0.62, 0.34), const Offset(0.63, 0.41), t);
        const wL = Offset(0.71, 0.33);
        const wR = Offset(0.71, 0.34);
        final hL = Offset(0.45 + lean * 0.5, 0.51);
        final hR = Offset(0.47 + lean * 0.5, 0.51);
        final kL = Offset(0.42 + lean * 0.2, 0.63);
        final kR = Offset(0.44 + lean * 0.2, 0.63);
        const aL = Offset(0.40, 0.74);
        const aR = Offset(0.42, 0.74);
        final deg = _lerp(165, 92, t).round();
        return _PoseRig(
          head: head,
          neck: neck,
          shoulderL: sL,
          shoulderR: sR,
          elbowL: eL,
          elbowR: eR,
          wristL: wL,
          wristR: wR,
          hipL: hL,
          hipR: hR,
          kneeL: kL,
          kneeR: kR,
          ankleL: aL,
          ankleR: aR,
          hasWall: true,
          cvFocusPoints: [eR, sR, hR],
          cvAngleLabel: 'Push: $deg°',
        );

      case 'Butt_Lift_Bridge':
        final lift = _lerp(0.0, -0.11, t);
        const head = Offset(0.28, 0.70);
        const neck = Offset(0.33, 0.70);
        const sL = Offset(0.36, 0.70);
        const sR = Offset(0.38, 0.70);
        final hL = Offset(0.50, 0.70 + lift);
        final hR = Offset(0.52, 0.70 + lift);
        const kL = Offset(0.62, 0.55);
        const kR = Offset(0.64, 0.55);
        const aL = Offset(0.68, 0.73);
        const aR = Offset(0.70, 0.73);
        const eL = Offset(0.43, 0.72);
        const eR = Offset(0.45, 0.72);
        final wL = Offset(0.50, 0.68 + lift);
        final wR = Offset(0.52, 0.68 + lift);
        final deg = _lerp(115, 172, t).round();
        return _PoseRig(
          head: head,
          neck: neck,
          shoulderL: sL,
          shoulderR: sR,
          elbowL: eL,
          elbowR: eR,
          wristL: wL,
          wristR: wR,
          hipL: hL,
          hipR: hR,
          kneeL: kL,
          kneeR: kR,
          ankleL: aL,
          ankleR: aR,
          cvFocusPoints: [hR, kR, sR],
          cvAngleLabel: 'Bridge: $deg°',
        );

      case 'Step-up_with_Knee_Raise':
      case 'Front_Leg_Raises':
      case 'Side_Leg_Raises':
        final isSide = key == 'Side_Leg_Raises';
        const head = Offset(0.50, 0.22);
        const neck = Offset(0.50, 0.28);
        final sL = Offset(0.50 - shoulderSpan, 0.30);
        final sR = Offset(0.50 + shoulderSpan, 0.30);
        const eL = Offset(0.41, 0.42);
        const eR = Offset(0.58, 0.42);
        const wL = Offset(0.37, 0.52);
        const wR = Offset(0.60, 0.50);
        final hL = Offset(0.50 - hipSpan, 0.50);
        final hR = Offset(0.50 + hipSpan, 0.50);
        final kL = Offset(hL.dx, 0.62);
        final aL = Offset(hL.dx, 0.74);
        final kR = isSide
            ? _lerpPt(Offset(hR.dx, 0.62), Offset(hR.dx + 0.11, 0.56), t)
            : _lerpPt(Offset(hR.dx, 0.62), Offset(hR.dx + 0.05, 0.49), t);
        final aR = isSide
            ? _lerpPt(Offset(hR.dx, 0.74), Offset(hR.dx + 0.20, 0.62), t)
            : _lerpPt(Offset(hR.dx, 0.74), Offset(hR.dx + 0.06, 0.61), t);
        final deg = _lerp(170, 95, t).round();
        return _PoseRig(
          head: head,
          neck: neck,
          shoulderL: sL,
          shoulderR: sR,
          elbowL: eL,
          elbowR: eR,
          wristL: wL,
          wristR: wR,
          hipL: hL,
          hipR: hR,
          kneeL: kL,
          kneeR: kR,
          ankleL: aL,
          ankleR: aR,
          hasChair: true,
          cvFocusPoints: [hR, kR, aR],
          cvAngleLabel: 'Taas: $deg°',
        );

      case 'Walking_Treadmill':
        final swing = (t - 0.5) * 0.12;
        const head = Offset(0.50, 0.22);
        const neck = Offset(0.50, 0.28);
        const sL = Offset(0.48, 0.30);
        const sR = Offset(0.52, 0.30);
        final eL = Offset(0.50 - swing, 0.41);
        final eR = Offset(0.50 + swing, 0.41);
        final wL = Offset(0.50 - swing * 1.5, 0.49);
        final wR = Offset(0.50 + swing * 1.5, 0.49);
        const hL = Offset(0.49, 0.50);
        const hR = Offset(0.51, 0.50);
        final kL = Offset(0.50 + swing, 0.62);
        final kR = Offset(0.50 - swing, 0.62);
        final aL = Offset(0.50 + swing * 1.4, 0.74);
        final aR = Offset(0.50 - swing * 1.4, 0.74);
        return _PoseRig(
          head: head,
          neck: neck,
          shoulderL: sL,
          shoulderR: sR,
          elbowL: eL,
          elbowR: eR,
          wristL: wL,
          wristR: wR,
          hipL: hL,
          hipR: hR,
          kneeL: kL,
          kneeR: kR,
          ankleL: aL,
          ankleR: aR,
        );

      default:
        // Plank / Cat Stretch / Hamstring Stretch
        final arch = _lerp(0.0, -0.05, t);
        const head = Offset(0.66, 0.52);
        const neck = Offset(0.62, 0.53);
        const sL = Offset(0.59, 0.54);
        const sR = Offset(0.61, 0.54);
        const eL = Offset(0.60, 0.64);
        const eR = Offset(0.62, 0.64);
        const wL = Offset(0.63, 0.73);
        const wR = Offset(0.65, 0.73);
        final hL = Offset(0.44, 0.55 + arch);
        final hR = Offset(0.46, 0.55 + arch);
        const kL = Offset(0.39, 0.72);
        const kR = Offset(0.41, 0.72);
        const aL = Offset(0.31, 0.74);
        const aR = Offset(0.33, 0.74);
        return _PoseRig(
          head: head,
          neck: neck,
          shoulderL: sL,
          shoulderR: sR,
          elbowL: eL,
          elbowR: eR,
          wristL: wL,
          wristR: wR,
          hipL: hL,
          hipR: hR,
          kneeL: kL,
          kneeR: kR,
          ankleL: aL,
          ankleR: aR,
          cvFocusPoints: [sR, hR, kR],
          cvAngleLabel: 'Core Line',
        );
    }
  }

  @override
  bool shouldRepaint(covariant _HomeExerciseStudioPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.photoKey != photoKey ||
      oldDelegate.isFemale != isFemale ||
      oldDelegate.showCvOverlay != showCvOverlay;
}
