"""
Dual-Frequency Processing (L-band and S-band)
Implements dual-frequency SAR processing for enhanced soil moisture estimation.
NISAR's unique dual-frequency (L+S band) capability provides complementary measurements.
"""

import numpy as np
import math
from typing import Dict, Any

# Frequency specifications
L_BAND = {
    "name": "L-band",
    "frequency_ghz": 1.257,
    "wavelength_cm": 23.8,
    "penetration_depth_cm": 50,
    "sensitivity": "Deep soil moisture, vegetation structure"
}

S_BAND = {
    "name": "S-band",
    "frequency_ghz": 3.226,
    "wavelength_cm": 9.3,
    "penetration_depth_cm": 15,
    "sensitivity": "Surface moisture, snow, ice"
}


def process_dual_frequency(
    l_band_backscatter: float,
    s_band_backscatter: float,
    incidence_angle: float = 35.0,
    vegetation_fraction: float = 0.5
) -> Dict[str, Any]:
    """
    Process dual-frequency L+S band data for enhanced soil moisture retrieval.

    The combination of L and S bands allows:
    - L-band: Penetrates vegetation, measures deeper soil moisture
    - S-band: More sensitive to surface conditions and vegetation water content
    """
    # Convert backscatter to soil moisture using semi-empirical model
    # L-band soil moisture (deeper, less affected by vegetation)
    l_moisture = _backscatter_to_moisture(
        l_band_backscatter,
        L_BAND["wavelength_cm"],
        incidence_angle,
        vegetation_fraction * 0.3  # L-band less affected by veg
    )

    # S-band soil moisture (surface, more vegetation effect)
    s_moisture = _backscatter_to_moisture(
        s_band_backscatter,
        S_BAND["wavelength_cm"],
        incidence_angle,
        vegetation_fraction * 0.7  # S-band more affected by veg
    )

    # Combined estimate (weighted fusion)
    # Higher weight to L-band in vegetated areas, S-band in bare soil
    l_weight = 0.6 + 0.2 * vegetation_fraction
    s_weight = 1.0 - l_weight
    combined_moisture = l_moisture * l_weight + s_moisture * s_weight

    # Vegetation water content from L-S difference
    vwc = max(0, (l_band_backscatter - s_band_backscatter + 5) * 0.3)

    # Root zone soil moisture extrapolation
    root_zone = combined_moisture * 1.15 + (l_moisture - s_moisture) * 0.5

    return {
        "l_band": {
            "backscatter_db": round(l_band_backscatter, 2),
            "soil_moisture_pct": round(l_moisture, 2),
            "depth_cm": L_BAND["penetration_depth_cm"],
            "frequency_ghz": L_BAND["frequency_ghz"]
        },
        "s_band": {
            "backscatter_db": round(s_band_backscatter, 2),
            "soil_moisture_pct": round(s_moisture, 2),
            "depth_cm": S_BAND["penetration_depth_cm"],
            "frequency_ghz": S_BAND["frequency_ghz"]
        },
        "combined": {
            "soil_moisture_pct": round(combined_moisture, 2),
            "confidence": round(min(0.95, 0.7 + 0.1 * (1 - abs(l_moisture - s_moisture) / 20)), 3),
            "method": "Weighted_Dual_Frequency_Fusion"
        },
        "derived": {
            "vegetation_water_content_kg_m2": round(vwc, 2),
            "root_zone_moisture_pct": round(max(0, min(60, root_zone)), 2),
            "surface_roughness_indicator": round(abs(l_band_backscatter - s_band_backscatter) * 0.1, 3)
        }
    }


def _backscatter_to_moisture(
    sigma_db: float,
    wavelength_cm: float,
    theta: float,
    veg_attenuation: float
) -> float:
    """
    Convert radar backscatter to volumetric soil moisture.
    Uses modified Dubois/Oh model approach.
    """
    # Remove vegetation attenuation
    sigma_soil = sigma_db + veg_attenuation * 3.0

    # Empirical backscatter-to-moisture relationship
    # Typical range: -25 dB (dry) to -5 dB (saturated)
    theta_rad = math.radians(theta)

    # Normalized to 0-60% volumetric water content
    moisture = (sigma_soil + 25) / 20.0 * 40.0

    # Wavelength correction (longer wavelength = deeper sensing)
    moisture *= (1.0 + 0.02 * (wavelength_cm - 10))

    # Incidence angle correction
    moisture *= (1.0 + 0.1 * math.cos(theta_rad))

    return max(1.0, min(58.0, moisture + np.random.normal(0, 2)))


def generate_dual_freq_grid(grid_points: list) -> list:
    """Generate dual-frequency estimates for a grid of points."""
    results = []
    for point in grid_points:
        lat = point.get("lat", 0)
        lon = point.get("lon", 0)
        moisture = point.get("soil_moisture", 25)

        # Simulate backscatter from moisture
        l_sigma = -25 + moisture * 0.5 + np.random.normal(0, 1.5)
        s_sigma = -23 + moisture * 0.45 + np.random.normal(0, 1.2)

        veg_frac = point.get("vegetation_fraction", 0.5)
        dual = process_dual_frequency(l_sigma, s_sigma, 35.0, veg_frac)

        results.append({
            "lat": lat,
            "lon": lon,
            "dual_frequency": dual
        })

    return results
