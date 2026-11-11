import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/features/auth/presentation/providers/auth_notifiers.dart';
import 'package:food_pos/routers/app_routes.dart';
import 'package:food_pos/theme/app_themes.dart';
import 'package:food_pos/widgets/labeled_text_field.dart';
import 'package:food_pos/widgets/loading_state_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = true;
  bool _isConfirmPasswordVisible = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(IconsaxPlusLinear.arrow_left, color: blackColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.login);
            }
          },
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 35,
                  vertical: 10,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryColor, width: 1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          IconsaxPlusLinear.user_add,
                          color: primaryColor,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Create Account',
                        style: boldTextStyle.copyWith(
                          fontSize: 28,
                          color: blackColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Sign up to get started with Cashier App',
                        textAlign: TextAlign.center,
                        style: regularTextStyle.copyWith(
                          fontSize: 16,
                          color: blackColor.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 30),
                      LabeledTextField(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'The full name field is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      LabeledTextField(
                        label: 'Username',
                        hint: 'Enter username',
                        controller: _usernameController,
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'The username field is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      LabeledTextField(
                        label: 'Email',
                        hint: 'Enter email address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'The email field is required';
                          }
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      LabeledTextField(
                        label: 'Phone Number',
                        hint: 'Enter phone number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'The phone number field is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      LabeledTextField(
                        label: 'Password',
                        hint: 'Enter password',
                        controller: _passwordController,
                        keyboardType: TextInputType.text,
                        isObsecure: _isPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'The password field is required';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        decoration: textFieldDecoration.copyWith(
                          hintText: 'Enter password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: greyColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          hintStyle: hintTextStyle,
                        ),
                      ),
                      const SizedBox(height: 20),
                      LabeledTextField(
                        label: 'Confirm Password',
                        hint: 'Re-enter password',
                        controller: _confirmPasswordController,
                        keyboardType: TextInputType.text,
                        isObsecure: _isConfirmPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'The confirm password field is required';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        decoration: textFieldDecoration.copyWith(
                          hintText: 'Re-enter password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: greyColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          hintStyle: hintTextStyle,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20, top: 35),
                        height: 55,
                        child: ElevatedButton(
                          onPressed: authState.isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    final success = await ref
                                        .read(authNotifierProvider.notifier)
                                        .register(
                                          name: _nameController.text,
                                          username: _usernameController.text,
                                          email: _emailController.text,
                                          phone: _phoneController.text,
                                          password: _passwordController.text,
                                        );

                                    if (!context.mounted) return;

                                    if (success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Account successfully created!',
                                          ),
                                          backgroundColor: primaryColor,
                                        ),
                                      );
                                      context.go(AppRoutes.login);
                                    } else {
                                      final error =
                                          ref
                                              .read(authNotifierProvider)
                                              .errorMessage ??
                                          'Registration failed';
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(error),
                                          backgroundColor: Colors.red.shade700,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: primaryButtonStyle,
                          child: Text(
                            'Sign Up',
                            style: boldTextStyle.copyWith(color: whiteColor),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: regularTextStyle.copyWith(
                              color: greyColor,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(AppRoutes.login);
                              }
                            },
                            child: Text(
                              'Sign In',
                              style: boldTextStyle.copyWith(
                                color: primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (authState.isLoading)
            const Positioned.fill(child: LoadingStateWidget()),
        ],
      ),
    );
  }
}
