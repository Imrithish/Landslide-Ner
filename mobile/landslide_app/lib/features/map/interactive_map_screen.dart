import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/map_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/prediction_provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/risk_zone.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/risk_badge.dart';
import '../prediction/risk_details_screen.dart';

class InteractiveMapScreen extends ConsumerStatefulWidget {
  const InteractiveMapScreen({super.key});

  @override
  ConsumerState<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends ConsumerState<InteractiveMapScreen> {
  final MapController _mapController = MapController();
  RiskZone? _selectedZone;
  String? _stateFilter;

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(selectedLocationProvider);
    final filteredZonesAsync = ref.watch(filteredRiskZonesProvider);
    final mapFilter = ref.watch(mapFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Risk Map'),
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        actions: [
          // State filter dropdown
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<String>(
              value: _stateFilter,
              dropdownColor: AppColors.darkCard,
              underline: const SizedBox.shrink(),
              hint: const Text('All States', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 13)),
              style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 13),
              items: [
                const DropdownMenuItem(value: null, child: Text('All States')),
                ...AppConstants.nerStates.map((s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
              onChanged: (val) {
                setState(() => _stateFilter = val);
                ref.read(mapFilterProvider.notifier).setStateFilter(val);
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(location.latitude, location.longitude),
              initialZoom: 7.0,
              onTap: (tapPos, latLng) {
                // On tap anywhere, set as selected location for analysis
                ref.read(selectedLocationProvider.notifier).setCustomLocation(
                  latitude: latLng.latitude,
                  longitude: latLng.longitude,
                  name: '${latLng.latitude.toStringAsFixed(4)}° N, ${latLng.longitude.toStringAsFixed(4)}° E',
                );
                setState(() => _selectedZone = null);
              },
            ),
            children: [
              // OpenStreetMap / CartoDB Dark tiles
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'in.gov.ner.landslide_app',
                maxZoom: 18,
                additionalOptions: const {
                  'attribution': '© OpenStreetMap contributors © CARTO',
                },
              ),

              // Risk Zone Circles
              filteredZonesAsync.when(
                data: (zones) => CircleLayer(
                  circles: zones.map((zone) {
                    final color = AppColors.getRiskColor(zone.riskLevel);
                    return CircleMarker(
                      point: LatLng(zone.latitude, zone.longitude),
                      radius: 12 + (zone.probability * 20),
                      color: color.withAlpha(50),
                      borderColor: color.withAlpha(180),
                      borderStrokeWidth: 2.0,
                    );
                  }).toList(),
                ),
                loading: () => const CircleLayer(circles: []),
                error: (_, __) => const CircleLayer(circles: []),
              ),

              // Risk Zone Markers
              filteredZonesAsync.when(
                data: (zones) => MarkerLayer(
                  markers: [
                    // Current selected location pin
                    Marker(
                      point: LatLng(location.latitude, location.longitude),
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedZone = null),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(120),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                    // Station markers
                    ...zones.map((zone) {
                      final color = AppColors.getRiskColor(zone.riskLevel);
                      return Marker(
                        point: LatLng(zone.latitude, zone.longitude),
                        width: 32,
                        height: 32,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedZone = zone),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withAlpha(200),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withAlpha(180), width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                _getRiskInitial(zone.riskLevel),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                loading: () => const MarkerLayer(markers: []),
                error: (_, __) => const MarkerLayer(markers: []),
              ),
            ],
          ),

          // Loading overlay
          filteredZonesAsync.isLoading
              ? const Positioned.fill(
                  child: Center(child: LoadingView(message: 'Loading risk zones...')),
                )
              : const SizedBox.shrink(),

          // GPS Locate Me button
          Positioned(
            right: 16,
            bottom: _selectedZone != null ? 260 : 100,
            child: FloatingActionButton.small(
              onPressed: () async {
                await ref.read(selectedLocationProvider.notifier).fetchCurrentGpsLocation();
                final loc = ref.read(selectedLocationProvider);
                _mapController.move(LatLng(loc.latitude, loc.longitude), 12);
              },
              backgroundColor: AppColors.darkCard,
              child: const Icon(Icons.my_location_rounded, color: AppColors.primary),
            ),
          ),

          // Risk Legend
          Positioned(
            left: 12,
            bottom: _selectedZone != null ? 260 : 100,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.darkCard.withAlpha(230),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Risk Level', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  ...[('CRITICAL', '🔴'), ('HIGH', '🟠'), ('MEDIUM', '🟡'), ('LOW', '🟢')].map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.$2, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(item.$1, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Selected Zone Bottom Sheet
          if (_selectedZone != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _StationBottomSheet(
                zone: _selectedZone!,
                onClose: () => setState(() => _selectedZone = null),
                onAnalyze: () {
                  ref.read(selectedLocationProvider.notifier).setCustomLocation(
                    latitude: _selectedZone!.latitude,
                    longitude: _selectedZone!.longitude,
                    name: _selectedZone!.name,
                    stateName: _selectedZone!.state,
                  );
                  ref.invalidate(currentPredictionProvider);
                },
              ),
            ),
        ],
      ),
    );
  }

  String _getRiskInitial(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'CRITICAL': return 'C';
      case 'HIGH': return 'H';
      case 'MEDIUM': return 'M';
      default: return 'L';
    }
  }
}

class _StationBottomSheet extends StatelessWidget {
  final RiskZone zone;
  final VoidCallback onClose;
  final VoidCallback? onAnalyze;

  const _StationBottomSheet({
    required this.zone,
    required this.onClose,
    this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getRiskColor(zone.riskLevel);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: color.withAlpha(80)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone.name,
                      style: const TextStyle(
                        color: AppColors.darkTextPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      zone.state,
                      style: const TextStyle(color: AppColors.darkTextMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, color: AppColors.darkTextMuted)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              RiskBadge(riskLevel: zone.riskLevel),
              const SizedBox(width: 12),
              Text(
                '${(zone.probability * 100).round()}% probability',
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (zone.elevationM != null || zone.slopeDegrees != null)
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (zone.elevationM != null)
                  _InfoChip(label: '${zone.elevationM!.toStringAsFixed(0)} m elevation'),
                if (zone.slopeDegrees != null)
                  _InfoChip(label: '${zone.slopeDegrees!.toStringAsFixed(1)}° slope'),
                if (zone.rainfall7d != null)
                  _InfoChip(label: '${zone.rainfall7d!.toStringAsFixed(0)} mm 7d rain'),
              ],
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAnalyze,
              icon: const Icon(Icons.radar_rounded, size: 18),
              label: const Text('Run ML Analysis for this Location'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkCardHover,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
    );
  }
}
