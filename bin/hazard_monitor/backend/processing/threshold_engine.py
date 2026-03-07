"""
Threshold Engine
Configurable threshold-based hazard detection system.
Implements multi-parameter thresholds for drought, flood, and landslide alerts.
"""

from typing import Dict, Any, List


# Default threshold configuration
THRESHOLDS = {
    "drought": {
        "soil_moisture_critical": 8.0,    # < 8% = critical drought
        "soil_moisture_severe": 12.0,     # < 12% = severe drought
        "soil_moisture_moderate": 18.0,   # < 18% = moderate drought
        "ndvi_stressed": 0.2,             # NDVI < 0.2 = vegetation stress
        "precipitation_low_mm": 2.0       # < 2mm daily = dry conditions
    },
    "flood": {
        "soil_moisture_critical": 48.0,   # > 48% = critical flood risk
        "soil_moisture_severe": 42.0,     # > 42% = severe flood risk
        "soil_moisture_moderate": 38.0,   # > 38% = moderate flood risk
        "precipitation_high_mm": 50.0,    # > 50mm daily = heavy rain
        "runoff_critical_mm": 8.0,        # > 8mm runoff = flood
        "runoff_high_mm": 5.0             # > 5mm runoff = high risk
    },
    "landslide": {
        "slope_critical_deg": 35.0,       # > 35° slope
        "slope_high_deg": 25.0,           # > 25° slope
        "moisture_trigger": 35.0,         # soil moisture > 35% on steep slope
        "displacement_mm": 5.0,           # InSAR displacement > 5mm
        "combined_threshold": 70          # combined risk score > 70
    }
}


def evaluate_point(
    soil_moisture: float,
    slope: float = 0.0,
    precipitation: float = 0.0,
    ndvi: float = 0.5,
    displacement: float = 0.0,
    runoff: float = 0.0
) -> Dict[str, Any]:
    """
    Evaluate all hazard thresholds for a single point.
    Returns alerts for each hazard type.
    """
    alerts = []
    risk_score = 0

    # --- DROUGHT ASSESSMENT ---
    t = THRESHOLDS["drought"]
    if soil_moisture < t["soil_moisture_critical"]:
        alerts.append({
            "type": "DROUGHT", "severity": "CRITICAL",
            "message": f"Critical drought: soil moisture {soil_moisture:.1f}% (threshold: {t['soil_moisture_critical']}%)",
            "score": 95
        })
        risk_score = max(risk_score, 95)
    elif soil_moisture < t["soil_moisture_severe"]:
        alerts.append({
            "type": "DROUGHT", "severity": "SEVERE",
            "message": f"Severe drought risk: soil moisture {soil_moisture:.1f}%",
            "score": 75
        })
        risk_score = max(risk_score, 75)
    elif soil_moisture < t["soil_moisture_moderate"]:
        drought_score = 50 if ndvi < t["ndvi_stressed"] else 40
        alerts.append({
            "type": "DROUGHT", "severity": "MODERATE",
            "message": f"Moderate drought risk: soil moisture {soil_moisture:.1f}%",
            "score": drought_score
        })
        risk_score = max(risk_score, drought_score)

    # --- FLOOD ASSESSMENT ---
    t = THRESHOLDS["flood"]
    flood_factors = 0
    if soil_moisture > t["soil_moisture_critical"]:
        flood_factors += 3
    elif soil_moisture > t["soil_moisture_severe"]:
        flood_factors += 2
    elif soil_moisture > t["soil_moisture_moderate"]:
        flood_factors += 1

    if precipitation > t["precipitation_high_mm"]:
        flood_factors += 2
    if runoff > t["runoff_critical_mm"]:
        flood_factors += 3
    elif runoff > t["runoff_high_mm"]:
        flood_factors += 1

    if flood_factors >= 5:
        flood_score = 95
        severity = "CRITICAL"
    elif flood_factors >= 3:
        flood_score = 75
        severity = "SEVERE"
    elif flood_factors >= 2:
        flood_score = 55
        severity = "MODERATE"
    elif flood_factors >= 1:
        flood_score = 35
        severity = "LOW"
    else:
        flood_score = 0
        severity = None

    if severity:
        alerts.append({
            "type": "FLOOD", "severity": severity,
            "message": f"Flood risk ({severity}): moisture={soil_moisture:.1f}%, precip={precipitation:.1f}mm, runoff={runoff:.1f}mm",
            "score": flood_score
        })
        risk_score = max(risk_score, flood_score)

    # --- LANDSLIDE ASSESSMENT ---
    t = THRESHOLDS["landslide"]
    landslide_score = 0

    if slope > t["slope_critical_deg"]:
        landslide_score += 40
    elif slope > t["slope_high_deg"]:
        landslide_score += 25

    if soil_moisture > t["moisture_trigger"] and slope > 15:
        landslide_score += 30

    if displacement > t["displacement_mm"]:
        landslide_score += 30

    if precipitation > 30 and slope > 20:
        landslide_score += 15

    if landslide_score > 0:
        if landslide_score >= 80:
            ls_severity = "CRITICAL"
        elif landslide_score >= 60:
            ls_severity = "SEVERE"
        elif landslide_score >= 40:
            ls_severity = "MODERATE"
        else:
            ls_severity = "LOW"

        alerts.append({
            "type": "LANDSLIDE", "severity": ls_severity,
            "message": f"Landslide risk ({ls_severity}): slope={slope:.1f}°, moisture={soil_moisture:.1f}%, deformation={displacement:.1f}mm",
            "score": landslide_score
        })
        risk_score = max(risk_score, landslide_score)

    # Overall classification
    if risk_score >= 80:
        overall = "CRITICAL"
    elif risk_score >= 60:
        overall = "HIGH"
    elif risk_score >= 40:
        overall = "MODERATE"
    elif risk_score >= 20:
        overall = "LOW"
    else:
        overall = "SAFE"

    return {
        "risk_score": risk_score,
        "overall_risk": overall,
        "alerts": alerts,
        "parameters": {
            "soil_moisture": soil_moisture,
            "slope": slope,
            "precipitation": precipitation,
            "ndvi": ndvi,
            "displacement": displacement,
            "runoff": runoff
        }
    }
