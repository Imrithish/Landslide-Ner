import csv
import math
import logging
import asyncio
from pathlib import Path
from typing import Optional, List, Dict, Any

from .base import RainfallProvider, TerrainProvider, SoilMoistureProvider

logger = logging.getLogger(__name__)

BASE_DIR = Path(__file__).resolve().parent.parent.parent

# Path to the local dataset
DATASET_PATH = BASE_DIR / "data" / "processed" / "final_ml_dataset.csv"

class LocalDatasetProvider(RainfallProvider, TerrainProvider, SoilMoistureProvider):
    def __init__(self):
        self.data = []
        self._load_data()

    def _load_data(self):
        if not DATASET_PATH.exists():
            logger.error(f"Dataset not found at {DATASET_PATH}")
            return

        try:
            with open(DATASET_PATH, "r", encoding="utf-8") as f:
                reader = csv.DictReader(f)
                for row in reader:
                    try:
                        lat = float(row["latitude"])
                        lng = float(row["longitude"])
                        r1d = float(row["rainfall_1d"]) if row["rainfall_1d"] else 0.0
                        r3d = float(row["rainfall_3d"]) if row["rainfall_3d"] else 0.0
                        r7d = float(row["rainfall_7d"]) if row["rainfall_7d"] else 0.0
                        elev = float(row["elevation_m"]) if row["elevation_m"] else 0.0
                        slope = float(row["slope_degrees"]) if row["slope_degrees"] else 0.0
                        sm = float(row["soil_moisture"]) if row["soil_moisture"] else 0.3
                        self.data.append({
                            "lat": lat,
                            "lng": lng,
                            "rainfall_1d": r1d,
                            "rainfall_3d": r3d,
                            "rainfall_7d": r7d,
                            "elevation_m": elev,
                            "slope_degrees": slope,
                            "soil_moisture": sm
                        })
                    except ValueError:
                        continue
            logger.info(f"Loaded {len(self.data)} records from {DATASET_PATH.name}")
        except Exception as e:
            logger.error(f"Failed to load dataset: {e}")

    def _find_nearest(self, latitude: float, longitude: float) -> dict:
        if not self.data:
            return {}

        def distance(item):
            # Simple Euclidean distance for fast lookup
            return (item["lat"] - latitude) ** 2 + (item["lng"] - longitude) ** 2

        nearest = min(self.data, key=distance)
        return nearest

    async def get(self, latitude: float, longitude: float) -> dict:
        nearest = self._find_nearest(latitude, longitude)
        if not nearest:
            return {"rainfall_1d": 0.0, "rainfall_3d": 0.0, "rainfall_7d": 0.0}
        return {
            "rainfall_1d": nearest["rainfall_1d"],
            "rainfall_3d": nearest["rainfall_3d"],
            "rainfall_7d": nearest["rainfall_7d"],
        }

    async def get_elevation_and_slope(self, latitude: float, longitude: float) -> dict:
        nearest = self._find_nearest(latitude, longitude)
        if not nearest:
            return {"elevation_m": 850.0, "slope_degrees": 15.0}
        return {
            "elevation_m": nearest["elevation_m"],
            "slope_degrees": nearest["slope_degrees"],
        }

    async def get_soil_moisture(self, latitude: float, longitude: float) -> Optional[float]:
        nearest = self._find_nearest(latitude, longitude)
        return nearest.get("soil_moisture", 0.3) if nearest else 0.3

    async def get_full_weather_forecast(self, latitude: float, longitude: float) -> Dict[str, Any]:
        """
        Simulate the full weather forecast structure using the nearest static data point.
        """
        nearest = self._find_nearest(latitude, longitude)
        
        r1d = nearest.get("rainfall_1d", 0.0) if nearest else 0.0
        r3d = nearest.get("rainfall_3d", 0.0) if nearest else 0.0
        r7d = nearest.get("rainfall_7d", 0.0) if nearest else 0.0
        sm = nearest.get("soil_moisture", 0.3418) if nearest else 0.3418

        return {
            "antecedent_rainfall": {
                "rainfall_1d": round(r1d, 2),
                "rainfall_3d": round(r3d, 2),
                "rainfall_7d": round(r7d, 2),
            },
            # Simulate flat past/future precip using average daily
            "past_daily_precip": [r7d / 7.0] * 7,
            "future_daily_precip": [r7d / 7.0] * 7,
            "future_dates": ["Day 1", "Day 2", "Day 3", "Day 4", "Day 5", "Day 6", "Day 7"],
            "hourly_soil_moisture": [sm] * (24 * 14),
            "current_soil_moisture": round(sm, 4),
            "river_discharge": [30.0] * 7
        }


dataset_provider = LocalDatasetProvider()
