import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../widgets/qibla_compass_widget.dart';
import '../../../../components/app_background_widget.dart';
import '../../../../core/widgets/custom_back_button.dart';

class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({super.key});

  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen> {
  bool _hasPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permissions are permanently denied, we cannot request permissions.',
          ),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _hasPermission = true;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 70.w,
        leading: const CustomBackButton(),
        centerTitle: true,
        title: Text(
          "Qibla Compass",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          appBackgroundWidget(),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (!_hasPermission)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64.sp, color: Colors.white54),
                  SizedBox(height: 16.h),
                  Text(
                    "Location permission required",
                    style: AppTypography.body.copyWith(color: Colors.white70),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton(
                    onPressed: _checkLocationPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: const Text(
                      "Grant Permission",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          else
            FutureBuilder(
              future: FlutterQiblah.androidDeviceSensorSupport(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink(); // Avoid second spinner blink
                }
                if (snapshot.hasError || snapshot.data == false) {
                  return const Center(
                    child: Text(
                      "Your device does not support compass sensors",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                return const QiblaCompassWidget();
              },
            ),
        ],
      ),
    );
  }
}
