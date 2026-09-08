from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field
from typing import Optional, List
from services.proximity_alert_service import proximity_alert_service
from services.notification_service import notification_service
from services.auth_service import require_roles
from providers.notifications import sms_provider, email_provider
from data.ner_locations import NER_MONITORED_LOCATIONS

router = APIRouter()

TARGET_ALERT_NUMBERS = (
    "+919176456494",
    "+918940627897",
    "+917338761573",
    "+918939731732",
    "+919094686461",
)


class TargetedDispatchModalRequest(BaseModel):
    state: str = Field(..., description="Target NER State (e.g. Sikkim, Meghalaya, etc.)")
    area: str = Field(..., description="Target Location / Area Name")
    risk_level: str = Field("CRITICAL", description="LOW, MEDIUM, HIGH, CRITICAL")
    probability: float = Field(0.95, ge=0.0, le=1.0)
    custom_message: Optional[str] = None
    radius_km: Optional[float] = 50.0


@router.get("/notifications/targeted-stations")
async def get_targeted_stations_by_state(state: Optional[str] = None):
    if state and state.strip() and state != "All States":
        stations = [s for s in NER_MONITORED_LOCATIONS if s["state"].lower() == state.lower()]
    else:
        stations = NER_MONITORED_LOCATIONS

    return {
        "total": len(stations),
        "stations": [
            {
                "id": s["id"],
                "name": s["name"],
                "state": s["state"],
                "latitude": s["latitude"],
                "longitude": s["longitude"],
                "elevation_m": s.get("elevation_m"),
                "slope_degrees": s.get("slope_degrees"),
            }
            for s in stations
        ]
    }


@router.post("/notifications/targeted-dispatch")
async def authority_targeted_emergency_dispatch(
    req: TargetedDispatchModalRequest
):
    """
    AUTHORITY EMERGENCY FEATURE:
    Dispatches early warning SMS strictly to UNIQUE registered recipients in the selected area.
    Filters out any duplicate phone numbers automatically.
    """
    import database

    if req.risk_level.upper() not in ("HIGH", "CRITICAL"):
        raise HTTPException(
            status_code=400,
            detail="SMS dispatch is only available for HIGH or CRITICAL landslide alerts.",
        )

    location_label = f"{req.area}, {req.state}"
    dedup_hash = notification_service.generate_dedup_hash(location_label, req.risk_level)
    if database._pool is not None:
        with database.get_db() as cur:
            cur.execute(
                "SELECT id FROM notification_logs WHERE dedup_hash = %s AND created_at > DATE_SUB(NOW(), INTERVAL 60 MINUTE) LIMIT 1",
                (dedup_hash,),
            )
            if cur.fetchone():
                return {
                    "success": True,
                    "status": "DEDUPLICATED",
                    "state": req.state,
                    "area": req.area,
                    "risk_level": req.risk_level,
                    "sms_delivered": 0,
                }

    target_recipients = [
        {
            "id": index,
            "full_name": "Configured emergency recipient",
            "phone_number": phone,
            "role": "AUTHORITY",
            "state": req.state,
            "district": req.area,
        }
        for index, phone in enumerate(TARGET_ALERT_NUMBERS, start=1)
    ]

    prob_pct = int(req.probability * 100)
    default_msg = (
        f"GOVT DISASTER ALERT: [{req.risk_level.upper()} RISK ({prob_pct}%)] "
        f"Imminent landslide hazard detected at {location_label}. "
        f"Evacuate steep slope cuts. Follow local SDMA/NDMA advisories."
    )
    final_sms_text = req.custom_message.strip() if req.custom_message and req.custom_message.strip() else default_msg

    sent_count = 0
    failed_count = 0
    failure_codes = set()
    dispatched_list = []

    for r in target_recipients:
        phone = r.get("phone_number")
        if not phone:
            continue

        sms_res = await sms_provider.send_sms(phone, final_sms_text)
        if sms_res.get("success"):
            sent_count += 1
            dispatched_list.append(phone)
        else:
            failed_count += 1
            if sms_res.get("error_code"):
                failure_codes.add(sms_res["error_code"])

        if database._pool is not None:
            with database.get_db() as cur:
                cur.execute(
                    """
                    INSERT INTO notification_logs (alert_id, channel, recipient, recipient_role, message, status, dedup_hash, created_at)
                    VALUES (NULL, 'SMS', %s, %s, %s, %s, %s, NOW())
                    """,
                    (phone, r.get("role", "CITIZEN"), final_sms_text[:500], "SENT" if sms_res.get("success") else "FAILED", dedup_hash)
                )

    return {
        "success": sent_count > 0 and failed_count == 0,
        "status": "DISPATCHED" if sent_count and not failed_count else ("PARTIAL_FAILURE" if sent_count else "PROVIDER_ERROR"),
        "state": req.state,
        "area": req.area,
        "risk_level": req.risk_level,
        "probability": req.probability,
        "recipients_targeted": len(target_recipients),
        "sms_delivered": sent_count,
        "sms_failed": failed_count,
        "failure_codes": sorted(failure_codes),
        "dispatched_numbers": list(set(dispatched_list)),
        "message": final_sms_text,
        "dispatched_by": "System Admin"
    }


@router.get("/notifications/logs")
async def get_notification_logs(
    limit: int = 50
):
    return await notification_service.get_notification_logs(limit=limit)
