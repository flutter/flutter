"""
Data source adapters for satellite data ingestion.

Contains adapters for:
- NASA SMAP/GPM (soil moisture, precipitation)
- JAXA AMSR2 (soil moisture validation)
- IMD Cyclone (cyclone tracking)
- Sentinel NDVI (vegetation health)
- Sentinel-1 InSAR (ground deformation)
- MODIS LST (thermal data)
"""

from app.services.data_sources.base_adapter import BaseDataAdapter, DataReading, DataSourceFactory
from app.services.data_sources.nasa_smap_gpm_adapter import NASASensorAdapter
from app.services.data_sources.jaxa_amsr2_adapter import JAXA_AMSR2_Adapter
from app.services.data_sources.imd_cyclone_adapter import IMD_Cyclone_Adapter
from app.services.data_sources.sentinel_ndvi_adapter import Sentinel_NDVI_Adapter
from app.services.data_sources.insar_adapter import Sentinel1_InSAR_Adapter
from app.services.data_sources.modis_thermal_adapter import MODIS_Thermal_Adapter

# Register all adapters with factory
DataSourceFactory.register('nasa_smap_gpm', NASASensorAdapter)
DataSourceFactory.register('jaxa_amsr2', JAXA_AMSR2_Adapter)
DataSourceFactory.register('imd_cyclone', IMD_Cyclone_Adapter)
DataSourceFactory.register('sentinel_ndvi', Sentinel_NDVI_Adapter)
DataSourceFactory.register('sentinel1_insar', Sentinel1_InSAR_Adapter)
DataSourceFactory.register('modis_thermal', MODIS_Thermal_Adapter)

__all__ = [
    'BaseDataAdapter',
    'DataReading',
    'DataSourceFactory',
    'NASASensorAdapter',
    'JAXA_AMSR2_Adapter',
    'IMD_Cyclone_Adapter',
    'Sentinel_NDVI_Adapter',
    'Sentinel1_InSAR_Adapter',
    'MODIS_Thermal_Adapter',
]
