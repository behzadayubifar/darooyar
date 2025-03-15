import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/utils/error_messages.dart';
import '../providers/auth_form_provider.dart';
import '../services/auth_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _showSuccessAnimation = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _loadFormData();
    _setupFocusListeners();

    // Add listeners for validation and form data saving
    _usernameController.addListener(() {
      if (mounted) {
        setState(() {
          _usernameError =
              FormValidators.validateUsername(_usernameController.text);
        });
        _saveFormData();
      }
    });

    _emailController.addListener(() {
      if (mounted) {
        setState(() {
          _emailError = FormValidators.validateEmail(_emailController.text);
        });
        _saveFormData();
      }
    });

    _passwordController.addListener(() {
      if (mounted) {
        setState(() {
          _passwordError =
              FormValidators.validatePassword(_passwordController.text);
          _validateConfirmPassword();
        });
        _saveFormData();
      }
    });

    _confirmPasswordController.addListener(() {
      if (mounted) {
        setState(() {
          _validateConfirmPassword();
        });
        _saveFormData();
      }
    });

    _firstNameController.addListener(_saveFormData);
    _lastNameController.addListener(_saveFormData);
  }

  void _loadFormData() {
    final formData = ref.read(registerFormProvider);
    _usernameController.text = formData.username;
    _emailController.text = formData.email;
    _passwordController.text = formData.password;
    _confirmPasswordController.text = formData.password;
    _firstNameController.text = formData.firstName;
    _lastNameController.text = formData.lastName;
  }

  void _saveFormData() {
    ref.read(registerFormProvider.notifier).updateForm(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
        );
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

  void _validateConfirmPassword() {
    if (_confirmPasswordController.text.isEmpty) {
      _confirmPasswordError = 'لطفا تکرار رمز عبور را وارد کنید';
    } else if (_confirmPasswordController.text != _passwordController.text) {
      _confirmPasswordError = 'تکرار رمز عبور با رمز عبور مطابقت ندارد';
    } else {
      _confirmPasswordError = null;
    }
  }

  void _scrollToField(int index) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          index * 80.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _register() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = 'تکرار رمز عبور با رمز عبور مطابقت ندارد';
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = AuthService();
      await authService.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _showSuccessAnimation = true;
        });

        // Clear saved form data after successful registration
        ref.read(registerFormProvider.notifier).clear();

        // Wait for the animation to complete
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
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
    for (final controller in [
      _usernameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
      _firstNameController,
      _lastNameController,
    ]) {
      controller.removeListener(_saveFormData);
    }

    // Dispose controllers
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _scrollController.dispose();

    // Dispose focus nodes
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccessAnimation) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/register_success.json',
                width: 200,
                height: 200,
                repeat: false,
              ),
              const SizedBox(height: 16),
              const Text(
                'ثبت نام با موفقیت انجام شد',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                    'ثبت نام',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                    controller: _usernameController,
                    focusNode: _focusNodes[0],
                    nextFocusNode: _focusNodes[1],
                    label: 'نام کاربری',
                    icon: Icons.person_outline,
                    error: _usernameError,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.next,
                    validator: FormValidators.validateUsername,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    focusNode: _focusNodes[1],
                    nextFocusNode: _focusNodes[2],
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
                    focusNode: _focusNodes[2],
                    nextFocusNode: _focusNodes[3],
                    label: 'رمز عبور',
                    icon: Icons.lock_outline,
                    error: _passwordError,
                    obscureText: _obscurePassword,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.next,
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
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    focusNode: _focusNodes[3],
                    nextFocusNode: _focusNodes[4],
                    label: 'تکرار رمز عبور',
                    icon: Icons.lock_outline,
                    error: _confirmPasswordError,
                    obscureText: _obscureConfirmPassword,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'لطفا تکرار رمز عبور را وارد کنید';
                      }
                      if (value != _passwordController.text) {
                        return 'تکرار رمز عبور با رمز عبور مطابقت ندارد';
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _firstNameController,
                    focusNode: _focusNodes[4],
                    nextFocusNode: _focusNodes[5],
                    label: 'نام',
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: FormValidators.validateName,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _lastNameController,
                    focusNode: _focusNodes[5],
                    label: 'نام خانوادگی',
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _register(),
                    validator: FormValidators.validateName,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
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
                        : const Text('ثبت نام'),
                  ),
                  const SizedBox(height: 16),
                  _buildLoginLink(),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      textDirection: textDirection,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: (value) {
        if (nextFocusNode != null) {
          nextFocusNode.requestFocus();
        } else {
          onFieldSubmitted?.call(value);
        }
      },
      style: TextStyle(
        color: isDarkMode ? Colors.white : AppTheme.textPrimaryColor,
        fontFamily: 'Vazirmatn',
        fontSize: 16,
      ),
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
        fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'حساب کاربری دارید؟ ',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              fontFamily: 'Vazirmatn',
            ),
          ),
          TextButton(
            onPressed: () {
              // Only save form data if widget is still mounted
              if (mounted) {
                _saveFormData();
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: Text(
              'وارد شوید',
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
