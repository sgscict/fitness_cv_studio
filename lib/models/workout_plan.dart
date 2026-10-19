import 'coach_exercise.dart';

enum MovementImpact { zeroImpact, lowImpact, moderateImpact, highImpact }

enum FitnessCategory {
  walking,
  mobility,
  jointFriendlyStrength,
  swimming,
  chairAssisted,
  balanceAndFallPrevention,
}

class WorkoutPlan {
  final String id;
  final String title;
  final String subtitle;
  final FitnessCategory category;
  final MovementImpact impact;
  final int durationMinutes;
  final int estimatedCalories;
  final String jointSafetyNote;
  final List<String> steps;
  final bool isCompleted;
  final bool isDumbbell;
  final CoachExercise? cvExercise;
  final String? demoPhotoKey;

  // Clinical Safety Attributes
  final bool causesValsalvaStrain;   // Straining with breath-holding (Contraindicated for hypertension)
  final bool causesInversion;        // Head below heart (Contraindicated for hypertension / glaucoma)
  final bool requiresDeepKneeFlexion;// Flexion > 90° (Contraindicated for knee osteoarthritis/pain)
  final bool isBalanceFocus;         // Fall-prevention for older adults
  final int rpeBorgScore;            // 1 to 10 scale (Safe target: 3-5 for stage 1-2 hypertension)

  const WorkoutPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.impact,
    required this.durationMinutes,
    required this.estimatedCalories,
    required this.jointSafetyNote,
    required this.steps,
    this.isCompleted = false,
    this.isDumbbell = false,
    this.cvExercise,
    this.demoPhotoKey,
    this.causesValsalvaStrain = false,
    this.causesInversion = false,
    this.requiresDeepKneeFlexion = false,
    this.isBalanceFocus = false,
    this.rpeBorgScore = 4,
  });

  /// Computer Vision is supported for all home exercises EXCEPT hard-to-monitor
  /// locomotion workouts like walking or jogging.
  bool get supportsComputerVision =>
      category != FitnessCategory.walking && cvExercise != null;

  // ---------------------------------------------------------------- Filipino
  // English fields stay the source of truth (logic, saved data, tests).
  // These return Filipino display text for known routines, else English.
  String titleFor(bool fil) => fil ? (_fil[id]?.title ?? title) : title;
  String subtitleFor(bool fil) => fil ? (_fil[id]?.subtitle ?? subtitle) : subtitle;
  String jointSafetyNoteFor(bool fil) => fil ? (_fil[id]?.note ?? jointSafetyNote) : jointSafetyNote;
  List<String> stepsFor(bool fil) {
    final s = fil ? _fil[id]?.steps : null;
    return s != null && s.length == steps.length ? s : steps;
  }

  /// Filipino step-by-step guide (always available in Filipino for workout cards).
  List<String> get filipinoSteps => _fil[id]?.steps ?? steps;

  /// Specific Computer Vision guidance in Filipino for this workout.
  String cvGuideFil() {
    if (!supportsComputerVision) {
      return '🚶 Walang Camera CV (Walking/Jogging): Mahirap bantayan sa nakapirming camera. Gamitin ang Workout Timer at Step Tracker habang pinapanatili ang talk-test pace.';
    }
    return _fil[id]?.cvGuide ??
        '🎯 AI Camera CV: Position yourself 2–3m in front of the camera for joint angle tracking and rep counting.';
  }

  /// Filipino title for a routine id (e.g. a saved session's workout id).
  static String? filipinoTitle(String id) => _fil[id]?.title;

  static const _fil = <String, ({String title, String subtitle, String note, String cvGuide, List<String> steps})>{
    'w1': (
      title: 'Zone-2 na Lakad sa Bahay / Barangay (Talk-Test Pace)',
      subtitle: 'Banayad na lakad na nagsusunog ng taba. Nasa ligtas na talk-test zone ang heart rate.',
      note: 'Patag na daan para protektado ang tuhod. Mababa ang impact.',
      cvGuide: '🚶 Walang Camera CV: Maglakad nang tuloy-tuloy gamit ang timer at step counter.',
      steps: [
        '5 min banayad na lakad sa sala o bakuran (warm-up)',
        '15 min tuloy-tuloy na lakad, kaya pang magkuwentuhan (RPE 3-4/10)',
        '5 min cooldown: mabagal na hinga sa ilong',
      ],
    ),
    'w2': (
      title: 'Home Wall Push-Up at Core Bracing',
      subtitle: 'Palakasin ang dibdib, balikat, tiyan at likod sa bahay gamit ang pader at upuan.',
      note: '100% suportado ang likod. Walang paghiga sa sahig o mabigat na strain.',
      cvGuide: '🎯 Gabay sa CV: Ilagay ang camera sa gilid o harap (2m). Binabantayan ng CV ang pagbaluktot ng siko (<125°) at pagtuwid (>155°) sa pader.',
      steps: [
        'Ilagay ang mga palad sa pader kapantay ng balikat (1 braso ang layo)',
        'Idikit ang core at dahan-dahang ilapit ang dibdib sa pader habang humihinga papasok',
        'Itulak pabalik habang bumubuga ng hininga (3 set ng 10 reps)',
      ],
    ),
    'w3': (
      title: 'Home Chair & Wall Squat (Ligtas na 90° Tuhod)',
      subtitle: 'Lakas ng hita at puwit sa bahay gamit ang upuan nang hindi nabibigatan ang tuhod.',
      note: 'May matibay na upuan sa likod. Huminto sa ~90° pag nadikit sa upuan.',
      cvGuide: '🎯 Gabay sa CV: Pumuwesto 2–3m sa harap ng camera. Binabantayan ng CV ang anggulo ng tuhod at balakang (~90°–115°) at nagbababala kung masyadong malalim.',
      steps: [
        'Tumayo sa harap ng matibay na upuan, paa ay shoulder-width ang buka',
        'Ibaba ang balakang hanggang maramdaman ang upuan (60°–90° ang tuhod)',
        'Huminga palabas habang tumatayo nang tuwid (8–10 reps)',
        'Magpahinga nang 45 segundo bawat set',
      ],
    ),
    'w4': (
      title: 'Home Chair Side Leg Raise at Balanse',
      subtitle: 'Pinapalakas ang balakang at bukung-bukong habang nakahawak sa upuan para iwas-tumba.',
      note: 'Katabi ang matibay na upuan sa bahay para may agad na suporta.',
      cvGuide: '🎯 Gabay sa CV: Humawak sa sandalan ng upuan. Binabantayan ng CV ang taas ng binti (>28°) at tuwid na tindig ng katawan.',
      steps: [
        'Humawak sa matibay na upuan at tumayo nang tuwid',
        'Dahan-dahang iangat ang isang binti sa gilid o harap (~30°–45°)',
        'I-hold nang 2 segundo habang normal ang paghinga (10 reps bawat binti)',
      ],
    ),
    'w5': (
      title: 'Home Upper-Body Mobility & Arm Circles',
      subtitle: 'Magaan na pag-ikot at pag-angat ng braso sa bahay para sa sirkulasyon at luwag ng balikat.',
      note: 'Walang bigat sa tuhod; puwedeng gawin nang nakatayo o nakaupo sa bahay.',
      cvGuide: '🎯 Gabay sa CV: Humarap sa camera (1.5–2.5m). Binabantayan ng CV ang pag-angat ng braso hanggang kapantay ng balikat (~70°+).',
      steps: [
        'Tumayo o umupo nang tuwid sa sala at i-relax ang leeg',
        'Itaas ang dalawang braso sa gilid hanggang kapantay ng balikat',
        'Gumawa ng mabagal na bilog at ibaba nang kontrolado habang humihinga palabas',
      ],
    ),
    'w_pinoy1': (
      title: 'Pinoy "Lakad-Lakad" Pagkatapos Kumain',
      subtitle: '15-min na banayad na lakad pagkatapos ng tanghalian o hapunan para bumaba ang blood sugar.',
      note: 'Patag na sala, bakuran, o kalye. Walang strain sa joints.',
      cvGuide: '🚶 Walang Camera CV: Maglakad nang banayad sa bahay o bakuran gamit ang timer.',
      steps: [
        '5 min relax na lakad para sa digestion',
        '8 min tuloy-tuloy na lakad, kaya pang magkuwentuhan (RPE 3-4/10)',
        '2 min cooldown na hinga sa ilong + 1 basong tubig',
      ],
    ),
    'w_pinoy2': (
      title: 'Home High-Knee March & Chair Mobility',
      subtitle: 'Ligtas na martsa at taas-tuhod sa bahay na may gabay ng upuan. Walang luhod sa sahig.',
      note: 'Katabi o nakaupo sa matibay na upuan. Walang risk na matumba.',
      cvGuide: '🎯 Gabay sa CV: Pumuwesto 2–3m sa harap ng camera. Binibilang ng CV ang salitang pag-angat ng kaliwa at kanang tuhod.',
      steps: [
        'Salitang iangat ang tuhod nang tuwid ang likod habang bumubuga ng hininga (12 bawat binti)',
        'Banayad na pag-ikot ng balikat at katawan',
        'Ankle pumps para sa sirkulasyon ng binti',
      ],
    ),
    'w_db1': (
      title: '🏋️ Home Dumbbell Seated Shoulder Press',
      subtitle: 'Palakasin ang balikat, tricep, at posture nang ligtas habang nakaupo sa upuan sa bahay.',
      note: 'Nakaupo nang tuwid sa matibay na upuan; huwag pigilan ang hininga habang nagtutulak.',
      cvGuide: '🎯 Gabay sa CV: Umupo 1.5–2.5m sa harap ng camera. Binabantayan ng CV ang pagtulak ng dumbbells mula balikat pataas ng ulo at pantay na siko.',
      steps: [
        'Umupo nang tuwid sa matibay na upuan sa bahay, hawak ang dumbbells kapantay ng balikat',
        'Itulak ang dumbbells pataas habang dahan-dahang bumubuga ng hininga (10 reps)',
        'Ibaba nang mabagal (2 segundo) pabalik sa balikat nang hindi binabagsak',
        'Ulitin nang 3 set na may 60 segundong pahinga',
      ],
    ),
    'w_db2': (
      title: '🏋️ Home Dumbbell Chair Squat (Lower Body)',
      subtitle: 'Lakas ng hita, glutes, at tuhod sa bahay gamit ang pares ng dumbbells at upuan sa likod.',
      note: 'Hawakan ang dumbbells sa tagiliran; huminto pag nadikit sa upuan (~90° tuhod).',
      cvGuide: '🎯 Gabay sa CV: Pumuwesto 2–3m sa harap ng camera. Binabantayan ng CV ang ~90° anggulo ng tuhod habang hawak ang dumbbells sa gilid.',
      steps: [
        'Tumayo sa harap ng upuan, hawak ang dumbbells sa magkabilang gilid ng hita',
        'Panatilihing tuwid ang dibdib at ibaba ang balakang hanggang maramdaman ang upuan (~90°)',
        'Bumuga ng hininga habang tumatayo nang matatag sa sakong (3 set × 10 reps)',
        'Ibaba ang dumbbells at magpahinga nang 60 segundo',
      ],
    ),
    'w_db3': (
      title: '🏋️ Home Dumbbell Bent-Over Row (Likod at Posture)',
      subtitle: 'Pinapalakas ang upper back, lats, at likod ng balikat sa bahay para iwas-kuba.',
      note: 'Yumuko mula sa balakang nang ~45° na diretso ang likod; puwedeng itukod ang 1 kamay sa upuan.',
      cvGuide: '🎯 Gabay sa CV: Pumuwesto nang bahagyang naka-anggulo sa camera (2m). Binabantayan ng CV ang paghila ng siko at dumbbell papunta sa tadyang.',
      steps: [
        'Hawakan ang dumbbells, bahagyang ibaluktot ang tuhod at yumuko nang 45° na tuwid ang likod',
        'Hilahin ang dumbbells papunta sa ibabang tadyang at ipitin ang likod nang 1 segundo',
        'Dahan-dahang ibaba ang braso habang humihinga papasok (3 set × 10 reps)',
      ],
    ),
    'w_db4': (
      title: '🏋️ Home Dumbbell Hammer Curl & Side Raise',
      subtitle: 'Toning at lakas ng braso (biceps), pulso, at gilid ng balikat sa loob ng bahay.',
      note: 'Idikit ang siko sa tagiliran; huwag ihagis o i-swing ang likod.',
      cvGuide: '🎯 Gabay sa CV: Humarap sa camera (1.5–2.5m). Binabantayan ng CV ang buong pagbaluktot ng siko (<68°) at pagbaba (>142°) nang walang body swing.',
      steps: [
        'Tumayo o umupo nang tuwid, nakaharap sa isa\'t isa ang palad na may hawak na dumbbell',
        'I-curl ang dumbbells papunta sa balikat habang bumubuga ng hininga (3 set × 12 reps)',
        'Isunod ang magaan na Dumbbell Side Raise hanggang kapantay ng balikat (2 set × 10 reps)',
      ],
    ),
    'w_db5': (
      title: '🏋️ Home Dumbbell Front Raise & Step Lunge Circuit',
      subtitle: 'Kumpletong home dumbbell workout para sa harap ng balikat, core, hita, at balanse.',
      note: 'Humakbang nang kontrolado (~90° tuhod) at huminto sa pantay-balikat sa front raise.',
      cvGuide: '🎯 Gabay sa CV: Pumuwesto 2–3m sa harap ng camera. Binabantayan ng CV ang pag-angat ng dumbbell sa harap hanggang balikat at ang tuwid ng katawan.',
      steps: [
        'Hawak ang dumbbells sa harap ng hita, dahan-dahang itaas hanggang pantay-balikat (10 reps)',
        'Humakbang pa-harap para sa Dumbbell Step Lunge (~90° tuhod, 8 reps bawat binti)',
        'Tapusin sa home glute bridge sa mat (2 set × 10 reps)',
      ],
    ),
    'w_unsafe1': (
      title: 'Max-Effort Overhead Barbell Press',
      subtitle: 'Mabigat na overhead press na naka-brace ang core.',
      note: 'Mataas na pressure sa gulugod at ugat.',
      cvGuide: '',
      steps: ['Mabigat na overhead lockout na pinipigil ang hininga (Valsalva)'],
    ),
    'w_unsafe2': (
      title: 'High-Impact Plyometric Jump Squats',
      subtitle: 'Pasabog na jump squat na malalim ang baba ng tuhod.',
      note: 'Matinding impact sa tuhod sa paglapag.',
      cvGuide: '',
      steps: ['Malalim na squat lampas 110°, pasabog na talon, matigas na lapag'],
    ),
  };

  WorkoutPlan copyWith({
    bool? isCompleted,
  }) {
    return WorkoutPlan(
      id: id,
      title: title,
      subtitle: subtitle,
      category: category,
      impact: impact,
      durationMinutes: durationMinutes,
      estimatedCalories: estimatedCalories,
      jointSafetyNote: jointSafetyNote,
      steps: steps,
      isCompleted: isCompleted ?? this.isCompleted,
      isDumbbell: isDumbbell,
      cvExercise: cvExercise,
      demoPhotoKey: demoPhotoKey,
      causesValsalvaStrain: causesValsalvaStrain,
      causesInversion: causesInversion,
      requiresDeepKneeFlexion: requiresDeepKneeFlexion,
      isBalanceFocus: isBalanceFocus,
      rpeBorgScore: rpeBorgScore,
    );
  }

  static const List<WorkoutPlan> defaultCatalog = [
    WorkoutPlan(
      id: 'w_db1',
      title: 'Home Dumbbell Seated Shoulder Press',
      subtitle: 'Strengthen shoulders, triceps, and upper posture safely while seated on a chair at home.',
      category: FitnessCategory.chairAssisted,
      impact: MovementImpact.zeroImpact,
      durationMinutes: 15,
      estimatedCalories: 95,
      jointSafetyNote: 'Sit tall on a sturdy chair; exhale on every press without holding breath.',
      steps: [
        'Sit upright on a sturdy chair, holding dumbbells at shoulder height',
        'Press dumbbells upward while slowly exhaling (10 reps)',
        'Lower controlled (2 seconds) back to shoulder level',
        'Repeat for 3 sets with 60 seconds rest between sets',
      ],
      isDumbbell: true,
      cvExercise: CoachExercise.shoulderPress,
      demoPhotoKey: 'Seated_Dumbbell_Press',
      rpeBorgScore: 4,
    ),
    WorkoutPlan(
      id: 'w_db2',
      title: 'Home Dumbbell Chair Squat (Lower Body)',
      subtitle: 'Build thigh, glute, and knee stability at home holding dumbbells with a chair behind you.',
      category: FitnessCategory.jointFriendlyStrength,
      impact: MovementImpact.lowImpact,
      durationMinutes: 18,
      estimatedCalories: 125,
      jointSafetyNote: 'Hold dumbbells at sides; stop at ~90° when hips touch the chair seat.',
      steps: [
        'Stand in front of chair, holding dumbbells at your sides',
        'Keep chest tall and hinge hips back until you tap the chair (~90° knee angle)',
        'Drive through heels to stand upright while exhaling (3 sets × 10 reps)',
        'Rest 60 seconds between sets',
      ],
      isDumbbell: true,
      cvExercise: CoachExercise.dumbbellSquat,
      demoPhotoKey: 'Dumbbell_Squat',
      rpeBorgScore: 4,
    ),
    WorkoutPlan(
      id: 'w_db3',
      title: 'Home Dumbbell Bent-Over Row (Back & Posture)',
      subtitle: 'Strengthen upper back, lats, and rear shoulders at home to prevent rounded posture.',
      category: FitnessCategory.jointFriendlyStrength,
      impact: MovementImpact.zeroImpact,
      durationMinutes: 15,
      estimatedCalories: 105,
      jointSafetyNote: 'Hinge ~45° from hips with a flat back; support one hand on a chair if needed.',
      steps: [
        'Hold dumbbells, soft knee bend, hinge 45° from hips with a flat spine',
        'Pull dumbbells toward lower ribcage and squeeze shoulder blades for 1 second',
        'Lower dumbbells with control while inhaling (3 sets × 10 reps)',
      ],
      isDumbbell: true,
      cvExercise: CoachExercise.dumbbellRow,
      demoPhotoKey: 'Bent_Over_Two-Dumbbell_Row',
      rpeBorgScore: 4,
    ),
    WorkoutPlan(
      id: 'w_db4',
      title: 'Home Dumbbell Hammer Curl & Side Raise',
      subtitle: 'Tone and strengthen biceps, forearms, and lateral shoulders at home.',
      category: FitnessCategory.chairAssisted,
      impact: MovementImpact.zeroImpact,
      durationMinutes: 14,
      estimatedCalories: 85,
      jointSafetyNote: 'Keep elbows pinned at your sides; avoid swinging your lower back.',
      steps: [
        'Stand or sit tall, palms facing inward holding dumbbells',
        'Curl dumbbells up toward shoulders while exhaling (3 sets × 12 reps)',
        'Follow with light Dumbbell Side Raises up to shoulder level (2 sets × 10 reps)',
      ],
      isDumbbell: true,
      cvExercise: CoachExercise.bicepCurl,
      demoPhotoKey: 'Hammer_Curls',
      rpeBorgScore: 3,
    ),
    WorkoutPlan(
      id: 'w_db5',
      title: 'Home Dumbbell Front Raise & Step Lunge Circuit',
      subtitle: 'Full-body home dumbbell routine for anterior shoulders, core, legs, and balance.',
      category: FitnessCategory.balanceAndFallPrevention,
      impact: MovementImpact.lowImpact,
      durationMinutes: 20,
      estimatedCalories: 135,
      jointSafetyNote: 'Step with controlled ~90° knee bend and stop at shoulder height on raises.',
      steps: [
        'Holding dumbbells in front of thighs, raise them smoothly to shoulder height (10 reps)',
        'Step forward into a gentle lunge (~90° knees, 8 reps each leg)',
        'Finish with a floor glute bridge on a mat (2 sets × 10 reps)',
      ],
      isDumbbell: true,
      cvExercise: CoachExercise.frontRaise,
      demoPhotoKey: 'Front_Two-Dumbbell_Raise',
      isBalanceFocus: true,
      rpeBorgScore: 4,
    ),
    WorkoutPlan(
      id: 'w2',
      title: 'Home Wall Push-Up & Core Bracing',
      subtitle: 'Build chest, shoulder, and core stability without lying on the floor.',
      category: FitnessCategory.chairAssisted,
      impact: MovementImpact.zeroImpact,
      durationMinutes: 15,
      estimatedCalories: 65,
      jointSafetyNote: '100% spine-supported. No floor-lying or heavy back strain.',
      steps: [
        'Place hands on wall at shoulder height, step back one arm length',
        'Brace core and lower chest toward wall (elbow angle < 125°)',
        'Press firmly back while exhaling (3 sets of 10 reps)',
      ],
      isDumbbell: false,
      cvExercise: CoachExercise.wallPushUp,
      demoPhotoKey: 'Incline_Push-Up',
      rpeBorgScore: 3,
    ),
    WorkoutPlan(
      id: 'w3',
      title: 'Wall-Supported Squats (Max 90° Safe Threshold)',
      subtitle: 'Quadriceps and glute strength without patellofemoral cartilage overload.',
      category: FitnessCategory.jointFriendlyStrength,
      impact: MovementImpact.zeroImpact,
      durationMinutes: 12,
      estimatedCalories: 75,
      jointSafetyNote: 'Back firmly supported against wall. Thighs stop before 90° parallel.',
      steps: [
        'Feet shoulder-width apart, 2 feet away from wall',
        'Slide down until knees reach comfortable 60°-80° angle',
        'Hold for 3-5 seconds while breathing smoothly',
        'Push back up through heels (3 sets × 8-10 reps)',
      ],
      isDumbbell: false,
      cvExercise: CoachExercise.squat,
      demoPhotoKey: 'Bodyweight_Squat',
      rpeBorgScore: 4,
    ),
    WorkoutPlan(
      id: 'w4',
      title: 'Home Chair Side Leg Raise & Balance',
      subtitle: 'Enhance lateral hip strength and ankle proprioception for fall prevention.',
      category: FitnessCategory.balanceAndFallPrevention,
      impact: MovementImpact.zeroImpact,
      durationMinutes: 10,
      estimatedCalories: 45,
      jointSafetyNote: 'Performed alongside sturdy chair for instant safety support.',
      steps: [
        'Hold chair back with one hand, stand tall',
        'Raise outer leg sideways 30°-45° with toes pointing straight ahead',
        'Hold for 2 seconds and lower smoothly (10 reps each leg)',
      ],
      isDumbbell: false,
      cvExercise: CoachExercise.legRaise,
      demoPhotoKey: 'Side_Leg_Raises',
      isBalanceFocus: true,
      rpeBorgScore: 2,
    ),
    WorkoutPlan(
      id: 'w5',
      title: 'Upper-Body Mobility & Arm Circles',
      subtitle: 'Gentle shoulder circulation and thoracic spine posture reset.',
      category: FitnessCategory.mobility,
      impact: MovementImpact.zeroImpact,
      durationMinutes: 10,
      estimatedCalories: 35,
      jointSafetyNote: 'Zero weight on knees; can be done seated or standing.',
      steps: [
        'Stand tall and relax neck and shoulders',
        'Raise arms out to sides to shoulder height (~90°)',
        'Perform slow controlled arm circles (10 clockwise, 10 counterclockwise)',
      ],
      isDumbbell: false,
      cvExercise: CoachExercise.armRaise,
      demoPhotoKey: 'Arm_Circles',
      rpeBorgScore: 2,
    ),
    WorkoutPlan(
      id: 'w_pinoy1',
      title: 'Post-Meal "Lakad-Lakad" Digestive Walk',
      subtitle: '15-min gentle conversational walk to naturally stabilize postprandial glucose.',
      category: FitnessCategory.walking,
      impact: MovementImpact.lowImpact,
      durationMinutes: 15,
      estimatedCalories: 75,
      jointSafetyNote: 'Flat indoor or outdoor surface. Low ground impact.',
      steps: [
        '5 min relaxed stroll to settle digestion',
        '8 min continuous conversational pace (RPE 3-4/10)',
        '2 min nasal breathing cooldown + 1 glass of water',
      ],
      isDumbbell: false,
      cvExercise: null,
      demoPhotoKey: 'Walking_Treadmill',
      rpeBorgScore: 3,
    ),
    WorkoutPlan(
      id: 'w_pinoy2',
      title: 'High-Knee March & Chair Mobility',
      subtitle: 'Gentle marching and joint mobility for active longevity and circulation.',
      category: FitnessCategory.chairAssisted,
      impact: MovementImpact.zeroImpact,
      durationMinutes: 12,
      estimatedCalories: 55,
      jointSafetyNote: 'Chair adjacent for balance support. Zero floor-kneeling.',
      steps: [
        'Alternate marching knees up toward hip height with tall spine (12 each leg)',
        'Gentle seated shoulder rolls and deep diaphragmatic breaths',
        'Ankle pumps and circles for lower leg blood flow',
      ],
      isDumbbell: false,
      cvExercise: CoachExercise.marching,
      demoPhotoKey: 'Step-up_with_Knee_Raise',
      isBalanceFocus: true,
      rpeBorgScore: 3,
    ),
  ];
}
