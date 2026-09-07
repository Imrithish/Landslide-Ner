import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/location_provider.dart';
import '../../providers/prediction_provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/risk_card.dart';
import 'risk_details_screen.dart';

class AnalyzeLocationScreen extends ConsumerStatefulWidget {
  const AnalyzeLocationScreen({super.key});

  @override
  ConsumerState<AnalyzeLocationScreen> createState() => _AnalyzeLocationScreenState();
}

class _AnalyzeLocationScreenState extends ConsumerState<AnalyzeLocationScreen> {
  final _searchController = TextEditingController();
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final locationService = ref.read(locationServiceProvider);
    final result = await locationService.searchLocationByName(query);
    if (result != null) {
      ref.read(selectedLocationProvider.notifier).setCustomLocation(
        latitude: result.latitude,
        longitude: result.longitude,
        name: query,
      );
      _mapController.move(LatLng(result.latitude, result.longitude), 12);
      ref.invalidate(currentPredictionProvider);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not found. Try a different search.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(selectedLocationProvider);
    final predictionAsync = ref.watch(currentPredictionProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Analyze Location'),
        backgroundColor: AppColors.darkBg,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppColors.darkTextPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search location (e.g. Gangtok)',
                      hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.darkTextMuted),
                      filled: true,
                      fillColor: AppColors.darkCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.darkBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.darkBorder),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    onSubmitted: (_) => _searchLocation(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchLocation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    minimumSize: const Size(50, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.search_rounded, size: 20),
                ),
              ],
            ),
          ),

          // Quick location option
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () async {
                await ref.read(selectedLocationProvider.notifier).fetchCurrentGpsLocation();
                ref.invalidate(currentPredictionProvider);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withAlpha(60)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.gps_fixed_rounded, color: AppColors.primary, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Use My Current GPS Location',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Mini Map for tap-to-select
          SizedBox(
            height: 200,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(location.latitude, location.longitude),
                initialZoom: 9,
                onTap: (tapPos, latLng) {
                  ref.read(selectedLocationProvider.notifier).setCustomLocation(
                    latitude: latLng.latitude,
                    longitude: latLng.longitude,
                  );
                  ref.invalidate(currentPredictionProvider);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'in.gov.ner.landslide_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(location.latitude, location.longitude),
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(100), blurRadius: 10)],
                        ),
                        child: const Icon(Icons.location_pin, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Location chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${location.latitude.toStringAsFixed(4)}° N, ${location.longitude.toStringAsFixed(4)}° E',
                    style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Prediction Result
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: predictionAsync.when(
                loading: () => const LoadingView(message: 'Fetching environmental data & running ML analysis...'),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(currentPredictionProvider),
                  icon: Icons.radar_rounded,
                ),
                data: (prediction) => SingleChildScrollView(
                  child: RiskCard(
                    prediction: prediction,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => RiskDetailsScreen(prediction: prediction),
                      ));
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
