class Validators {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'メールアドレスを入力してください';
    if (s.length > 255) return '255文字以内で入力してください';
    if (!_email.hasMatch(s)) return 'メールアドレスの形式が不正です';
    return null;
  }

  static String? password(String? v) {
    final s = (v ?? '');
    if (s.isEmpty) return 'パスワードを入力してください';
    if (s.length < 8 || s.length > 64) return '8〜64文字で入力してください';
    if (s.contains(RegExp(r'\s'))) return '空白は使用できません';
    return null;
  }

  static String? nickname(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'ニックネームを入力してください';
    if (s.runes.any((r) => _isControlOrEmoji(r))) return '絵文字・制御文字は使用できません';
    if (s.length < 2 || s.length > 20) return '2〜20文字で入力してください';
    return null;
  }

  static bool _isControlOrEmoji(int rune) {
    if (rune <= 0x1F || (rune >= 0x7F && rune <= 0x9F)) return true; // control
    // Basic emoji ranges (rough)
    if ((rune >= 0x1F300 && rune <= 0x1FAFF) || (rune >= 0x2600 && rune <= 0x27BF)) return true;
    return false;
  }

  static String? height(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return '身長を入力してください';
    final d = double.tryParse(s.replaceAll(',', '.'));
    if (d == null) return '数値で入力してください';
    if (d < 100 || d > 250) return '100〜250の範囲で入力してください';
    if (!_oneDecimal(s)) return '小数は1桁までです';
    return null;
  }

  static String? weight(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return '体重を入力してください';
    final d = double.tryParse(s.replaceAll(',', '.'));
    if (d == null) return '数値で入力してください';
    if (d < 30 || d > 200) return '30〜200の範囲で入力してください';
    if (!_oneDecimal(s)) return '小数は1桁までです';
    return null;
  }

  static bool _oneDecimal(String s) => RegExp(r'^\d{1,3}(?:\.\d)?$').hasMatch(s);
}

