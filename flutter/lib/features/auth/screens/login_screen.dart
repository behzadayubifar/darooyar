import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/utils/error_messages.dart';
import '../providers/auth_form_provider.dart';
import '../providers/auth_providers.dart';
import '../../../core/utils/logger.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNodes = List.generate(2, (index) => FocusNode());
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  bool _formDataSaved = false;

  @override
  void initState() {
    super.initState();
    _setupFocusListeners();
    _loadSavedFormData();

    // Add validation listeners with mounted checks
    _emailController.addListener(() {
      if (mounted) {
        setState(() {
          _emailError = FormValidators.validateEmail(_emailController.text);
        });
        _formDataSaved = false;
      }
    });

    _passwordController.addListener(() {
      if (mounted) {
        setState(() {
          _passwordError =
              FormValidators.validatePassword(_passwordController.text);
        });
        _formDataSaved = false;
      }
    });

    AppLogger.d('LoginScreen initialized');
  }

  void _loadSavedFormData() {
    final formData = ref.read(loginFormProvider);
    _emailController.text = formData.email;
    _passwordController.text = formData.password;
    AppLogger.d('Loaded saved form data');
  }

  void _saveFormData() {
    if (_formDataSaved || !mounted) return;

    try {
      _formDataSaved = true;
      if (mounted) {
        ref.read(loginFormProvider.notifier).updateForm(
              email: _emailController.text,
              password: _passwordController.text,
            );
        AppLogger.d('Saved form data');
      }
    } catch (e) {
      AppLogger.e('Error saving form data: $e');
    }
  }

  void _setupFocusListeners() {
    for (var i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          _scrollToField(i);
        }
      });
    }
  }

  void _scrollToField(int index) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          index * 80.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _login() async {
    _saveFormData();

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      AppLogger.i('Attempting login for: ${_emailController.text}');

      await ref.read(authStateProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
          );

      AppLogger.i('Login successful, navigating to home');

      if (mounted) {
        ref.read(loginFormProvider.notifier).clear();
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      AppLogger.e('Login failed: $e');

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ErrorMessages.getAuthError(
                  e.toString().replaceAll('Exception: ', '')),
              style: const TextStyle(fontFamily: 'Vazirmatn'),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Remove all listeners before disposing
    _emailController.removeListener(_saveFormData);
    _passwordController.removeListener(_saveFormData);

    // Only save form data if we haven't already and the widget is still mounted
    if (!_formDataSaved) {
      try {
        if (mounted) {
          ref.read(loginFormProvider.notifier).updateForm(
                email: _emailController.text,
                password: _passwordController.text,
              );
          AppLogger.d('Saved form data on dispose');
        }
      } catch (e) {
        AppLogger.e('Error saving form data on dispose: $e');
      }
    }

    // Dispose controllers
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();

    // Dispose focus nodes
    for (var node in _focusNodes) {
      node.dispose();
    }

    AppLogger.d('LoginScreen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.surfaceColor,
        body: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'ورود',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                    controller: _emailController,
                    focusNode: _focusNodes[0],
                    nextFocusNode: _focusNodes[1],
                    label: 'ایمیل',
                    icon: Icons.email_outlined,
                    error: _emailError,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: FormValidators.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    focusNode: _focusNodes[1],
                    label: 'رمز عبور',
                    icon: Icons.lock_outline,
                    error: _passwordError,
                    obscureText: _obscurePassword,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    validator: FormValidators.validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? Lottie.asset(
                            'assets/animations/loading.json',
                            width: 30,
                            height: 30,
                          )
                        : const Text('ورود'),
                  ),
                  const SizedBox(height: 16),
                  _buildRegisterLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required String label,
    required IconData icon,
    String? error,
    bool obscureText = false,
    TextDirection? textDirection,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      textDirection: textDirection,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : AppTheme.textPrimaryColor,
          ),
      onFieldSubmitted: (value) {
        if (nextFocusNode != null) {
          nextFocusNode.requestFocus();
        } else {
          onFieldSubmitted?.call(value);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        errorText: error,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
        ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF2C2C2C),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'حساب کاربری ندارید؟',
            style: TextStyle(
              color: Colors.grey[700],
              fontFamily: 'Vazirmatn',
            ),
          ),
          TextButton(
            onPressed: () {
              _saveFormData();
              Navigator.pushReplacementNamed(context, '/register');
            },
            child: Text(
              'ثبت نام کنید',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
