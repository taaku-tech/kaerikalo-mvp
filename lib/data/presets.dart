import '../models/food_preset.dart';
import '../models/micro_action.dart';
import '../models/action_unit.dart';

const defaultFoods = <FoodPreset>[
  FoodPreset(id: 'karaage', name: '唐揚げ(1個)', kcal: 60),
  FoodPreset(id: 'latte', name: 'カフェラテ', kcal: 120),
  FoodPreset(id: 'cake', name: '焼き餃子（4個）', kcal: 180),
  FoodPreset(id: 'chips', name: 'ポテチ（50g）', kcal: 270),
];

const microActions = <MicroAction>[
  MicroAction(
    id: 'walk_fast',
    name: '早歩き',
    unit: ActionUnit.min,
    kcalPerUnit: 5,
    exampleText: '60秒 ⇒ +5kcal',
  ),
  MicroAction(
    id: 'stairs',
    name: '階段',
    unit: ActionUnit.flight,
    kcalPerUnit: 6,
    exampleText: '30段 ⇒ +6kcal',
  ),
  MicroAction(
    id: 'high_knee',
    name: 'もも上げ',
    unit: ActionUnit.rep,
    kcalPerUnit: 3,
    exampleText: '10回 ⇒ +3kcal',
  ),
  MicroAction(
    id: 'calf_raise',
    name: 'かかと上げ',
    unit: ActionUnit.rep,
    kcalPerUnit: 2,
    exampleText: '10回 ⇒ +2kcal',
  ),
];
