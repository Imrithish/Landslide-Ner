import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../services/report_service.dart';
import '../models/report.dart';

final reportServiceProvider = Provider<ReportService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localCache = ref.watch(localCacheProvider);
  return ReportService(apiClient: apiClient, localCache: localCache);
});

final userReportsProvider = FutureProvider<List<HazardReport>>((ref) async {
  final reportService = ref.watch(reportServiceProvider);
  return await reportService.getReports();
});

class ReportSubmissionState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final HazardReport? submittedReport;

  ReportSubmissionState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.submittedReport,
  });
}

class ReportSubmissionNotifier extends StateNotifier<ReportSubmissionState> {
  final ReportService _reportService;

  ReportSubmissionNotifier(this._reportService) : super(ReportSubmissionState());

  Future<bool> submitHazardReport({
    required String location,
    required double latitude,
    required double longitude,
    required String description,
    String hazardType = 'Landslide',
    String severity = 'medium',
    String? state,
    String? district,
    File? imageFile,
    String? reporterName,
    String? contactInfo,
    bool visibleCracks = false,
    bool rockfallObserved = false,
    bool roadBlocked = false,
    bool waterAccumulation = false,
    bool soilMovement = false,
  }) async {
    state = ReportSubmissionState(isLoading: true);
    try {
      String? mediaUrl;
      if (imageFile != null) {
        mediaUrl = await _reportService.uploadPhoto(imageFile);
      }

      final report = await _reportService.submitReport(
        location: location,
        latitude: latitude,
        longitude: longitude,
        description: description,
        hazardType: hazardType,
        severity: severity,
        state: state,
        district: district,
        imageFile: imageFile,
        mediaUrl: mediaUrl,
        reporterName: reporterName,
        contactInfo: contactInfo,
        visibleCracks: visibleCracks,
        rockfallObserved: rockfallObserved,
        roadBlocked: roadBlocked,
        waterAccumulation: waterAccumulation,
        soilMovement: soilMovement,
      );

      state = ReportSubmissionState(
        isLoading: false,
        isSuccess: true,
        submittedReport: report,
      );
      return true;
    } catch (e) {
      state = ReportSubmissionState(
        isLoading: false,
        isSuccess: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = ReportSubmissionState();
  }
}

final reportSubmissionProvider = StateNotifierProvider<ReportSubmissionNotifier, ReportSubmissionState>((ref) {
  final reportService = ref.watch(reportServiceProvider);
  return ReportSubmissionNotifier(reportService);
});
