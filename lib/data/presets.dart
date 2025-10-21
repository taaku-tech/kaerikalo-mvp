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
  MicroAction(id: 'walk_fast', name: '早歩き', unitLabel: '分', kcalPerUnit: 5, exampleText: '次の横断歩道まで90秒'),
  MicroAction(id: 'stairs', name: '階段', unitLabel: '往復', kcalPerUnit: 12, exampleText: '20段×2往復'),
  MicroAction(id: 'high_knee', name: 'もも上げ', unitLabel: '回', kcalPerUnit: 0.8, exampleText: '信号待ちで10回'),
  MicroAction(id: 'calf_raise', name: 'かかと上げ', unitLabel: '回', kcalPerUnit: 0.6, exampleText: '信号待ちで15回'),
];
