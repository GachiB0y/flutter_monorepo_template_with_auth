import 'package:auth/src/widget/auth_scope.dart';
import 'package:flutter/material.dart';

/// {@template login_screen}
/// LoginScreen widget
/// {@endtemplate}
class LoginScreen extends StatefulWidget {
  /// {@macro login_screen}
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _passwordController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: FlutterLogo(size: 36),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Login',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _emailController,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      border: TextFieldOutlineBorder(
                        scheme: theme.colorScheme,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _PasswordTextField(controller: _passwordController),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      // Adds the [AuthEvent.signInWithEmailAndPassword]
                      // event to the [AuthBloc]
                      AuthScope.of(context).signInWithEmailAndPassword(
                        _emailController.text,
                        _passwordController.text,
                      );
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Sign in',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// {@template password_text_field}
/// _PasswordTextField widget
/// {@endtemplate}
class _PasswordTextField extends StatefulWidget {
  /// {@macro password_text_field}
  const _PasswordTextField({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  State<_PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<_PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 48,
      child: TextField(
        obscureText: _obscureText,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Password',
          border: TextFieldOutlineBorder(scheme: theme.colorScheme),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() => _obscureText = !_obscureText);
            },
          ),
        ),
      ),
    );
  }
}

class TextFieldOutlineBorder extends MaterialStateOutlineInputBorder {
  /// {@macro text_field_outline_border}
  const TextFieldOutlineBorder({
    required this.scheme,
  });

  /// The color scheme used to resolve the color of the outline.
  final ColorScheme scheme;

  @override
  InputBorder resolve(Set<WidgetState> states) {
    final isFocused = states.contains(WidgetState.focused);

    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: isFocused ? scheme.primary : scheme.outline,
        width: 1.5,
      ),
    );
  }
}
