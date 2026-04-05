import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/project_provider.dart';
import 'home_screen.dart';

enum AuthMode { login, adminRegister, staffRegister }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoginMode = true;
  bool _isAdminRegistration = true;

  // Form controllers
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  // Project fields for admin registration
  final _projectNameCtrl = TextEditingController();
  final _projectAreaCtrl = TextEditingController();
  final _projectDurationCtrl = TextEditingController();

  // Staff registration fields
  final _accessCodeCtrl = TextEditingController();
  String? _selectedRole = 'HSE OFFICER';

  final List<Map<String, String>> _roleOptions = [
    {'value': 'HSE OFFICER', 'label': 'HSE Officer'},
    {'value': 'HSE SUPERVISOR', 'label': 'HSE Supervisor'},
    {'value': 'HSE MANAGER', 'label': 'HSE Manager'},
  ];

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _projectNameCtrl.dispose();
    _projectAreaCtrl.dispose();
    _projectDurationCtrl.dispose();
    _accessCodeCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_usernameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }

    try {
      await ref
          .read(projectProvider.notifier)
          .login(
            username: _usernameCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      _showError('Login failed: ${e.toString()}');
    }
  }

  void _handleAdminRegister() async {
    if (!_validateRegistrationFields()) return;

    try {
      await ref
          .read(projectProvider.notifier)
          .registerAsAdmin(
            username: _usernameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            firstName: _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim(),
            projectName: _projectNameCtrl.text.trim(),
            projectArea: _projectAreaCtrl.text.trim(),
            projectDuration: _projectDurationCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      _showError('Registration failed: ${e.toString()}');
    }
  }

  void _handleStaffRegister() async {
    if (!_validateStaffFields()) return;

    try {
      await ref
          .read(projectProvider.notifier)
          .registerAsStaff(
            username: _usernameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            firstName: _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim(),
            projectName: _projectNameCtrl.text.trim(),
            accessCode: _accessCodeCtrl.text.trim(),
            role: _selectedRole!,
          );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      _showError('Registration failed: ${e.toString()}');
    }
  }

  bool _validateRegistrationFields() {
    if (_usernameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passwordCtrl.text.isEmpty ||
        _firstNameCtrl.text.isEmpty ||
        _lastNameCtrl.text.isEmpty ||
        _projectNameCtrl.text.isEmpty ||
        _projectAreaCtrl.text.isEmpty ||
        _projectDurationCtrl.text.isEmpty) {
      _showError('Please fill in all required fields');
      return false;
    }
    if (_passwordCtrl.text.length < 8) {
      _showError('Password must be at least 8 characters');
      return false;
    }
    return true;
  }

  bool _validateStaffFields() {
    if (_usernameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passwordCtrl.text.isEmpty ||
        _firstNameCtrl.text.isEmpty ||
        _lastNameCtrl.text.isEmpty ||
        _projectNameCtrl.text.isEmpty ||
        _accessCodeCtrl.text.isEmpty) {
      _showError('Please fill in all required fields');
      return false;
    }
    if (_passwordCtrl.text.length < 8) {
      _showError('Password must be at least 8 characters');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _switchToLogin() {
    setState(() {
      _isLoginMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(projectProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF0F2F5,
      ), // Light grey Facebook background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo and Title
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'HSEBOOK',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLoginMode ? 'Welcome Back!' : 'Create Account',
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),

                  // Login / Registration Form
                  if (_isLoginMode)
                    _buildLoginForm(loading)
                  else
                    _buildRegistrationForm(loading),

                  const SizedBox(height: 16),

                  // Toggle between Login and Registration
                  if (_isLoginMode) ...[
                    TextButton(
                      onPressed: () => setState(() => _isLoginMode = false),
                      child: const Text.rich(
                        TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: Colors.black54),
                          children: [
                            TextSpan(
                              text: 'Sign up',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? '),
                        TextButton(
                          onPressed: _switchToLogin,
                          child: const Text(
                            'Log in',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Divider with "OR"
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Social Auth Buttons
                  _buildSocialAuthButtons(loading),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool loading) {
    return Column(
      children: [
        TextField(
          controller: _usernameCtrl,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Login',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Admin/Staff Toggle
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isAdminRegistration = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isAdminRegistration
                          ? Colors.red
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Admin',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isAdminRegistration
                            ? Colors.white
                            : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isAdminRegistration = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isAdminRegistration
                          ? Colors.red
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Staff',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: !_isAdminRegistration
                            ? Colors.white
                            : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Name fields
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _firstNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Username
        TextField(
          controller: _usernameCtrl,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 12),

        // Email
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 12),

        // Password
        TextField(
          controller: _passwordCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
            helperText: 'At least 8 characters',
          ),
        ),
        const SizedBox(height: 16),

        // Project Name (Required for both)
        TextField(
          controller: _projectNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Project Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.work),
          ),
        ),
        const SizedBox(height: 12),

        // Admin-specific fields
        if (_isAdminRegistration) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _projectAreaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Project Area',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _projectDurationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 6 months',
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Staff-specific: Role Selection
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: const InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge),
            ),
            items: _roleOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option['value'],
                child: Text(option['label']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRole = value;
              });
            },
          ),
          const SizedBox(height: 12),
          // Staff-specific: Access Code
          TextField(
            controller: _accessCodeCtrl,
            decoration: const InputDecoration(
              labelText: 'Access Code',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.key),
              helperText: 'Get this from your admin',
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Register Button (Green - Facebook style)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading
                ? null
                : (_isAdminRegistration
                      ? _handleAdminRegister
                      : _handleStaffRegister),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _isAdminRegistration
                        ? 'Create Project & Register'
                        : 'Join Project & Register',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialAuthButtons(bool loading) {
    return Column(
      children: [
        // Google Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: loading ? null : () => _handleSocialAuth('google'),
            icon: const Icon(Icons.g_mobiledata, size: 24),
            label: const Text('Continue with Google'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Facebook Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: loading ? null : () => _handleSocialAuth('facebook'),
            icon: const Icon(Icons.facebook, color: Colors.white),
            label: const Text('Continue with Facebook'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Social login requires project setup',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  void _handleSocialAuth(String provider) {
    // Show dialog for social auth completion
    showDialog(
      context: context,
      builder: (context) => _SocialAuthDialog(
        provider: provider,
        onComplete: (projectName, accessCode) async {
          Navigator.pop(context);
          // TODO: Implement actual social auth
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${provider.toUpperCase()} login - Project: $projectName, Code: $accessCode',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }
}

class _SocialAuthDialog extends StatefulWidget {
  final String provider;
  final Function(String projectName, String accessCode) onComplete;

  const _SocialAuthDialog({required this.provider, required this.onComplete});

  @override
  State<_SocialAuthDialog> createState() => _SocialAuthDialogState();
}

class _SocialAuthDialogState extends State<_SocialAuthDialog> {
  final _projectNameCtrl = TextEditingController();
  final _accessCodeCtrl = TextEditingController();

  @override
  void dispose() {
    _projectNameCtrl.dispose();
    _accessCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Complete Registration with ${widget.provider.toUpperCase()}',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Please provide your project details to complete registration:',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _projectNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Project Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _accessCodeCtrl,
            decoration: const InputDecoration(
              labelText: 'Access Code',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_projectNameCtrl.text.isNotEmpty &&
                _accessCodeCtrl.text.isNotEmpty) {
              widget.onComplete(
                _projectNameCtrl.text.trim(),
                _accessCodeCtrl.text.trim(),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Complete'),
        ),
      ],
    );
  }
}
