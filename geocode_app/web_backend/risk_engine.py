"""
Risk scoring engine for flood, landslide, and drought hazards.
Implements deterministic algorithms based on satellite metrics.
"""
import logging
from typing import Dict, Any, Optional, Literal

logger = logging.getLogger(__name__)


class RiskEngine:
    """Deterministic hazard risk scoring engine"""

    @staticmethod
    def normalize(value: Optional[float], min_val: float, max_val: float) -> float:
        """
        Normalize a value to 0-100 scale.
        Handles None values gracefully.
        """
        if value is None or value != value:  # NaN check
            return 0.0

        if value <= min_val:
            return 0.0
        elif value >= max_val:
            return 100.0
        else:
            return ((value - min_val) / (max_val - min_val)) * 100.0

    @staticmethod
    def _safe_divide(numerator: Optional[float], denominator: Optional[float], default: float = 0.0) -> float:
        """Safely divide two values, handling None and NaN"""
        if numerator is None or denominator is None:
            return default
        if numerator != numerator or denominator != denominator:  # NaN check
            return default
        if denominator == 0:
            return default
        return numerator / denominator

    @staticmethod
    def calculate_flood_risk(
        precipitation_24h: Optional[float],
        soil_moisture: Optional[float],
        elevation: Optional[float],
        slope: Optional[float]
    ) -> tuple[float, Dict[str, float]]:
        """
        Calculate flood risk score (0-100%).

        Triggers:
        - High precipitation (>50mm/day)
        - High soil moisture (>70%)
        - Low elevation (<100m) or low slope (<5°)

        Formula: (precip_factor * 0.4) + (moisture_factor * 0.35) + (elevation_factor * 0.25)
        """
        factors = {}

        # Precipitation factor (0-100)
        # Threshold: 50mm/day
        precip_factor = RiskEngine.normalize(precipitation_24h, 0, 100)
        factors["precipitation"] = precip_factor

        # Soil moisture factor (0-100)
        # Threshold: 70% saturation
        moisture_factor = RiskEngine.normalize(soil_moisture, 40, 90)
        factors["soil_moisture"] = moisture_factor

        # Elevation factor (0-100)
        # Lower elevation = higher flood risk
        # Tamil Nadu ranges from 0-2600m
        elevation_factor = 100 - RiskEngine.normalize(elevation, 0, 500)
        factors["elevation"] = elevation_factor

        # Slope factor (0-100)
        # Lower slope = higher flood risk (water accumulates)
        slope_factor = 100 - RiskEngine.normalize(slope, 0, 20)
        factors["slope"] = slope_factor

        # Weighted combination
        flood_score = (
            (precip_factor * 0.4) +
            (moisture_factor * 0.35) +
            ((elevation_factor + slope_factor) / 2 * 0.25)
        )

        flood_score = max(0, min(100, flood_score))
        logger.info(f"Flood risk: {flood_score:.1f}% | Precip: {precip_factor:.0f}%, Moisture: {moisture_factor:.0f}%")

        return flood_score, factors

    @staticmethod
    def calculate_landslide_risk(
        slope: Optional[float],
        soil_moisture: Optional[float],
        insar_deformation: Optional[float],
        precipitation_24h: Optional[float]
    ) -> tuple[float, Dict[str, float]]:
        """
        Calculate landslide risk score (0-100%).

        Triggers:
        - Steep slope (>15°)
        - Soil saturation (>80% moisture)
        - Active ground deformation (>2mm/year subsidence)
        - High precipitation

        Formula: (slope_factor * 0.4) + (saturation_factor * 0.35) + (deformation_factor * 0.25)
        """
        factors = {}

        # Slope factor (0-100)
        # Threshold: >15° is high risk
        slope_factor = RiskEngine.normalize(slope, 0, 30)
        factors["slope"] = slope_factor

        # Saturation factor (0-100)
        # Threshold: >80% moisture indicates super-saturation
        saturation_factor = RiskEngine.normalize(soil_moisture, 60, 95)
        factors["saturation"] = saturation_factor

        # Deformation factor (0-100)
        # Subsidence (negative values) indicates instability
        # More than 2mm/year is concerning
        if insar_deformation is not None and insar_deformation < 0:
            deformation_factor = min(100, abs(insar_deformation) * 20)
        else:
            deformation_factor = 0
        factors["deformation"] = deformation_factor

        # Precipitation factor (secondary)
        # High rainfall can trigger slides
        precip_factor = RiskEngine.normalize(precipitation_24h, 0, 50)

        # Weighted combination
        landslide_score = (
            (slope_factor * 0.4) +
            (saturation_factor * 0.35) +
            (deformation_factor * 0.25)
        )

        # Boost if high precipitation + steep slope
        if precip_factor > 50 and slope_factor > 50:
            landslide_score = min(100, landslide_score * 1.2)

        landslide_score = max(0, min(100, landslide_score))
        logger.info(f"Landslide risk: {landslide_score:.1f}% | Slope: {slope_factor:.0f}%, Saturation: {saturation_factor:.0f}%")

        return landslide_score, factors

    @staticmethod
    def calculate_drought_risk(
        soil_moisture: Optional[float],
        ndvi: Optional[float],
        temperature: Optional[float],
        precipitation_24h: Optional[float]
    ) -> tuple[float, Dict[str, float]]:
        """
        Calculate drought risk score (0-100%).

        Triggers:
        - Very low soil moisture (<15%)
        - Poor vegetation health (NDVI <0.3)
        - High temperature anomaly
        - Low precipitation

        Formula: (moisture_deficit * 0.45) + (ndvi_loss * 0.35) + (temp_anomaly * 0.20)
        """
        factors = {}

        # Moisture deficit factor (0-100)
        # Inverse of moisture: low moisture = high risk
        # Threshold: <15% is critical
        moisture_factor = 100 - RiskEngine.normalize(soil_moisture, 10, 60)
        factors["moisture_deficit"] = moisture_factor

        # NDVI loss factor (0-100)
        # Low NDVI indicates stressed vegetation
        # Threshold: <0.3 is poor vegetation
        ndvi_factor = 100 - RiskEngine.normalize(ndvi, 0.1, 0.7) if ndvi is not None else 50
        factors["ndvi_loss"] = ndvi_factor

        # Temperature anomaly factor (0-100)
        # Tamil Nadu average: ~27°C
        # Deviation from normal indicates stress
        temp_anomaly = max(0, (temperature - 28) * 2) if temperature is not None else 0
        temp_factor = RiskEngine.normalize(temp_anomaly, 0, 10)
        factors["temperature"] = temp_factor

        # Precipitation factor (inverse)
        # Low precipitation indicates drought
        precip_factor = 100 - RiskEngine.normalize(precipitation_24h, 0, 5)
        factors["precipitation"] = precip_factor

        # Weighted combination
        drought_score = (
            (moisture_factor * 0.45) +
            (ndvi_factor * 0.35) +
            (temp_factor * 0.20)
        )

        drought_score = max(0, min(100, drought_score))
        logger.info(f"Drought risk: {drought_score:.1f}% | Moisture deficit: {moisture_factor:.0f}%, NDVI loss: {ndvi_factor:.0f}%")

        return drought_score, factors

    @staticmethod
    def get_risk_level(score: float) -> Literal["LOW", "MODERATE", "HIGH", "CRITICAL"]:
        """Convert risk score to risk level"""
        if score < 30:
            return "LOW"
        elif score < 60:
            return "MODERATE"
        elif score < 80:
            return "HIGH"
        else:
            return "CRITICAL"

    @staticmethod
    def calculate_all_hazards(metrics: Dict[str, Any]) -> Dict[str, Dict[str, Any]]:
        """
        Calculate all three hazard risks for given metrics.

        Returns: Dictionary with flood, landslide, drought assessments
        """
        results = {}

        # Flood Risk
        flood_score, flood_factors = RiskEngine.calculate_flood_risk(
            metrics.get("precipitation_24h"),
            metrics.get("soil_moisture"),
            metrics.get("elevation"),
            metrics.get("slope")
        )
        results["flood"] = {
            "score": flood_score,
            "level": RiskEngine.get_risk_level(flood_score),
            "factors": flood_factors
        }

        # Landslide Risk
        landslide_score, landslide_factors = RiskEngine.calculate_landslide_risk(
            metrics.get("slope"),
            metrics.get("soil_moisture"),
            metrics.get("insar_deformation"),
            metrics.get("precipitation_24h")
        )
        results["landslide"] = {
            "score": landslide_score,
            "level": RiskEngine.get_risk_level(landslide_score),
            "factors": landslide_factors
        }

        # Drought Risk
        drought_score, drought_factors = RiskEngine.calculate_drought_risk(
            metrics.get("soil_moisture"),
            metrics.get("ndvi"),
            metrics.get("temperature"),
            metrics.get("precipitation_24h")
        )
        results["drought"] = {
            "score": drought_score,
            "level": RiskEngine.get_risk_level(drought_score),
            "factors": drought_factors
        }

        return results
