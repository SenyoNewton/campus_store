import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:campus_store/features/authentication/controllers/login_controller.dart';
import 'package:campus_store/features/authentication/screens/signup/signup.dart';
import 'package:campus_store/features/authentication/screens/login/forgot_password.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.08),

                // Header Section
                _buildHeader(),

                SizedBox(height: size.height * 0.06),

                // Login Form
                _buildLoginForm(controller),

                const SizedBox(height: 24),

                // Sign Up Link
                _buildSignUpLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.school,
            color: Colors.orange[700],
            size: 32,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your campus store account',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(LoginController controller) {
    return Form(
      key: controller.formKey,
      child: Column(
        children: [
          // Email Field with Real-time Validation
          _buildEmailField(controller),

          const SizedBox(height: 20),

          // Password Field with Real-time Validation
          _buildPasswordField(controller),

          const SizedBox(height: 16),

          // Forgot Password Link
          _buildForgotPasswordLink(),

          const SizedBox(height: 32),

          // Login Button with Form Validation State
          _buildLoginButton(controller),
        ],
      ),
    );
  }

  Widget _buildEmailField(LoginController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final hasError = controller.emailError.value != null;
          final isValid = controller.isEmailValid.value;
          final hasContent = controller.email.text.isNotEmpty;

          Color borderColor = Colors.grey[300]!;
          Color? suffixIconColor;
          Widget? suffixIcon;

          if (hasContent) {
            if (hasError) {
              borderColor = Colors.red;
              suffixIconColor = Colors.red;
              suffixIcon = const Icon(Icons.error_outline, size: 20);
            } else if (isValid) {
              borderColor = Colors.green;
              suffixIconColor = Colors.green;
              suffixIcon = const Icon(Icons.check_circle_outline, size: 20);
            }
          }

          return TextFormField(
            controller: controller.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')), // No spaces
              LengthLimitingTextInputFormatter(50),
            ],
            validator: controller.validateEmail,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your student email',
              prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
              suffixIcon: suffixIcon != null
                  ? IconTheme(
                      data: IconThemeData(color: suffixIconColor),
                      child: suffixIcon,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : Colors.orange[700]!,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          );
        }),

        // Real-time validation message
        Obx(() {
          final error = controller.emailError.value;
          if (error != null) {
            return Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Colors.red[600],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildPasswordField(LoginController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final hasError = controller.passwordError.value != null;
          final isValid = controller.isPasswordValid.value;
          final hasContent = controller.password.text.isNotEmpty;

          Color borderColor = Colors.grey[300]!;
          Widget? validationIcon;

          if (hasContent) {
            if (hasError) {
              borderColor = Colors.red;
              validationIcon = Icon(
                Icons.error_outline,
                size: 20,
                color: Colors.red[600],
              );
            } else if (isValid) {
              borderColor = Colors.green;
              validationIcon = Icon(
                Icons.check_circle_outline,
                size: 20,
                color: Colors.green[600],
              );
            }
          }

          return TextFormField(
            controller: controller.password,
            obscureText: !controller.isPasswordVisible.value,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')), // No spaces
              LengthLimitingTextInputFormatter(50),
            ],
            validator: controller.validatePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (validationIcon != null) ...[
                    validationIcon,
                    const SizedBox(width: 4),
                  ],
                  IconButton(
                    icon: Icon(
                      controller.isPasswordVisible.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey[600],
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : Colors.orange[700]!,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          );
        }),

        // Real-time validation message
        Obx(() {
          final error = controller.passwordError.value;
          if (error != null) {
            return Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Colors.red[600],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),

        // Password requirements indicator
        Obx(() {
          final hasContent = controller.password.text.isNotEmpty;
          final isValid = controller.isPasswordValid.value;

          if (hasContent && !isValid) {
            return Padding(
              padding: const EdgeInsets.only(top: 12, left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password requirements:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildRequirement('At least 6 characters',
                      controller.password.text.length >= 6),
                  _buildRequirement('At least one letter',
                      RegExp(r'[a-zA-Z]').hasMatch(controller.password.text)),
                  _buildRequirement('At least one number',
                      RegExp(r'[0-9]').hasMatch(controller.password.text)),
                  _buildRequirement('No spaces allowed',
                      !controller.password.text.contains(' ')),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: isMet ? Colors.green[600] : Colors.grey[400],
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isMet ? Colors.green[600] : Colors.grey[600],
              fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Get.to(() => const ForgotPasswordScreen());
        },
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: Colors.orange[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(LoginController controller) {
    return Obx(() {
      final isFormValid = controller.isFormValid;
      final isLoading = controller.isLoading.value;

      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: (isFormValid && !isLoading) ? controller.loginUser : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isFormValid ? Colors.orange[700] : Colors.grey[300],
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isFormValid) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        size: 18,
                      ),
                    ],
                  ],
                ),
        ),
      );
    });
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            Get.to(() => const SignUpScreen());
          },
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: Colors.orange[700],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
