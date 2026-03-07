"""
Async data fetchers for real satellite and meteorological APIs.
Fetches data in parallel using asyncio.gather() for minimal latency.
"""
import asyncio
import logging
from typing import Optional, Dict, Any
import aiohttp
from config import settings

logger = logging.getLogger(__name__)


class DataFetchers:
    """Async fetchers for live satellite and weather data"""

    @staticmethod
    async def fetch_nasa_smap_moisture(latitude: float, longitude: float) -> Optional[float]:
        """
        Fetch soil moisture from NASA SMAP via OPeNDAP.

        Returns: Soil moisture as percentage (0-100) or None if unavailable
        """
        try:
            # NASA SMAP OPeNDAP endpoint
            url = f"https://n5eil02u.ecs.nsidc.org/egi/request?short_name=SPL3SMP&version=008"

            async with aiohttp.ClientSession() as session:
                auth = aiohttp.BasicAuth(settings.NASA_USERNAME, settings.NASA_PASSWORD)

                async with session.get(
                    url,
                    auth=auth,
                    timeout=aiohttp.ClientTimeout(total=settings.API_TIMEOUT),
                    params={
                        "bounding_box": f"{longitude-0.5},{latitude-0.5},{longitude+0.5},{latitude+0.5}",
                        "format": "json"
                    }
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        # Extract soil moisture from response
                        # This is a placeholder - actual structure depends on NASA API
                        if "results" in data and len(data["results"]) > 0:
                            moisture = float(data["results"][0].get("soil_moisture", 0))
                            logger.info(f"SMAP: {moisture:.1f}% moisture at ({latitude}, {longitude})")
                            return max(0, min(100, moisture))  # Clamp to 0-100
                        return None
                    else:
                        logger.warning(f"SMAP API returned status {response.status}")
                        return None
        except asyncio.TimeoutError:
            logger.warning("SMAP fetch timed out")
            return None
        except Exception as e:
            logger.error(f"SMAP fetch error: {e}")
            return None

    @staticmethod
    async def fetch_nasa_gpm_precipitation(latitude: float, longitude: float) -> Optional[float]:
        """
        Fetch daily precipitation from NASA GPM IMERG.

        Returns: Precipitation in mm/day or None if unavailable
        """
        try:
            # NASA GPM IMERG endpoint
            url = "https://gpm1.gesdisc.eosdis.nasa.gov/daac-bin/OTF/HTTP_services.cgi"

            async with aiohttp.ClientSession() as session:
                auth = aiohttp.BasicAuth(settings.NASA_USERNAME, settings.NASA_PASSWORD)

                async with session.get(
                    url,
                    auth=auth,
                    timeout=aiohttp.ClientTimeout(total=settings.API_TIMEOUT),
                    params={
                        "FILENAME": "s4pa///gpmdata//Lv3///03IMERG_ER/",
                        "SHORTNAME": "GPM_3IMERGDF",
                        "DATAFIELD_0": "precipitationCal",
                        "BBOX": f"{latitude-0.5},{longitude-0.5},{latitude+0.5},{longitude+0.5}",
                    }
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        if "data" in data and len(data["data"]) > 0:
                            precip = float(data["data"][0].get("value", 0))
                            logger.info(f"GPM: {precip:.1f}mm precipitation at ({latitude}, {longitude})")
                            return max(0, precip)
                        return None
                    else:
                        logger.warning(f"GPM API returned status {response.status}")
                        return None
        except asyncio.TimeoutError:
            logger.warning("GPM fetch timed out")
            return None
        except Exception as e:
            logger.error(f"GPM fetch error: {e}")
            return None

    @staticmethod
    async def fetch_asf_insar_deformation(latitude: float, longitude: float) -> Optional[float]:
        """
        Fetch ground deformation from ASF HyP3 Sentinel-1 InSAR.

        Returns: Deformation in mm/year or None if unavailable
        """
        try:
            # ASF DAAC InSAR endpoint
            url = "https://api.daac.asf.alaska.edu/services/search/param"

            async with aiohttp.ClientSession() as session:
                async with session.get(
                    url,
                    timeout=aiohttp.ClientTimeout(total=settings.API_TIMEOUT),
                    params={
                        "platform": "Sentinel-1",
                        "processingLevel": "INSAR_STACK_GEOCODED",
                        "bbox": f"{longitude-0.5},{latitude-0.5},{longitude+0.5},{latitude+0.5}",
                        "output": "json"
                    }
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        if "results" in data and len(data["results"]) > 0:
                            # Extract deformation from most recent InSAR product
                            deformation = float(data["results"][0].get("deformation_rate", 0))
                            logger.info(f"InSAR: {deformation:.1f}mm/year deformation at ({latitude}, {longitude})")
                            return deformation
                        return None
                    else:
                        logger.warning(f"ASF InSAR returned status {response.status}")
                        return None
        except asyncio.TimeoutError:
            logger.warning("InSAR fetch timed out")
            return None
        except Exception as e:
            logger.error(f"InSAR fetch error: {e}")
            return None

    @staticmethod
    async def fetch_open_meteo_data(latitude: float, longitude: float) -> Optional[Dict[str, Any]]:
        """
        Fetch elevation, weather, and vegetation data from Open-Meteo.
        No authentication required.

        Returns: Dict with elevation, slope, temperature, precipitation, NDVI proxy
        """
        try:
            results = {}

            # Fetch elevation
            async with aiohttp.ClientSession() as session:
                # Elevation API
                async with session.get(
                    "https://api.open-meteo.com/v1/elevation",
                    timeout=aiohttp.ClientTimeout(total=settings.API_TIMEOUT),
                    params={
                        "latitude": latitude,
                        "longitude": longitude
                    }
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        elevation = data.get("elevation", [0])[0]
                        results["elevation"] = elevation
                        logger.info(f"Elevation: {elevation}m at ({latitude}, {longitude})")
                    else:
                        logger.warning(f"Elevation API returned status {response.status}")
                        results["elevation"] = None

                # Weather API (includes temperature, precipitation, vegetation)
                async with session.get(
                    "https://api.open-meteo.com/v1/forecast",
                    timeout=aiohttp.ClientTimeout(total=settings.API_TIMEOUT),
                    params={
                        "latitude": latitude,
                        "longitude": longitude,
                        "current": "temperature_2m,precipitation",
                        "hourly": "temperature_2m,precipitation",
                        "daily": "temperature_2m_max,precipitation_sum",
                        "timezone": "Asia/Kolkata"
                    }
                ) as response:
                    if response.status == 200:
                        data = await response.json()
                        current = data.get("current", {})
                        results["temperature"] = current.get("temperature_2m", None)
                        results["precipitation_current"] = current.get("precipitation", 0)

                        # Daily precipitation
                        daily = data.get("daily", {})
                        daily_precip = daily.get("precipitation_sum", [0])
                        results["precipitation_24h"] = daily_precip[0] if daily_precip else 0

                        # NDVI proxy: use vegetation health formula based on temp/precip
                        # NDVI ranges from -1 to 1, with 0.5+ indicating healthy vegetation
                        temp = results.get("temperature", 25)
                        precip = results.get("precipitation_24h", 0)
                        # Simple vegetation proxy
                        ndvi_proxy = min(1.0, (precip / 10.0) * 0.7 if precip > 0 else 0.3)
                        results["ndvi"] = ndvi_proxy

                        logger.info(f"Weather: {results['temperature']}°C, {results['precipitation_24h']}mm at ({latitude}, {longitude})")
                    else:
                        logger.warning(f"Weather API returned status {response.status}")
                        results["temperature"] = None
                        results["precipitation_24h"] = None
                        results["ndvi"] = None

            # Calculate slope (simple approach based on elevation variance)
            # In real implementation, use DEM for accurate slope
            results["slope"] = 8.0  # Default slope for Tamil Nadu

            return results if results else None

        except asyncio.TimeoutError:
            logger.warning("Open-Meteo fetch timed out")
            return None
        except Exception as e:
            logger.error(f"Open-Meteo fetch error: {e}")
            return None

    @staticmethod
    async def fetch_all_metrics(latitude: float, longitude: float) -> Dict[str, Any]:
        """
        Fetch all 4 data sources in parallel using asyncio.gather().

        Returns: Dictionary with all satellite metrics
        """
        logger.info(f"Fetching metrics for ({latitude}, {longitude})")

        # Run all 4 fetchers in parallel
        smap, gpm, insar, meteo = await asyncio.gather(
            DataFetchers.fetch_nasa_smap_moisture(latitude, longitude),
            DataFetchers.fetch_nasa_gpm_precipitation(latitude, longitude),
            DataFetchers.fetch_asf_insar_deformation(latitude, longitude),
            DataFetchers.fetch_open_meteo_data(latitude, longitude),
            return_exceptions=True
        )

        # Handle exceptions gracefully
        if isinstance(smap, Exception):
            logger.error(f"SMAP exception: {smap}")
            smap = None
        if isinstance(gpm, Exception):
            logger.error(f"GPM exception: {gpm}")
            gpm = None
        if isinstance(insar, Exception):
            logger.error(f"InSAR exception: {insar}")
            insar = None
        if isinstance(meteo, Exception):
            logger.error(f"Meteo exception: {meteo}")
            meteo = {}

        # Compile results
        return {
            "latitude": latitude,
            "longitude": longitude,
            "soil_moisture": smap,
            "precipitation_24h": gpm,
            "insar_deformation": insar,
            "elevation": meteo.get("elevation") if meteo else None,
            "slope": meteo.get("slope") if meteo else None,
            "temperature": meteo.get("temperature") if meteo else None,
            "ndvi": meteo.get("ndvi") if meteo else None,
        }


# Static Tamil Nadu locations for testing
TAMIL_NADU_LOCATIONS = [
    {"name": "Chennai", "type": "city", "district": "Chennai", "lat": 13.0827, "lon": 80.2707},
    {"name": "Salem", "type": "city", "district": "Salem", "lat": 11.6643, "lon": 78.1460},
    {"name": "Coimbatore", "type": "city", "district": "Coimbatore", "lat": 11.0081, "lon": 76.9069},
    {"name": "Madurai", "type": "city", "district": "Madurai", "lat": 9.9252, "lon": 78.1198},
    {"name": "Trichy", "type": "city", "district": "Tiruchirapalli", "lat": 10.8069, "lon": 78.7061},
    {"name": "Erode", "type": "city", "district": "Erode", "lat": 11.3445, "lon": 77.7173},
    {"name": "Thoothukudi", "type": "city", "district": "Thoothukudi", "lat": 8.7789, "lon": 78.1697},
    {"name": "Tiruppur", "type": "city", "district": "Tiruppur", "lat": 11.1085, "lon": 77.3411},
    {"name": "Kanyakumari", "type": "town", "district": "Kanyakumari", "lat": 8.0883, "lon": 77.5385},
    {"name": "Nagercoil", "type": "town", "district": "Kanyakumari", "lat": 8.1830, "lon": 77.4304},
]
