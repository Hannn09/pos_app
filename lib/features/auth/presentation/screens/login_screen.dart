import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_pos/features/auth/presentation/providers/auth_notifiers.dart';
import 'package:food_pos/routers/app_routes.dart';
import 'package:food_pos/theme/app_themes.dart';
import 'package:food_pos/widgets/labeled_text_field.dart';
import 'package:food_pos/widgets/loading_state_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: whiteColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 35,
                      vertical: 25,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: primaryColor, width: 1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              IconsaxPlusLinear.wallet_money,
                              color: primaryColor,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'Welcome Back !',
                            style: boldTextStyle.copyWith(
                              fontSize: 28,
                              color: blackColor,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Sign in to Cashier App',
                            textAlign: TextAlign.center,
                            style: regularTextStyle.copyWith(
                              fontSize: 16,
                              color: blackColor.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 35),
                          LabeledTextField(
                            label: 'Username',
                            hint: 'Enter Username (e.g. sarah or admin)',
                            controller: _emailController,
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
                            label: 'Password',
                            hint: 'Enter Password / PIN',
                            controller: _passwordController,
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'The password field is required';
                              }
                              return null;
                            },
                            isObsecure: _isPasswordVisible,
                            decoration: textFieldDecoration.copyWith(
                              hintText: 'Enter Password',
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
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 20, top: 40),
                            height: 55,
                            child: ElevatedButton(
                              onPressed: authState.isLoading
                                  ? null
                                  : () async {
                                      if (_formKey.currentState?.validate() ??
                                          false) {
                                        final success = await ref
                                            .read(authNotifierProvider.notifier)
                                            .login(
                                              _emailController.text,
                                              _passwordController.text,
                                            );

                                        if (!context.mounted) return;

                                        if (success) {
                                          context.go(AppRoutes.home);
                                        } else {
                                          final error = ref
                                                  .read(authNotifierProvider)
                                                  .errorMessage ??
                                              'Login failed';
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(error),
                                              backgroundColor:
                                                  Colors.red.shade700,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: primaryButtonStyle,
                              child: Text(
                                'Sign In',
                                style: boldTextStyle.copyWith(
                                  color: whiteColor,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: regularTextStyle.copyWith(
                                  color: greyColor,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  context.push(AppRoutes.signup);
                                },
                                child: Text(
                                  'Sign Up',
                                  style: boldTextStyle.copyWith(
                                    color: primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
