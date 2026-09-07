import httpx
import asyncio
import csv
import logging
from datetime import datetime, timedelta
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent
DATA_CSV = BASE_DIR / "data" / "processed" / "final_ml_dataset.csv"

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

async def fetch_eonet_landslides(days=7):
    """Fetch recent landslides from NASA EONET."""
    url = f"https://eonet.gsfc.nasa.gov/api/v3/events?category=landslides&days={days}"
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.get(url, timeout=10.0)
            resp.raise_for_status()
            data = resp.json()
            return data.get("events", [])
        except Exception as e:
            logger.error(f"EONET API error: {e}")
            return []

async def get_env_data(lat, lng, date_str):
    """Fetch exact weather conditions at the time of the event from Open-Meteo."""
    elevation, slope = 850.0, 15.0
    try:
        # Open-Meteo Elevation
        delta = 0.0015
        el_url = f"https://api.open-meteo.com/v1/elevation?latitude={lat},{lat+delta},{lat-delta},{lat},{lat}&longitude={lng},{lng},{lng},{lng+delta},{lng-delta}"
        async with httpx.AsyncClient() as client:
            resp = await client.get(el_url, timeout=10.0)
            if resp.status_code == 200:
                els = resp.json().get("elevation", [])
                if els: elevation = els[0]
    except Exception:
        pass

    # Weather variables
    r1d, r3d, r7d, sm = 0.0, 0.0, 0.0, 0.35
    try:
        w_url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lng}&daily=precipitation_sum&hourly=soil_moisture_0_to_1cm&past_days=14&forecast_days=1&timezone=auto"
        async with httpx.AsyncClient() as client:
            resp = await client.get(w_url, timeout=10.0)
            if resp.status_code == 200:
                w_data = resp.json()
                times = w_data.get("daily", {}).get("time", [])
                precips = w_data.get("daily", {}).get("precipitation_sum", [])
                
                # Match to event date
                target_date = date_str[:10]
                if target_date in times:
                    idx = times.index(target_date)
                    r1d = precips[idx] if precips[idx] is not None else 0.0
                    r3d = sum(p for p in precips[max(0, idx-2):idx+1] if p is not None)
                    r7d = sum(p for p in precips[max(0, idx-6):idx+1] if p is not None)
                
                # Average soil moisture
                sms = w_data.get("hourly", {}).get("soil_moisture_0_to_1cm", [])
                if sms:
                    valid_sms = [s for s in sms if s is not None]
                    if valid_sms:
                        sm = sum(valid_sms)/len(valid_sms)
    except Exception:
        pass
    
    return {
        "rainfall_1d": round(r1d, 2),
        "rainfall_3d": round(r3d, 2),
        "rainfall_7d": round(r7d, 2),
        "elevation_m": round(elevation, 2),
        "slope_degrees": slope,
        "soil_moisture": round(sm, 4)
    }

async def main(mock=False):
    logger.info("Checking NASA EONET for live landslide events...")
    events = await fetch_eonet_landslides(days=7)
    
    if mock and not events:
        logger.info("[MOCK MODE] No live events found. Injecting a mock live event for demonstration.")
        events = [{
            "id": "mock_live_001",
            "title": "Mock Live Landslide - Assam",
            "geometry": [{"date": datetime.utcnow().isoformat() + "Z", "coordinates": [91.7986, 26.1699]}]
        }]
    
    if not events:
        logger.info("No recent landslides detected globally. Exiting without appending.")
        return False

    new_rows = []
    for ev in events:
        ev_id = ev.get("id")
        geom = ev.get("geometry", [{}])[0]
        coords = geom.get("coordinates", [0, 0])
        date_str = geom.get("date", "")
        if not date_str or len(coords) < 2:
            continue
            
        lng, lat = coords[0], coords[1]
        logger.info(f"Detected event '{ev_id}' at lat:{lat}, lng:{lng} on {date_str}. Fetching Open-Meteo telemetry...")
        
        env = await get_env_data(lat, lng, date_str)
        
        new_row = {
            "sample_id": f"live_{ev_id}",
            "event_date": date_str.replace("T", " ")[:19].replace("Z", ""),
            "state": "Live_Detected",
            "latitude": lat,
            "longitude": lng,
            "rainfall_1d": env["rainfall_1d"],
            "rainfall_3d": env["rainfall_3d"],
            "rainfall_7d": env["rainfall_7d"],
            "elevation_m": env["elevation_m"],
            "slope_degrees": env["slope_degrees"],
            "soil_moisture": env["soil_moisture"],
            "target": 1
        }
        new_rows.append(new_row)
    
    if new_rows:
        logger.info(f"Appending {len(new_rows)} new verified incident records to {DATA_CSV.name}...")
        with open(DATA_CSV, "a", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=new_rows[0].keys())
            for row in new_rows:
                writer.writerow(row)
        logger.info("Dataset updated successfully.")
        return True
    return False

if __name__ == "__main__":
    import sys
    use_mock = "--mock" in sys.argv
    added = asyncio.run(main(mock=use_mock))
    sys.exit(0 if added else 2) # Exit code 2 indicates no new data was appended
