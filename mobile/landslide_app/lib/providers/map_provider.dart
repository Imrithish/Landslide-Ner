import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'alert_provider.dart';
import '../models/risk_zone.dart';

class MapFilterState {
  final String? selectedState;
  final String? selectedRiskLevel;
  final double minProbability;
  final bool showHeatmap;

  MapFilterState({
    this.selectedState,
    this.selectedRiskLevel,
    this.minProbability = 0.0,
    this.showHeatmap = false,
  });

  MapFilterState copyWith({
    String? selectedState,
    String? selectedRiskLevel,
    double? minProbability,
    bool? showHeatmap,
  }) {
    return MapFilterState(
      selectedState: selectedState ?? this.selectedState,
      selectedRiskLevel: selectedRiskLevel ?? this.selectedRiskLevel,
      minProbability: minProbability ?? this.minProbability,
      showHeatmap: showHeatmap ?? this.showHeatmap,
    );
  }
}

class MapFilterNotifier extends StateNotifier<MapFilterState> {
  MapFilterNotifier() : super(MapFilterState());

  void setStateFilter(String? stateName) {
    state = state.copyWith(selectedState: stateName == 'All States' ? null : stateName);
  }

  void setRiskLevelFilter(String? riskLevel) {
    state = state.copyWith(selectedRiskLevel: riskLevel == 'ALL' ? null : riskLevel);
  }

  void toggleHeatmap() {
    state = state.copyWith(showHeatmap: !state.showHeatmap);
  }

  void setMinProbability(double prob) {
    state = state.copyWith(minProbability: prob);
  }
}

final mapFilterProvider = StateNotifierProvider<MapFilterNotifier, MapFilterState>((ref) {
  return MapFilterNotifier();
});

final filteredRiskZonesProvider = Provider<AsyncValue<List<RiskZone>>>((ref) {
  final rawZonesAsync = ref.watch(riskZonesProvider);
  final filter = ref.watch(mapFilterProvider);

  return rawZonesAsync.whenData((zones) {
    return zones.where((zone) {
      if (filter.selectedState != null &&
          zone.state.toLowerCase() != filter.selectedState!.toLowerCase()) {
        return false;
      }
      if (filter.selectedRiskLevel != null &&
          zone.riskLevel.toUpperCase() != filter.selectedRiskLevel!.toUpperCase()) {
        return false;
      }
      if (zone.probability < filter.minProbability) {
        return false;
      }
      return true;
    }).toList();
  });
});
