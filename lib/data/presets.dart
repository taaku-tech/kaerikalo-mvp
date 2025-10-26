class FoodPreset { final String id; final String name; final int kcal;
  const FoodPreset({required this.id, required this.name, required this.kcal}); }

class MicroAction { final String id; final String name; final String unitLabel;
  final double kcalPerUnit; final String exampleText;
  const MicroAction({required this.id,required this.name,required this.unitLabel,
    required this.kcalPerUnit,required this.exampleText}); }

const defaultFoods = <FoodPreset>[
  FoodPreset(id: 'cake', name: 'ショートケーキ', kcal: 300),
  FoodPreset(id: 'latte', name: 'カフェラテ', kcal: 120),
  FoodPreset(id: 'karaage', name: '唐揚げ(1個)', kcal: 70),
  FoodPreset(id: 'chips', name: 'ポテチ小袋', kcal: 160),
];

const microActions = <MicroAction>[
  MicroAction(id: 'walk_fast', name: '早歩き', unitLabel: '+1分', kcalPerUnit: 5, exampleText: '60秒 ⇒ +5kcal'),
  MicroAction(id: 'stairs', name: '階段', unitLabel: '+30段', kcalPerUnit: 6, exampleText: '30段 ⇒ +6kcal'),
  MicroAction(id: 'high_knee', name: 'もも上げ', unitLabel: '+10回', kcalPerUnit: 3, exampleText: '10回 ⇒ +3kcal'),
  MicroAction(id: 'calf_raise', name: 'かかと上げ', unitLabel: '+10回', kcalPerUnit: 2, exampleText: '10回 ⇒ +2kcal'),
];
