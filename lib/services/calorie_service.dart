
class CalorieService {
  static const double baselineWeightKg = 60.0;

  // Per-unit kcal at baseline (60kg)
  static const double detourPerMinuteKcal = 4.0; // 4 kcal / min
  static const double fastWalkPerMinuteKcal = 5.0; // 5 kcal / min
  static const double stairsPerStepKcal = 6.0 / 30.0; // 6 kcal / 30 steps
  static const double highKneePerRepKcal = 3.0 / 10.0; // 3 kcal / 10 reps
  static const double calfRaisePerRepKcal = 2.0 / 10.0; // 2 kcal / 10 reps

  static double _factor(double? weightKg) {
    final w = (weightKg ?? baselineWeightKg).clamp(30.0, 200.0);
    return w / baselineWeightKg;
  }

  // Units -> kcal (weight adjusted)
  static double detourMinutesToKcal(int minutes, {double? weightKg}) =>
      minutes * detourPerMinuteKcal * _factor(weightKg);

  static double fastWalkSecondsToKcal(int seconds, {double? weightKg}) =>
      (seconds / 60.0) * fastWalkPerMinuteKcal * _factor(weightKg);

  static double stairsStepsToKcal(int steps, {double? weightKg}) =>
      steps * stairsPerStepKcal * _factor(weightKg);

  static double highKneeRepsToKcal(int reps, {double? weightKg}) =>
      reps * highKneePerRepKcal * _factor(weightKg);

  static double calfRaiseRepsToKcal(int reps, {double? weightKg}) =>
      reps * calfRaisePerRepKcal * _factor(weightKg);

  // kcal -> Units (weight adjusted)
  static int kcalToDetourMinutes(double kcal, {double? weightKg}) =>
      (kcal / (detourPerMinuteKcal * _factor(weightKg))).round();

  static int kcalToFastWalkSeconds(double kcal, {double? weightKg}) =>
      ((kcal / (fastWalkPerMinuteKcal * _factor(weightKg))) * 60.0).round();

  static int kcalToStairsSteps(double kcal, {double? weightKg}) =>
      (kcal / (stairsPerStepKcal * _factor(weightKg))).round();

  static int kcalToHighKneeReps(double kcal, {double? weightKg}) =>
      (kcal / (highKneePerRepKcal * _factor(weightKg))).round();

  static int kcalToCalfRaiseReps(double kcal, {double? weightKg}) =>
      (kcal / (calfRaisePerRepKcal * _factor(weightKg))).round();
}

