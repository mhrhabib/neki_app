import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../cubit/salah_lock_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class SalahLockOverlay extends StatefulWidget {
  const SalahLockOverlay({super.key});

  @override
  State<SalahLockOverlay> createState() => _SalahLockOverlayState();
}

class _SalahLockOverlayState extends State<SalahLockOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  int _alhamdulillahCount = 0;
  final int _targetCount = 10;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) {
        setState(() {}); // force builder to re-evaluate and return SizedBox.shrink()
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAlhamdulillahTap() {
    if (_alhamdulillahCount < _targetCount) {
      setState(() {
        _alhamdulillahCount++;
      });
      if (_alhamdulillahCount == _targetCount) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SalahLockCubit, SalahLockState>(
      listener: (context, state) {
        if (state is SalahLockActive) {
          _controller.forward();
          setState(() {
            _alhamdulillahCount = 0;
          });
        } else {
          _controller.reverse();
        }
      },
      builder: (context, state) {
        if (state is! SalahLockActive && _controller.isDismissed) {
          return const SizedBox.shrink();
        }

        final authState = context.read<AuthCubit>().state;
        final userId = authState is Authenticated ? authState.user.id : '';

        // Safely extract data from state (even if reversing)
        final salahName = (state is SalahLockActive)
            ? state.salahName
            : 'Salah';
        final verse = (state is SalahLockActive)
            ? state.verse
            : {'arabic': '', 'english': ''};

        return FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0D2818).withValues(alpha: 0.98),
                    const Color(0xFF05120A).withValues(alpha: 0.99),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 40.h),
                      _buildHeader(salahName),
                      const Spacer(),
                      _buildVerseCard(verse),
                      const Spacer(),
                      _buildInteractionSection(context, userId, salahName),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String salahName) {
    return Column(
      children: [
        Icon(Icons.dark_mode, color: const Color(0xFF4ADE80), size: 48.sp),
        SizedBox(height: 16.h),
        Text(
          '$salahName Time',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8.h),
        StreamBuilder(
          stream: Stream.periodic(const Duration(seconds: 1)),
          builder: (context, snapshot) {
            return Text(
              DateFormat('HH:mm').format(DateTime.now()),
              style: TextStyle(
                color: Colors.white70,
                fontSize: 20.sp,
                fontWeight: FontWeight.w300,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVerseCard(Map<String, String> verse) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            verse['arabic'] ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF4ADE80),
              fontSize: 24.sp,
              fontFamily:
                  'Amiri', // Assuming fonts might be available or fallback
              height: 1.8,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            verse['english'] ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14.sp,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionSection(
    BuildContext context,
    String userId,
    String salahName,
  ) {
    final bool isFinished = _alhamdulillahCount >= _targetCount;

    return Column(
      children: [
        Text(
          isFinished ? 'MashaAllah!' : 'Tap Alhamdulillah 10 times to unlock',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(10, (index) {
            final active = index < _alhamdulillahCount;
            return Container(
              width: 12.w,
              height: 12.w,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? const Color(0xFF4ADE80) : Colors.white24,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4ADE80).withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
        SizedBox(height: 32.h),
        if (!isFinished)
          GestureDetector(
            onTap: _onAlhamdulillahTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3D26),
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(
                  color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'ALHAMDULILLAH',
                style: TextStyle(
                  color: const Color(0xFF4ADE80),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              ElevatedButton(
                onPressed: _isConfirming
                    ? null
                    : () async {
                        setState(() => _isConfirming = true);
                        await context
                            .read<SalahLockCubit>()
                            .confirmPrayed(userId, salahName);
                        if (mounted) setState(() => _isConfirming = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ADE80),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(
                    horizontal: 48.w,
                    vertical: 16.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: Text(
                  'Yes, I prayed $salahName',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: _isConfirming
                    ? null
                    : () {
                        setState(() => _isConfirming = true);
                        context.read<SalahLockCubit>().remindLater(salahName);
                      },
                child: Text(
                  'Remind me in 10 minutes',
                  style: TextStyle(color: Colors.white60, fontSize: 14.sp),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
