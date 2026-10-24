// Người phụ trách: Khôi
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _passwordCtrl,
      _confirmCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final error = await context.read<AuthProvider>().register(
          name: _nameCtrl.text,
          email: _emailCtrl.text,
          phone: _phoneCtrl.text,
          password: _passwordCtrl.text,
        );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }
    // Đăng ký xong là đã đăng nhập -> đóng màn này, AuthGate hiện MainShell
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Đăng ký thành công, chào mừng bạn!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Điền thông tin để bắt đầu đặt vé',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _nameCtrl,
                  label: 'Họ và tên',
                  icon: Icons.person_outline,
                  validator: Validators.name,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _phoneCtrl,
                  label: 'Số điện thoại',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _passwordCtrl,
                  label: 'Mật khẩu (≥ 6 ký tự, có chữ và số)',
                  icon: Icons.lock_outline,
                  obscureText: _obscure,
                  validator: Validators.newPassword,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _confirmCtrl,
                  label: 'Nhập lại mật khẩu',
                  icon: Icons.lock_reset,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  validator:
                      Validators.confirmPassword(() => _passwordCtrl.text),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('ĐĂNG KÝ'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
