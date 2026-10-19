enum BiologicalSex { female, male }

/// Standalone user fitness profile for configuring kinematic limits and calorie estimation.
class UserFitnessProfile {
  final double weightKg;
  final int age;
  final BiologicalSex sex;
  final bool hasKneeSensitivity;
  final bool hasHypertension;
  final double targetSquatMinAngle;
  final double targetCurlMinAngle;

  const UserFitnessProfile({
    this.weightKg = 68.0,
    this.age = 30,
    this.sex = BiologicalSex.female,
    this.hasKneeSensitivity = false,
    this.hasHypertension = false,
    this.targetSquatMinAngle = 85.0,
    this.targetCurlMinAngle = 65.0,
  });

  UserFitnessProfile copyWith({
    double? weightKg,
    int? age,
    BiologicalSex? sex,
    bool? hasKneeSensitivity,
    bool? hasHypertension,
    double? targetSquatMinAngle,
    double? targetCurlMinAngle,
  }) {
    return UserFitnessProfile(
      weightKg: weightKg ?? this.weightKg,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      hasKneeSensitivity: hasKneeSensitivity ?? this.hasKneeSensitivity,
      hasHypertension: hasHypertension ?? this.hasHypertension,
      targetSquatMinAngle: targetSquatMinAngle ?? this.targetSquatMinAngle,
      targetCurlMinAngle: targetCurlMinAngle ?? this.targetCurlMinAngle,
    );
  }
}
