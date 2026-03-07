"""
Utility functions for geospatial data processing.
Used by all satellite data adapters.
"""

import numpy as np
from datetime import datetime, timedelta
from typing import Tuple, List, Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)


class SpatialUtils:
    """Spatial/geographic utility functions."""

    @staticmethod
    def create_grid(
        bbox: Tuple[float, float, float, float],
        resolution: float = 0.5
    ) -> List[Tuple[float, float]]:
        """
        Create grid of points within bounding box.

        Args:
            bbox: (south_lat, west_lon, north_lat, east_lon)
            resolution: Grid resolution in degrees

        Returns:
            List of (lat, lon) tuples
        """
        south, west, north, east = bbox
        lats = np.arange(south, north, resolution)
        lons = np.arange(west, east, resolution)

        grid = []
        for lat in lats:
            for lon in lons:
                grid.append((lat, lon))

        logger.info(f"Created grid with {len(grid)} points at {resolution}° resolution")
        return grid

    @staticmethod
    def interpolate_nearest_neighbor(
        data_points: List[Dict[str, Any]],
        target_points: List[Tuple[float, float]]
    ) -> List[Dict[str, Any]]:
        """
        Interpolate values to target points using nearest neighbor.

        Args:
            data_points: List of dicts with 'lat', 'lon', 'value' keys
            target_points: List of (lat, lon) tuples

        Returns:
            List of dicts with interpolated values
        """
        import scipy.spatial as spatial

        if not data_points:
            return []

        # Extract coordinates and values
        coords = np.array([(p['lat'], p['lon']) for p in data_points])
        values = np.array([p['value'] for p in data_points])

        # Build KD-tree for efficient nearest neighbor search
        tree = spatial.cKDTree(coords)

        interpolated = []
        for lat, lon in target_points:
            _, idx = tree.query([lat, lon])
            interpolated.append({
                'lat': lat,
                'lon': lon,
                'value': float(values[idx]),
                'method': 'nearest_neighbor'
            })

        logger.info(f"Interpolated {len(interpolated)} points")
        return interpolated

    @staticmethod
    def validate_coordinates(lat: float, lon: float) -> bool:
        """Validate latitude and longitude values."""
        return -90 <= lat <= 90 and -180 <= lon <= 180

    @staticmethod
    def distance_km(
        lat1: float,
        lon1: float,
        lat2: float,
        lon2: float
    ) -> float:
        """
        Calculate great-circle distance between two points in km.
        Uses Haversine formula.
        """
        from math import radians, cos, sin, asin, sqrt

        lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
        dlon = lon2 - lon1
        dlat = lat2 - lat1
        a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
        c = 2 * asin(sqrt(a))
        km = 6371 * c
        return km


class TemporalUtils:
    """Temporal/time-based utility functions."""

    @staticmethod
    def get_date_range(
        days_back: int = 3,
        end_date: Optional[datetime] = None
    ) -> Tuple[datetime, datetime]:
        """
        Get date range for data retrieval.

        Args:
            days_back: Number of days to look back
            end_date: End date (defaults to now)

        Returns:
            Tuple of (start_date, end_date)
        """
        if end_date is None:
            end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=days_back)
        return start_date, end_date

    @staticmethod
    def format_iso_date(dt: datetime) -> str:
        """Format datetime to ISO 8601 string."""
        return dt.strftime('%Y-%m-%dT%H:%M:%SZ')

    @staticmethod
    def parse_iso_date(date_str: str) -> datetime:
        """Parse ISO 8601 date string."""
        return datetime.fromisoformat(date_str.replace('Z', '+00:00'))

    @staticmethod
    def get_satellite_pass_info(satellite_name: str) -> Dict[str, Any]:
        """Get typical pass frequency and latency for satellite."""
        info = {
            'SMAP': {
                'revisit_days': 3,
                'latency_hours': 24,
                'ascending_node': True,
                'descending_node': False
            },
            'AMSR2': {
                'revisit_days': 2,
                'latency_hours': 12,
                'ascending_node': True,
                'descending_node': True
            },
            'Sentinel-1': {
                'revisit_days': 12,  # Default, can be 6 with both A+B
                'latency_hours': 48,
                'ascending_node': True,
                'descending_node': True
            },
            'Sentinel-2': {
                'revisit_days': 5,  # Default, can be 2-3 with A+B
                'latency_hours': 24,
                'ascending_node': True,
                'descending_node': False
            },
            'MODIS': {
                'revisit_days': 1,
                'latency_hours': 6,
                'ascending_node': False,
                'descending_node': False
            },
            'GPM': {
                'revisit_hours': 3,
                'latency_minutes': 30,
            }
        }
        return info.get(satellite_name, {})


class DataQualityUtils:
    """Data quality checking and validation."""

    @staticmethod
    def check_value_range(
        value: float,
        min_val: float,
        max_val: float,
        name: str = "value"
    ) -> bool:
        """Check if value is within acceptable range."""
        if not (min_val <= value <= max_val):
            logger.warning(f"{name} {value} outside range [{min_val}, {max_val}]")
            return False
        return True

    @staticmethod
    def detect_outliers(
        values: List[float],
        method: str = 'iqr',
        threshold: float = 1.5
    ) -> List[bool]:
        """
        Detect outliers in data using IQR or Z-score method.

        Args:
            values: List of numerical values
            method: 'iqr' or 'zscore'
            threshold: IQR multiplier (1.5) or z-score threshold (3.0)

        Returns:
            List of booleans indicating outliers
        """
        values = np.array(values)

        if method == 'iqr':
            Q1 = np.percentile(values, 25)
            Q3 = np.percentile(values, 75)
            IQR = Q3 - Q1
            lower = Q1 - threshold * IQR
            upper = Q3 + threshold * IQR
            return (values < lower) | (values > upper)

        elif method == 'zscore':
            z_scores = np.abs((values - np.mean(values)) / np.std(values))
            return z_scores > threshold

        return [False] * len(values)

    @staticmethod
    def calculate_confidence(
        num_sources: int = 1,
        data_age_days: float = 0,
        has_validation: bool = False,
        spatial_coverage: float = 1.0
    ) -> float:
        """
        Calculate confidence score for a measurement (0-1).

        Args:
            num_sources: Number of data sources used
            data_age_days: Age of data in days
            has_validation: Whether data has been validated
            spatial_coverage: Fraction of spatial domain covered

        Returns:
            Confidence score 0-1
        """
        # Base confidence
        confidence = 0.5

        # More sources = higher confidence
        confidence += min(0.3, num_sources * 0.15)

        # Fresher data = higher confidence
        age_penalty = min(0.2, data_age_days * 0.05)
        confidence -= age_penalty

        # Validation increases confidence
        if has_validation:
            confidence += 0.2

        # Better coverage = higher confidence
        confidence += spatial_coverage * 0.1

        return min(1.0, max(0.0, confidence))

    @staticmethod
    def calculate_anomaly(
        current_value: float,
        climatological_mean: float,
        climatological_std: float
    ) -> Tuple[float, str]:
        """
        Calculate anomaly from climatological normal.

        Args:
            current_value: Current measurement
            climatological_mean: Long-term mean
            climatological_std: Long-term standard deviation

        Returns:
            Tuple of (anomaly_value, anomaly_category)
        """
        if climatological_std == 0:
            return 0.0, 'neutral'

        anomaly = current_value - climatological_mean
        z_score = anomaly / climatological_std

        if z_score < -2:
            category = 'extreme_low'
        elif z_score < -1:
            category = 'below_normal'
        elif z_score >= 2:
            category = 'extreme_high'
        elif z_score > 1:
            category = 'above_normal'
        else:
            category = 'normal'

        return anomaly, category


class FileUtils:
    """File reading and parsing utilities."""

    @staticmethod
    async def parse_geotiff(file_path: str) -> Dict[str, Any]:
        """
        Parse GeoTIFF file and extract data.

        Args:
            file_path: Path to GeoTIFF file

        Returns:
            Dict with data, bounds, crs, etc.
        """
        try:
            import rasterio
            with rasterio.open(file_path) as src:
                data = src.read(1)
                bounds = src.bounds
                crs = src.crs
                transform = src.transform

                return {
                    'data': data,
                    'bounds': bounds,
                    'crs': crs,
                    'transform': transform,
                    'width': src.width,
                    'height': src.height
                }
        except Exception as e:
            logger.error(f"Error parsing GeoTIFF {file_path}: {e}")
            return {}

    @staticmethod
    async def parse_hdf5(file_path: str, variables: List[str]) -> Dict[str, Any]:
        """
        Parse HDF5 file and extract variables.

        Args:
            file_path: Path to HDF5 file
            variables: List of variable names to extract

        Returns:
            Dict with extracted data
        """
        try:
            import h5py
            with h5py.File(file_path, 'r') as f:
                data = {}
                for var in variables:
                    if var in f:
                        data[var] = f[var][:]
                    else:
                        logger.warning(f"Variable {var} not found in HDF5")
                return data
        except Exception as e:
            logger.error(f"Error parsing HDF5 {file_path}: {e}")
            return {}

    @staticmethod
    async def parse_netcdf(file_path: str, variables: List[str]) -> Dict[str, Any]:
        """
        Parse NetCDF file and extract variables.

        Args:
            file_path: Path to NetCDF file
            variables: List of variable names to extract

        Returns:
            Dict with extracted data
        """
        try:
            import xarray as xr
            ds = xr.open_dataset(file_path)
            data = {}
            for var in variables:
                if var in ds.data_vars:
                    data[var] = ds[var].values
                else:
                    logger.warning(f"Variable {var} not found in NetCDF")
            ds.close()
            return data
        except Exception as e:
            logger.error(f"Error parsing NetCDF {file_path}: {e}")
            return {}
