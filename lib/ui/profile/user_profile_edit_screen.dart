import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../services/calorie_service.dart';
import '../../utils/decimal_input_formatter.dart';

class UserProfileEditScreen extends StatefulWidget {
  const UserProfileEditScreen({super.key});

  @override
  State<UserProfileEditScreen> createState() => _UserProfileEditScreenState();
}

class _UserProfileEditScreenState extends State<UserProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AuthProvider>().profile;
    if (p != null) {
      _nickname.text = p.nickname;
      _height.text = p.heightCm.toStringAsFixed((p.heightCm * 10) % 10 == 0 ? 0 : 1);
      _weight.text = p.weightKg.toStringAsFixed((p.weightKg * 10) % 10 == 0 ? 0 : 1);
    }
    for (final c in [_nickname, _height, _weight]) {
      c.addListener(() => setState(() => _dirty = true));
    }
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('変更を破棄しますか？'),
            content: const Text('未保存の変更があります'),
            actions: [
              TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('キャンセル')),
              TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('破棄')),
            ],
          ),
        ) ??
        false;
  }

  double? _calcBmi() {
    final h = double.tryParse(_height.text.replaceAll(',', '.'));
    final w = double.tryParse(_weight.text.replaceAll(',', '.'));
    if (h == null || w == null || h <= 0) return null;
    final m = h / 100.0;
    final bmi = w / (m * m);
    return double.parse(bmi.toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = auth.profile;
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const SizedBox.shrink();
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final ok = await _confirmLeave();
        if (!context.mounted) return;
        if (ok) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ユーザー情報編集'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final ok = await _confirmLeave();
              if (!context.mounted) return;
              if (ok) Navigator.of(context).pop();
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  initialValue: p?.email ?? '',
                  enabled: false,
                  decoration: const InputDecoration(labelText: 'メールアドレス'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nickname,
                  decoration: const InputDecoration(labelText: 'ニックネーム'),
                  validator: Validators.nickname,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _height,
                      decoration: const InputDecoration(labelText: '身長 (cm)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [OneDecimalTextInputFormatter()],
                      validator: Validators.height,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weight,
                      decoration: const InputDecoration(labelText: '体重 (kg)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [OneDecimalTextInputFormatter()],
                      validator: Validators.weight,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                if (_calcBmi() != null) Text('BMI: ${_calcBmi()!.toStringAsFixed(1)}'),
                const SizedBox(height: 16),
                Builder(builder: (context) {
                  final w = double.tryParse(_weight.text.replaceAll(',', '.'));
                  if (w == null || w <= 0) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('消費カロリー目安（${w.toStringAsFixed(1)}kg の場合）',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                          '・遠回り（1分）: ${CalorieService.detourMinutesToKcal(1, weightKg: w).toStringAsFixed(1)} kcal'),
                      Text(
                          '・早歩き（1分）: ${CalorieService.fastWalkSecondsToKcal(60, weightKg: w).toStringAsFixed(1)} kcal'),
                      Text(
                          '・階段（30段）: ${CalorieService.stairsStepsToKcal(30, weightKg: w).toStringAsFixed(1)} kcal'),
                      Text(
                          '・もも上げ（10回）: ${CalorieService.highKneeRepsToKcal(10, weightKg: w).toStringAsFixed(1)} kcal'),
                      Text(
                          '・かかと上げ（10回）: ${CalorieService.calfRaiseRepsToKcal(10, weightKg: w).toStringAsFixed(1)} kcal'),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final ok = await _confirmLeave();
                        if (!context.mounted) return;
                        if (ok) Navigator.of(context).pop();
                      },
                      child: const Text('キャンセル'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              try {
                                await auth.updateProfile(
                                  nickname: _nickname.text.trim(),
                                  heightCm: double.parse(_height.text.replaceAll(',', '.')),
                                  weightKg: double.parse(_weight.text.replaceAll(',', '.')),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存しました')));
                                Navigator.of(context).pop();
                              } catch (_) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ネットワークエラー。再試行してください')));
                              }
                            },
                      child: auth.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('保存'),
                    ),
                  ),
                ])
              ],
            ),
          ),
        ),
      ),
    );
  }
}
