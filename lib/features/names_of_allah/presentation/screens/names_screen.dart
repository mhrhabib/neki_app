import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/names_data.dart';

class NamesScreen extends StatefulWidget {
  const NamesScreen({super.key});

  @override
  State<NamesScreen> createState() => _NamesScreenState();
}

class _NamesScreenState extends State<NamesScreen> {
  List<NameOfAllah> _filteredNames = namesOfAllahData;

  void _filterNames(String query) {
    setState(() {
      _filteredNames = namesOfAllahData
          .where(
            (name) =>
                name.transliteration.toLowerCase().contains(query.toLowerCase()) ||
                name.meaning.toLowerCase().contains(query.toLowerCase()) ||
                name.arabic.contains(query),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("99 Names of Allah", style: AppTypography.h1.copyWith(color: AppColors.primaryGreen)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 0.85,
              ),
              itemCount: _filteredNames.length,
              itemBuilder: (context, index) {
                final name = _filteredNames[index];
                return _buildNameCard(name);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      color: Colors.white,
      child: TextField(
        onChanged: _filterNames,
        decoration: InputDecoration(
          hintText: "Search by name or meaning...",
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
          filled: true,
          fillColor: AppColors.softCream,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(vertical: 0.h),
        ),
      ),
    );
  }

  Widget _buildNameCard(NameOfAllah name) {
    return GestureDetector(
      onTap: () => _showNameDetail(name),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name.id.toString(),
              style: AppTypography.caption.copyWith(color: AppColors.goldAccent, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              name.arabic,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
                fontFamily: 'Arabic', // Assuming you have an Arabic font or default handles it
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              name.transliteration,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                name.meaning,
                style: AppTypography.caption.copyWith(color: AppColors.textGray),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNameDetail(NameOfAllah name) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "#${name.id}",
                style: AppTypography.caption.copyWith(color: AppColors.goldAccent, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              Text(
                name.arabic,
                style: TextStyle(fontSize: 48.sp, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              ),
              SizedBox(height: 8.h),
              Text(name.transliteration, style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),
              const Divider(),
              SizedBox(height: 16.h),
              Text(
                "Meaning",
                style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.goldAccent),
              ),
              Text(name.meaning, style: AppTypography.h3, textAlign: TextAlign.center),
              SizedBox(height: 20.h),
              Text(
                "Description",
                style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.goldAccent),
              ),
              Text(
                name.description,
                style: AppTypography.body.copyWith(color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  minimumSize: Size(double.infinity, 45.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: const Text("Close", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
