import 'package:flutter/foundation.dart';

class GoalProvider extends ChangeNotifier {
  int targetKcal = 200; // デフォルト
  int burnedKcal = 0;

  void setTarget(int kcal) {
    targetKcal = kcal;
    notifyListeners();
  }

  void addBurned(int kcal) {
    burnedKcal += kcal;
    notifyListeners();
  }

  double get achievedRate =>
      targetKcal == 0 ? 0 : (burnedKcal / targetKcal).clamp(0, 1).toDouble();

   void resetToday() {
    burnedKcal = 0;
    notifyListeners();
  }
}
