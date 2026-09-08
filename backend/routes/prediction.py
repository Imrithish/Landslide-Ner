import logging
import os
from typing import Optional
from fastapi import APIRouter, HTTPException, Query
from schemas.prediction import LocationRequest, PredictionResponse, MultiHazardForecastResponse
from services.prediction_service import prediction_service

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/predictions", response_model=PredictionResponse)
async def predict_landslide_risk(location: LocationRequest):
    """
    Predict landslide risk for a given location using the trained Random Forest model.
    """
    try:
        prediction = await prediction_service.predict_landslide_risk(
            latitude=location.latitude,
            longitude=location.longitude,
            rainfall_1d=location.rainfall_1d,
            rainfall_3d=location.rainfall_3d,
            rainfall_7d=location.rainfall_7d,
            elevation_m=location.elevation_m,
            slope_degrees=location.slope_degrees,
            soil_moisture=location.soil_moisture,
        )

        # Persist prediction in MySQL if available
        import database
        if database._pool is not None:
            try:
                with database.get_db() as cur:
                    cur.execute(
                        """
                        INSERT INTO predictions (
                            prediction_id, latitude, longitude, risk_level, probability, confidence,
                            rainfall_1d, rainfall_3d, rainfall_7d, elevation_m, slope_degrees, soil_moisture,
                            explanation, model_name, model_version, created_at
                        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
                        """,
                        (
                            prediction.prediction_id,
                            prediction.latitude,
                            prediction.longitude,
                            prediction.risk_level,
                            prediction.probability,
                            prediction.confidence,
                            prediction.features.rainfall_1d,
                            prediction.features.rainfall_3d,
                            prediction.features.rainfall_7d,
                            prediction.features.elevation_m,
                            prediction.features.slope_degrees,
                            prediction.features.soil_moisture,
                            prediction.explanation,
                            prediction.model_name,
                            prediction.model_version,
                        )
                    )
            except Exception as db_err:
                logger.warning("Could not persist prediction to database: %s", db_err)

        return prediction
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        logger.error("Prediction failed: %s", e, exc_info=True)
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")


@router.get("/predictions/history")
async def get_prediction_history(
    limit: int = Query(20, ge=1, le=100),
    risk_level: Optional[str] = Query(None, description="Filter by risk level: LOW, MEDIUM, HIGH, CRITICAL")
):
    """Get recent prediction history from database."""
    import database
    if database._pool is None:
        return {"total": 0, "history": []}

    try:
        with database.get_db() as cur:
            if risk_level:
                cur.execute(
                    """
                    SELECT prediction_id, latitude, longitude, risk_level, probability, confidence,
                           rainfall_1d, rainfall_3d, rainfall_7d, elevation_m, slope_degrees, soil_moisture,
                           explanation, model_name, model_version, created_at
                    FROM predictions
                    WHERE risk_level = %s
                    ORDER BY created_at DESC
                    LIMIT %s
                    """,
                    (risk_level.upper(), limit)
                )
            else:
                cur.execute(
                    """
                    SELECT prediction_id, latitude, longitude, risk_level, probability, confidence,
                           rainfall_1d, rainfall_3d, rainfall_7d, elevation_m, slope_degrees, soil_moisture,
                           explanation, model_name, model_version, created_at
                    FROM predictions
                    ORDER BY created_at DESC
                    LIMIT %s
                    """,
                    (limit,)
                )
            rows = cur.fetchall()

        history = []
        for r in rows:
            history.append({
                "prediction_id": r["prediction_id"],
                "latitude": float(r["latitude"]),
                "longitude": float(r["longitude"]),
                "risk_level": r["risk_level"],
                "probability": float(r["probability"]),
                "confidence": float(r["confidence"]),
                "features": {
                    "rainfall_1d": float(r["rainfall_1d"]) if r.get("rainfall_1d") is not None else None,
                    "rainfall_3d": float(r["rainfall_3d"]) if r.get("rainfall_3d") is not None else None,
                    "rainfall_7d": float(r["rainfall_7d"]) if r.get("rainfall_7d") is not None else None,
                    "elevation_m": float(r["elevation_m"]) if r.get("elevation_m") is not None else None,
                    "slope_degrees": float(r["slope_degrees"]) if r.get("slope_degrees") is not None else None,
                    "soil_moisture": float(r["soil_moisture"]) if r.get("soil_moisture") is not None else None,
                },
                "explanation": r.get("explanation", ""),
                "model_name": r.get("model_name", "landslide-rf-final"),
                "model_version": r.get("model_version", "1.0.0"),
                "created_at": r["created_at"].isoformat() + "Z" if hasattr(r["created_at"], "isoformat") else str(r["created_at"])
            })
        return {"total": len(history), "history": history}
    except Exception as exc:
        logger.error("Failed to fetch prediction history: %s", exc)
        return {"total": 0, "history": []}


@router.post("/predictions/multi-hazard-forecast", response_model=MultiHazardForecastResponse)
async def predict_multi_hazard_forecast(location: LocationRequest):
    """
    FUTURE RISK PREDICTION ENGINE:
    Evaluates rolling multi-day ML model inference for:
    - 24-hour Landslide Risk Forecast
    - 48-hour Landslide Risk Forecast
    - 72-hour Landslide Risk Forecast
    - 7-Day Rainfall Surge (mm) & Soil Saturation
    - 7-Day Flash Flood Susceptibility Score & Risk Level
    """
    try:
        return await prediction_service.predict_multi_hazard_forecast(
            latitude=location.latitude,
            longitude=location.longitude
        )
    except Exception as e:
        logger.error("Multi-hazard forecast failed: %s", e, exc_info=True)
        raise HTTPException(status_code=500, detail=f"Multi-hazard forecast failed: {str(e)}")


@router.get("/predictions/model-info")
async def get_model_info():
    """Get current ML model metadata and feature specification."""
    from ml.FEATURES import (
        FEATURE_NAMES, FEATURE_UNITS, FEATURE_TRAINING_RANGES,
        IMPUTER_MEDIANS, RISK_THRESHOLDS
    )
    svc = prediction_service
    return {
        "model_name": svc.model_name,
        "model_version": svc.model_version,
        "status": "live" if svc._model is not None else "unavailable",
        "features": {
            name: {
                "unit": FEATURE_UNITS[name],
                "training_range": list(FEATURE_TRAINING_RANGES[name]),
                "imputer_median": IMPUTER_MEDIANS[name],
            }
            for name in FEATURE_NAMES
        },
        "feature_order": FEATURE_NAMES,
        "risk_thresholds": RISK_THRESHOLDS,
        "soil_moisture_scale": "fraction (0.0 - 1.0, volumetric m3/m3)",
    }
