import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:studentology/core/theme/app_theme.dart';
import 'package:studentology/providers/auth_provider.dart';
import 'package:studentology/providers/exam_provider.dart';
import 'package:studentology/providers/grade_provider.dart';
import 'package:studentology/providers/subject_provider.dart';
import 'package:studentology/providers/task_provider.dart';
import 'package:studentology/providers/theme_provider.dart';
import 'package:studentology/widgets/section_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _openEditProfileSheet() {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditProfileSheet(
        initialName: user.name,
        onSave: (name) async {
          await auth.updateProfile(user.copyWith(name: name));
        },
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => _ChangePasswordDialog(
        onChangePassword: (current, newPwd) async {
          await context.read<AuthProvider>().changePassword(current, newPwd);
        },
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).dialogBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black, width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black,
                  blurRadius: 0,
                  spreadRadius: 0,
                  offset: Offset(5, 5)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign Out',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Theme.of(ctx).textTheme.bodyLarge!.color),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to sign out?',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(ctx).textTheme.bodySmall!.color,
                      height: 1.5),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      side: const BorderSide(color: Colors.black, width: 1.5),
                    ),
                    child: Text('Sign Out',
                        style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 1.5),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor:
                          Theme.of(ctx).textTheme.bodyLarge!.color,
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Theme.of(ctx).textTheme.bodyLarge!.color)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      final navigator = Navigator.of(context);
      context.read<SubjectProvider>().reset();
      context.read<TaskProvider>().reset();
      context.read<ExamProvider>().reset();
      context.read<GradeProvider>().reset();
      await context.read<AuthProvider>().signOut();
      navigator.pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, auth, themeProvider, _) {
        final user = auth.currentUser;
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: context.bgColor,
            elevation: 0,
            iconTheme: IconThemeData(color: context.textPrimary),
            title: Text(
              'Profile & Settings',
              style: GoogleFonts.ultra(color: context.textPrimary),
            ),
          ),
          body: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // ── Profile header ───────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryAccent,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor:
                            AppTheme.primaryAccent.withValues(alpha: 0.15),
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 36,
                            color: AppTheme.primaryAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user?.name ?? 'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.ultra(
                        fontSize: 22,
                        color: context.textPrimary,
                        height: 1.36,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── APPEARANCE ───────────────────────────────────────────────
              const SectionHeader(title: 'APPEARANCE'),
              const SizedBox(height: 10),
              _SettingsCard(
                children: [
                  SwitchListTile(
                    value: isDark,
                    onChanged: (_) => themeProvider.toggleTheme(),
                    activeColor: const Color(0xFFFFB347),
                    activeTrackColor:
                        const Color(0xFFFFB347).withOpacity(0.4),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade400,
                    title: Text(
                      'Dark Mode',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      isDark ? 'Dark theme enabled' : 'Light theme enabled',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── ACCOUNT ──────────────────────────────────────────────────
              const SectionHeader(title: 'ACCOUNT'),
              const SizedBox(height: 10),
              _SettingsCard(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline_rounded,
                        color: AppTheme.primaryAccent),
                    title: Text(
                      'Edit Profile',
                      style: TextStyle(color: context.textPrimary),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: context.textSecondary,
                      size: 20,
                    ),
                    onTap: _openEditProfileSheet,
                  ),
                  Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: context.cardBorder),
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded,
                        color: AppTheme.primaryAccent),
                    title: Text(
                      'Change Password',
                      style: TextStyle(color: context.textPrimary),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: context.textSecondary,
                      size: 20,
                    ),
                    onTap: _showChangePasswordDialog,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── ABOUT ────────────────────────────────────────────────────
              const SectionHeader(title: 'ABOUT'),
              const SizedBox(height: 10),
              _SettingsCard(
                children: [
                  ListTile(
                    title: Text('App Version',
                        style: TextStyle(color: context.textPrimary)),
                    trailing: Text(
                      '1.0.0',
                      style: TextStyle(
                          color: context.textSecondary, fontSize: 14),
                    ),
                  ),
                  Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: context.cardBorder),
                  ListTile(
                    title: Text('Developer',
                        style: TextStyle(color: context.textPrimary)),
                    trailing: Text(
                      'Ann Nicole Adraneda',
                      style: TextStyle(
                          color: context.textSecondary, fontSize: 14),
                    ),
                  ),
                  Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: context.cardBorder),
                  ListTile(
                    title: Text('Course',
                        style: TextStyle(color: context.textPrimary)),
                    trailing: Text(
                      'CTMOBPGL',
                      style: TextStyle(
                          color: context.textSecondary, fontSize: 14),
                    ),
                  ),
                  Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: context.cardBorder),
                  ListTile(
                    title: Text('School',
                        style: TextStyle(color: context.textPrimary)),
                    trailing: Text(
                      'National University — Clark',
                      style: TextStyle(
                          color: context.textSecondary, fontSize: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: _signOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor, width: 1.5),
                  minimumSize: const Size(double.infinity, 52),
                  shape: const StadiumBorder(),
                  textStyle: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Logout'),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// ── Change Password Dialog ────────────────────────────────────────────────────

class _ChangePasswordDialog extends StatefulWidget {
  final Future<void> Function(String current, String newPwd) onChangePassword;
  const _ChangePasswordDialog({required this.onChangePassword});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isSaving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.onChangePassword(_currentCtrl.text, _newCtrl.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Password changed successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      final isWrongPwd = msg.toLowerCase().contains('incorrect') ||
          msg.toLowerCase().contains('invalid-credential') ||
          msg.toLowerCase().contains('wrong');
      messenger.showSnackBar(
        SnackBar(
          content: Text(isWrongPwd ? 'Current password is incorrect' : msg),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggleObscure,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(obscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined),
          onPressed: toggleObscure,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black,
                blurRadius: 0,
                spreadRadius: 0,
                offset: Offset(5, 5)),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Change Password',
                    style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Theme.of(context).textTheme.bodyLarge!.color),
                  ),
                  const SizedBox(height: 20),
                  _passwordField(
                    controller: _currentCtrl,
                    label: 'Current Password',
                    obscure: _obscureCurrent,
                    toggleObscure: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _passwordField(
                    controller: _newCtrl,
                    label: 'New Password',
                    obscure: _obscureNew,
                    toggleObscure: () =>
                        setState(() => _obscureNew = !_obscureNew),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _passwordField(
                    controller: _confirmCtrl,
                    label: 'Confirm New Password',
                    obscure: _obscureConfirm,
                    toggleObscure: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v != _newCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAccent,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        side: const BorderSide(
                            color: Colors.black, width: 1.5),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Change Password',
                              style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Colors.black, width: 1.5),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor:
                            Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                      child: Text('Cancel',
                          style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .color)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Edit Profile bottom sheet ─────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final String initialName;
  final Future<void> Function(String name) onSave;

  const _EditProfileSheet({required this.initialName, required this.onSave});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await widget.onSave(_nameController.text.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Edit Profile',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings card ─────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}
