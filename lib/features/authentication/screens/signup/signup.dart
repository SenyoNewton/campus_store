import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:campus_store/features/authentication/controllers/signup_controller.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignupController());
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(),

                SizedBox(height: size.height * 0.04),

                // Signup Form
                _buildSignupForm(controller),

                const SizedBox(height: 24),

                // Login Link
                _buildLoginLink(),
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
            Icons.person_add_outlined,
            color: Colors.orange[700],
            size: 32,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join the campus store community',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm(SignupController controller) {
    return Form(
      key: controller.formKey,
      child: Column(
        children: [
          // Name Field
          _buildNameField(controller),

          const SizedBox(height: 20),

          // Email Field
          _buildEmailField(controller),

          const SizedBox(height: 20),

          // Index Number Field
          _buildIndexNumberField(controller),

          const SizedBox(height: 20),

          // Course Field
          _buildCourseField(controller),

          const SizedBox(height: 20),

          // Phone Field
          _buildPhoneField(controller),

          const SizedBox(height: 20),

          // Password Field
          _buildPasswordField(controller),

          const SizedBox(height: 20),

          // Role Selection
          _buildRoleSelection(controller),

          const SizedBox(height: 32),

          // Sign Up Button
          _buildSignUpButton(controller),
        ],
      ),
    );
  }

  Widget _buildNameField(SignupController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final hasError = controller.nameError.value != null;
          final isValid = controller.isNameValid.value;
          final hasContent = controller.name.text.isNotEmpty;

          Color borderColor = Colors.grey[300]!;
          Widget? suffixIcon;

          if (hasContent) {
            if (hasError) {
              borderColor = Colors.red;
              suffixIcon =
                  Icon(Icons.error_outline, color: Colors.red, size: 20);
            } else if (isValid) {
              borderColor = Colors.green;
              suffixIcon = Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 20);
            }
          }

          return TextFormField(
            controller: controller.name,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'[a-zA-Z\s]')), // Only letters and spaces
              LengthLimitingTextInputFormatter(50),
            ],
            validator: controller.validateName,
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: Icon(Icons.person_outline, color: Colors.grey[600]),
              suffixIcon: suffixIcon,
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
        _buildValidationMessage(controller.nameError),
      ],
    );
  }

  Widget _buildEmailField(SignupController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final hasError = controller.emailError.value != null;
          final isValid = controller.isEmailValid.value;
          final hasContent = controller.email.text.isNotEmpty;

          Color borderColor = Colors.grey[300]!;
          Widget? suffixIcon;

          if (hasContent) {
            if (hasError) {
              borderColor = Colors.red;
              suffixIcon =
                  Icon(Icons.error_outline, color: Colors.red, size: 20);
            } else if (isValid) {
              borderColor = Colors.green;
              suffixIcon = Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 20);
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
              labelText: 'Student Email',
              hintText: 'Enter your student email',
              prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
              suffixIcon: suffixIcon,
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
        _buildValidationMessage(controller.emailError),
      ],
    );
  }

  Widget _buildIndexNumberField(SignupController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final hasError = controller.indexNumberError.value != null;
          final isValid = controller.isIndexNumberValid.value;
          final hasContent = controller.indexNumber.text.isNotEmpty;

          Color borderColor = Colors.grey[300]!;
          Widget? suffixIcon;

          if (hasContent) {
            if (hasError) {
              borderColor = Colors.red;
              suffixIcon =
                  Icon(Icons.error_outline, color: Colors.red, size: 20);
            } else if (isValid) {
              borderColor = Colors.green;
              suffixIcon = Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 20);
            }
          }

          return TextFormField(
            controller: controller.indexNumber,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'[A-Z0-9]')), // Only uppercase letters and numbers
              LengthLimitingTextInputFormatter(15),
            ],
            validator: controller.validateIndexNumber,
            decoration: InputDecoration(
              labelText: 'Index Number',
              hintText: 'Enter your index number',
              prefixIcon: Icon(Icons.badge_outlined, color: Colors.grey[600]),
              suffixIcon: suffixIcon,
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
        _buildValidationMessage(controller.indexNumberError),
      ],
    );
  }

  Widget _buildCourseField(SignupController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final hasError = controller.courseError.value != null;
          final isValid = controller.isCourseValid.value;
          final hasContent = controller.course.text.isNotEmpty;

          Color borderColor = Colors.grey[300]!;
          Widget? suffixIcon;

          if (hasContent) {
            if (hasError) {
              borderColor = Colors.red;
              suffixIcon =
                  Icon(Icons.error_outline, color: Colors.red, size: 20);
            } else if (isValid) {
              borderColor = Colors.green;
              suffixIcon = Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 20);
            }
          }

          return TextFormField(
            controller: controller.course,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'[a-zA-Z\s&]')), // Letters, spaces, and ampersand
              LengthLimitingTextInputFormatter(50),
            ],
            validator: controller.validateCourse,
            decoration: InputDecoration(
              labelText: 'Course of Study',
              hintText: 'Enter your course',
              prefixIcon: Icon(Icons.school_outlined, color: Colors.grey[600]),
              suffixIcon: suffixIcon,
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
        _buildValidationMessage(controller.courseError),
      ],
    );
  }

  Widget _buildPhoneField(SignupController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final hasError = controller.phoneError.value != null;
          final isValid = controller.isPhoneValid.value;
          final hasContent = controller.phone.text.isNotEmpty;

          Color borderColor = Colors.grey[300]!;
          Widget? suffixIcon;

          if (hasContent) {
            if (hasError) {
              borderColor = Colors.red;
              suffixIcon =
                  Icon(Icons.error_outline, color: Colors.red, size: 20);
            } else if (isValid) {
              borderColor = Colors.green;
              suffixIcon = Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 20);
            }
          }

          return TextFormField(
            controller: controller.phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(
                  r'[0-9+\-\s()]')), // Numbers, +, -, spaces, parentheses
              LengthLimitingTextInputFormatter(20),
            ],
            validator: controller.validatePhone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter your phone number',
              prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey[600]),
              suffixIcon: suffixIcon,
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
        _buildValidationMessage(controller.phoneError),
      ],
    );
  }

  Widget _buildPasswordField(SignupController controller) {
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
              validationIcon =
                  Icon(Icons.error_outline, color: Colors.red, size: 20);
            } else if (isValid) {
              borderColor = Colors.green;
              validationIcon = Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 20);
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
        _buildValidationMessage(controller.passwordError),

        // Password requirements (similar to login screen)
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

  Widget _buildRoleSelection(SignupController controller) {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedRole.value.isEmpty
              ? null
              : controller.selectedRole.value,
          decoration: InputDecoration(
            labelText: 'Register As',
            hintText: 'Select your role',
            prefixIcon:
                Icon(Icons.person_pin_outlined, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
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
          items: controller.roles.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(
                role[0].toUpperCase() + role.substring(1),
                style: const TextStyle(fontSize: 16),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              controller.updateRole(value);
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your role';
            }
            return null;
          },
        ));
  }

  Widget _buildSignUpButton(SignupController controller) {
    return Obx(() {
      final isFormValid = controller.isFormValid;
      final isLoading = controller.isLoading.value;

      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed:
              (isFormValid && !isLoading) ? controller.registerUser : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isFormValid ? Colors.orange[700] : Colors.grey[300],
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isFormValid) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ],
                ),
        ),
      );
    });
  }

  Widget _buildValidationMessage(RxnString errorMessage) {
    return Obx(() {
      final error = errorMessage.value;
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
    });
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            Get.back();
          },
          child: Text(
            'Sign In',
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
