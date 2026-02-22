import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thotha_mobile_app/core/di/dependency_injection.dart';
import 'package:thotha_mobile_app/features/home_screen/data/models/doctor_model.dart';
import 'package:thotha_mobile_app/features/home_screen/logic/doctor_cubit.dart';
import 'package:thotha_mobile_app/features/home_screen/logic/doctor_state.dart';
import 'package:thotha_mobile_app/features/doctor_info/ui/doctor_info_screen.dart';
import 'dart:ui'; 

class CategoryDoctorsScreen extends StatelessWidget {
  final String categoryName;
  final int? categoryId;
  final int? cityId;
  final String? cityName;

  const CategoryDoctorsScreen({
    super.key,
    required this.categoryName,
    this.categoryId,
    this.cityId,
    this.cityName,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final baseFontSize = width * 0.04;

    return BlocProvider(
      create: (context) {
        final cubit = getIt<DoctorCubit>();
        if (categoryId != null) {
          if (cityName != null && cityName!.isNotEmpty) {
            cubit.filterByCategoryAndCity(categoryId!, cityName!);
          } else {
            cubit.filterByCategory(categoryId!);
          }
        } else {
          if (cityName != null && cityName!.isNotEmpty) {
            cubit.filterByCategoryNameAndCity(categoryName, cityName!);
          } else {
            cubit.filterByCategoryName(categoryName);
          }
        }
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            categoryName,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: baseFontSize * 1.125, // 18sp
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<DoctorCubit, DoctorState>(
          builder: (context, state) {
            if (state is DoctorLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is DoctorError) {
              return Center(child: Text(state.error, style: const TextStyle(fontFamily: 'Cairo')));
            } else if (state is DoctorSuccess) {
              final doctors = state.doctors;
              if (doctors.isEmpty) {
                return Center(
                    child: Text('لا يوجد أطباء في هذا القسم حالياً', 
                      style: TextStyle(fontFamily: 'Cairo', fontSize: baseFontSize)));
              }
              return ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: 16),
                itemCount: doctors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildDoctorItem(context, doctors[index], width, baseFontSize);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildDoctorItem(BuildContext context, DoctorModel doctor, double width, double baseFontSize) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showDoctorDetails(context, doctor),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60 * (width / 390),
              height: 60 * (width / 390),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
              child: ClipOval(
                child: doctor.photo != null && doctor.photo!.isNotEmpty
                    ? Image.network(
                        doctor.photo!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, color: Colors.grey),
                      )
                    : const Icon(Icons.person, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.fullName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: baseFontSize,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.categoryName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Cairo',
                      fontSize: baseFontSize * 0.875,
                      color:
                          theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          doctor.cityName,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontFamily: 'Cairo', fontSize: baseFontSize * 0.75),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      if (doctor.price != null)
                        Flexible(
                          child: Text(
                            '${doctor.price} جنيه',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'Cairo',
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: baseFontSize * 0.75,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDoctorDetails(BuildContext context, DoctorModel doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Stack(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            maxChildSize: 0.9,
            minChildSize: 0.3,
            builder: (context, controller) {
              return DoctorInfoContent(
                controller: controller,
                doctor: doctor,
              );
            },
          )
        ]);
      },
    );
  }
}
