import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../root_tabs.dart';
import '../../utils/validators.dart';
import '../../utils/decimal_input_formatter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.fromSettings = false});
  final bool fromSettings; // back behavior control

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _loginKey = GlobalKey<FormState>();
  final _signupKey = GlobalKey<FormState>();

  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  bool _showPassLogin = false;
  bool _remember = false;

  final _suEmail = TextEditingController();
  final _suPassword = TextEditingController();
  final _suPassword2 = TextEditingController();
  final _suNickname = TextEditingController();
  final _suHeight = TextEditingController();
  final _suWeight = TextEditingController();
  bool _showPassSignup = false;
  bool _agree = false;

  double? _calcBmi() {
    final h = double.tryParse(_suHeight.text.replaceAll(',', '.'));
    final w = double.tryParse(_suWeight.text.replaceAll(',', '.'));
    if (h == null || w == null || h <= 0) return null;
    final m = h / 100.0;
    final bmi = w / (m * m);
    return double.parse(bmi.toStringAsFixed(1));
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _restoreRememberEmail();
  }

  Future<void> _restoreRememberEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getString('auth.rememberEmail');
    if (remembered != null) _loginEmail.text = remembered;
  }

  Future<bool> _onWillPop() async {
    if (widget.fromSettings) return true; // go back to previous screen
    // initial flow: Android back exits app
    return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('終了しますか？'),
            content: const Text('アプリを終了します'),
            actions: [
              TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('キャンセル')),
              TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('終了')),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Login / SignUp'),
          bottom: TabBar(controller: _tab, tabs: const [Tab(text: 'Login'), Tab(text: 'SignUp')]),
        ),
        body: TabBarView(
          controller: _tab,
          children: [
            _buildLogin(auth),
            _buildSignup(auth),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _suEmail.dispose();
    _suPassword.dispose();
    _suPassword2.dispose();
    _suNickname.dispose();
    _suHeight.dispose();
    _suWeight.dispose();
    super.dispose();
  }

  Widget _buildLogin(AuthProvider auth) {
    return AnimatedOpacity(
      opacity: auth.isLoading ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: auth.isLoading,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _loginKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _loginEmail,
                  decoration: const InputDecoration(labelText: 'メールアドレス'),
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _loginPassword,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    suffixIcon: IconButton(
                      icon: Icon(_showPassLogin ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showPassLogin = !_showPassLogin),
                    ),
                  ),
                  obscureText: !_showPassLogin,
                  validator: Validators.password,
                ),
                CheckboxListTile(
                  value: _remember,
                  onChanged: (v) async {
                    final nv = v ?? false;
                    setState(() => _remember = nv);
                    await auth.setRemember(nv);
                  },
                  title: const Text('ログイン状態を保持'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/forgot-password'),
                    child: const Text('パスワードをお忘れですか？'),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    if (!_loginKey.currentState!.validate()) return;
                    try {
                      await auth.login(email: _loginEmail.text.trim(), password: _loginPassword.text);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('auth.rememberEmail', _loginEmail.text.trim());
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ログインしました')));
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const RootTabs()),
                        (_) => false,
                      );
                    } catch (e) {
                      if (!mounted) return;
                      String msg = 'ネットワークエラー。再試行してください';
                      if (e is AuthError && e.status == 401) {
                        msg = 'メールまたはパスワードが違います';
                      } else if (e is AuthError) {
                        msg = e.message;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                    }
                  },
                  child: auth.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('ログイン'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignup(AuthProvider auth) {
    return AnimatedOpacity(
      opacity: auth.isLoading ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: auth.isLoading,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _signupKey,
            child: ListView(
              children: [
                TextFormField(controller: _suEmail, decoration: const InputDecoration(labelText: 'メールアドレス'), keyboardType: TextInputType.emailAddress, validator: Validators.email),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _suPassword,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    suffixIcon: IconButton(
                      icon: Icon(_showPassSignup ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _showPassSignup = !_showPassSignup),
                    ),
                  ),
                  obscureText: !_showPassSignup,
                  validator: Validators.password,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _suPassword2,
                  decoration: const InputDecoration(labelText: 'パスワード（確認）'),
                  obscureText: true,
                  validator: (v) {
                    final e = Validators.password(v);
                    if (e != null) return e;
                    if (v != _suPassword.text) return 'パスワードが一致しません';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _suNickname, decoration: const InputDecoration(labelText: 'ニックネーム'), validator: Validators.nickname),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(controller: _suHeight, decoration: const InputDecoration(labelText: '身長 (cm)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [OneDecimalTextInputFormatter()], validator: Validators.height, onChanged: (_) => setState(() {}))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _suWeight, decoration: const InputDecoration(labelText: '体重 (kg)'), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [OneDecimalTextInputFormatter()], validator: Validators.weight, onChanged: (_) => setState(() {}))),
                ]),
                const SizedBox(height: 8),
                if (_calcBmi() != null) Text('BMI: ${_calcBmi()!.toStringAsFixed(1)}'),
                CheckboxListTile(
                  value: _agree,
                  onChanged: (v) => setState(() => _agree = v ?? false),
                  title: const Text('規約に同意します'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: !_agree
                      ? null
                      : () async {
                          if (!_signupKey.currentState!.validate()) return;
                          try {
                            await auth.signup(
                              email: _suEmail.text.trim(),
                              password: _suPassword.text,
                              nickname: _suNickname.text.trim(),
                              heightCm: double.parse(_suHeight.text.replaceAll(',', '.')),
                              weightKg: double.parse(_suWeight.text.replaceAll(',', '.')),
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('登録が完了しました')));
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const RootTabs()),
                              (_) => false,
                            );
                          } catch (e) {
                            if (!mounted) return;
                            final msg = (e is AuthError) ? e.message : 'ネットワークエラー。再試行してください';
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                          }
                        },
                  child: auth.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('新規登録'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
