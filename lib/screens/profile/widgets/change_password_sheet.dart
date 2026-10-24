// Người phụ trách: Khôi - form đổi mật khẩu
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';
import 'auth_text_field.dart';

class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final error = await context
        .read<AuthProvider>()
        .changePassword(_currentCtrl.text, _newCtrl.text);
    if (!mounted) return;
    setState(() => _saving = false);
    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Đổi mật khẩu thành công')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đổi mật khẩu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _currentCtrl,
              label: 'Mật khẩu hiện tại',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: Validators.loginPassword,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _newCtrl,
              label: 'Mật khẩu mới',
              icon: Icons.lock_reset,
              obscureText: true,
              validator: Validators.newPassword,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _confirmCtrl,
              label: 'Nhập lại mật khẩu mới',
              icon: Icons.lock_reset,
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: Validators.confirmPassword(() => _newCtrl.text),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('LƯU MẬT KHẨU'),
            ),
          ],
        ),
      ),
    );
  }
}
