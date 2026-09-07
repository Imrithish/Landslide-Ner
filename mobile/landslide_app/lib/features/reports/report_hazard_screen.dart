import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/report_provider.dart';
import '../../providers/location_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../widgets/loading_view.dart';

class ReportHazardScreen extends ConsumerStatefulWidget {
  const ReportHazardScreen({super.key});

  @override
  ConsumerState<ReportHazardScreen> createState() => _ReportHazardScreenState();
}

class _ReportHazardScreenState extends ConsumerState<ReportHazardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  String _hazardType = 'Landslide';
  String _severity = 'Moderate';
  XFile? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final location = ref.read(selectedLocationProvider);

    try {
      await ref.read(reportServiceProvider).submitReport(
        latitude: location.latitude,
        longitude: location.longitude,
        description: _descController.text.trim(),
        hazardType: _hazardType,
        severity: _severity,
        imageFile: _selectedImage != null ? File(_selectedImage!.path) : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Report submitted successfully'),
              ],
            ),
            backgroundColor: AppColors.riskLow,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(selectedLocationProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Report Hazard'),
        backgroundColor: AppColors.darkBg,
        elevation: 0,
      ),
      body: _isSubmitting
          ? const LoadingView(message: 'Submitting your field report...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location display
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${location.latitude.toStringAsFixed(4)}° N, ${location.longitude.toStringAsFixed(4)}° E',
                              style: const TextStyle(
                                color: AppColors.darkTextPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              ref.read(selectedLocationProvider.notifier).fetchCurrentGpsLocation();
                            },
                            icon: const Icon(Icons.gps_fixed_rounded, size: 14),
                            label: const Text('Update GPS'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Photo section
                    const Text(
                      'PHOTO EVIDENCE',
                      style: TextStyle(
                        color: AppColors.darkTextMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_selectedImage != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedImage!.path),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => setState(() => _selectedImage = null),
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 16),
                        label: const Text('Remove photo', style: TextStyle(color: AppColors.error)),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _PhotoOptionButton(
                              icon: Icons.camera_alt_rounded,
                              label: 'Take Photo',
                              onTap: () => _pickImage(ImageSource.camera),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PhotoOptionButton(
                              icon: Icons.photo_library_rounded,
                              label: 'Choose Gallery',
                              onTap: () => _pickImage(ImageSource.gallery),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Hazard Type
                    const Text(
                      'HAZARD TYPE',
                      style: TextStyle(
                        color: AppColors.darkTextMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.hazardTypes.map((type) {
                        final isSelected = _hazardType == type;
                        return GestureDetector(
                          onTap: () => setState(() => _hazardType = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withAlpha(30) : AppColors.darkCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.darkBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: isSelected ? AppColors.primary : AppColors.darkTextSecondary,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Severity
                    const Text(
                      'SEVERITY',
                      style: TextStyle(
                        color: AppColors.darkTextMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: AppConstants.severityLevels.map((level) {
                        final isSelected = _severity == level;
                        final color = AppColors.getRiskColor(level.toUpperCase());
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _severity = level),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? color.withAlpha(25) : AppColors.darkCard,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? color : AppColors.darkBorder,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                level,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? color : AppColors.darkTextSecondary,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Description
                    const Text(
                      'DESCRIPTION',
                      style: TextStyle(
                        color: AppColors.darkTextMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _descController,
                      maxLines: 4,
                      style: const TextStyle(color: AppColors.darkTextPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Describe what you observed...',
                        hintStyle: TextStyle(color: AppColors.darkTextMuted),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().length < 10)
                              ? 'Please provide at least 10 characters'
                              : null,
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Submit Field Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Center(
                      child: Text(
                        'Reports are stored securely and reviewed by authorities',
                        style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _PhotoOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.darkTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
