import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../cubit/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softCream,
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.go('/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.outerPadding * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),
                Text(
                  '🌙',
                  style: TextStyle(fontSize: 60.sp),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.gridGap),
                Text(
                  'NEKI TRACKER',
                  style: AppTypography.h1.copyWith(color: AppColors.primaryGreen),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.gridGap * 3),
                if (!_isLogin) ...[
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  SizedBox(height: AppSpacing.gridGap),
                ],
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                SizedBox(height: AppSpacing.gridGap),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                SizedBox(height: AppSpacing.gridGap * 2),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    if (state is AuthLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ElevatedButton(
                      onPressed: () => _handleSubmit(context),
                      child: Text(_isLogin ? 'Login' : 'Register', style: AppTypography.button),
                    );
                  },
                ),
                SizedBox(height: AppSpacing.gridGap),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin ? 'Don\'t have an account? Register' : 'Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit(BuildContext context) {
    if (_isLogin) {
      context.read<AuthCubit>().login(email: _emailController.text, password: _passwordController.text);
    } else {
      context.read<AuthCubit>().register(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
