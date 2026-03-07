"""
Location Search API endpoints.
Searchable database of all Tamil Nadu cities, towns, and villages.
"""

import logging
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, or_

from app.models.database import get_db, Location
from app.api.v1.models import SearchRequest, SearchResponse, SearchResult

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/search", tags=["Search"])


def calculate_match_score(query: str, location_name: str) -> float:
    """Calculate similarity score between query and location name."""
    query_lower = query.lower()
    name_lower = location_name.lower()

    # Exact match
    if query_lower == name_lower:
        return 1.0

    # Starts with
    if name_lower.startswith(query_lower):
        return 0.9

    # Contains
    if query_lower in name_lower:
        return 0.7

    # Partial match (Levenshtein distance approximation)
    common_chars = sum(1 for c in query_lower if c in name_lower)
    return common_chars / max(len(query_lower), len(name_lower)) if max(len(query_lower), len(name_lower)) > 0 else 0


@router.post("/", response_model=SearchResponse)
async def search_locations(
    request: SearchRequest,
    db: Session = Depends(get_db)
):
    """
    Search for locations in Tamil Nadu by name.

    Supports fuzzy matching and filtering by location type.

    Parameters:
    - **query**: Search query (e.g., "Madurai", "Chennai", "Kodai...")
    - **type**: Filter by type: city, town, village, district (optional)
    - **limit**: Max results (1-100, default 10)

    Returns:
    - Matching locations with match scores
    """
    try:
        logger.info(f"Searching locations: query='{request.query}', types={request.type}")

        # Build query
        query_obj = db.query(Location).filter(
            Location.name.ilike(f"%{request.query}%")
        )

        # Filter by type if specified
        if request.type:
            query_obj = query_obj.filter(Location.type.in_(request.type))

        # Execute query
        locations = query_obj.limit(request.limit * 2).all()  # Get more than needed for scoring

        if not locations:
            logger.info(f"No locations found for query: {request.query}")
            return SearchResponse(
                query=request.query,
                results=[],
                total=0
            )

        # Score and sort results
        scored_results = []
        for loc in locations:
            score = calculate_match_score(request.query, loc.name)
            scored_results.append((loc, score))

        # Sort by score descending
        scored_results.sort(key=lambda x: x[1], reverse=True)

        # Convert to response objects
        results = []
        for loc, score in scored_results[:request.limit]:
            if score > 0.3:  # Filter out very poor matches
                result = SearchResult(
                    name=loc.name,
                    type=loc.type,
                    district=loc.district,
                    latitude=loc.latitude,
                    longitude=loc.longitude,
                    population=loc.population,
                    match_score=score
                )
                results.append(result)

        logger.info(f"Found {len(results)} matching locations")

        return SearchResponse(
            query=request.query,
            results=results,
            total=len(results)
        )

    except Exception as e:
        logger.error(f"Search error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Error searching locations")


@router.get("/autocomplete", response_model=List[dict])
async def autocomplete(
    query: str = Query(..., min_length=1, max_length=50),
    limit: int = Query(default=10, ge=1, le=50),
    db: Session = Depends(get_db)
):
    """
    Autocomplete endpoint for search-as-you-type functionality.

    Returns location names matching the query prefix.
    """
    try:
        # Query starts with
        locations = db.query(Location).filter(
            Location.name.ilike(f"{query}%")
        ).limit(limit).all()

        results = [
            {
                "name": loc.name,
                "type": loc.type,
                "district": loc.district,
                "latitude": loc.latitude,
                "longitude": loc.longitude
            }
            for loc in locations
        ]

        logger.debug(f"Autocomplete: '{query}' -> {len(results)} results")
        return results

    except Exception as e:
        logger.error(f"Autocomplete error: {e}")
        raise HTTPException(status_code=500, detail="Autocomplete error")


@router.get("/nearby", response_model=List[SearchResult])
async def get_nearby_locations(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    radius_km: float = Query(default=50, ge=1, le=200),
    limit: int = Query(default=10, ge=1, le=50),
    db: Session = Depends(get_db)
):
    """
    Get locations near a given coordinate (within radius_km).

    Useful for finding nearby cities/towns/villages fora given GPS coordinate.
    """
    try:
        # Approximate distance calculation using latitude/longitude
        # For more accuracy, use PostGIS distance operators in production
        lat_delta = radius_km / 111.0  # 1° latitude ≈ 111 km
        lon_delta = radius_km / (111.0 * abs(__import__('math').cos(__import__('math').radians(latitude))))

        locations = db.query(Location).filter(
            Location.latitude.between(latitude - lat_delta, latitude + lat_delta),
            Location.longitude.between(longitude - lon_delta, longitude + lon_delta)
        ).limit(limit).all()

        # Calculate actual distance and sort
        import math

        def haversine(lat1, lon1, lat2, lon2):
            R = 6371  # Earth radius in km
            lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
            dlat = lat2 - lat1
            dlon = lon2 - lon1
            a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
            c = 2 * math.asin(math.sqrt(a))
            return R * c

        # Sort by distance
        locations_with_dist = [
            (loc, haversine(latitude, longitude, loc.latitude, loc.longitude))
            for loc in locations
        ]
        locations_with_dist.sort(key=lambda x: x[1])

        results = [
            SearchResult(
                name=loc.name,
                type=loc.type,
                district=loc.district,
                latitude=loc.latitude,
                longitude=loc.longitude,
                population=loc.population,
                match_score=1.0 - (dist / radius_km) if dist < radius_km else 0
            )
            for loc, dist in locations_with_dist
        ]

        logger.info(f"Found {len(results)} locations within {radius_km}km of ({latitude}, {longitude})")
        return results

    except Exception as e:
        logger.error(f"Nearby search error: {e}")
        raise HTTPException(status_code=500, detail="Error finding nearby locations")


@router.get("/by-district/{district}", response_model=List[SearchResult])
async def get_locations_by_district(
    district: str,
    location_type: Optional[str] = Query(None, description="Filter by type"),
    limit: int = Query(default=50, ge=1, le=500),
    db: Session = Depends(get_db)
):
    """
    Get all locations in a specific district.

    Useful for showing all towns/villages in a district.
    """
    try:
        query_obj = db.query(Location).filter(
            Location.district.ilike(f"%{district}%")
        )

        if location_type:
            query_obj = query_obj.filter(Location.type == location_type)

        locations = query_obj.limit(limit).all()

        results = [
            SearchResult(
                name=loc.name,
                type=loc.type,
                district=loc.district,
                latitude=loc.latitude,
                longitude=loc.longitude,
                population=loc.population,
                match_score=1.0
            )
            for loc in locations
        ]

        logger.info(f"Found {len(results)} locations in {district}")
        return results

    except Exception as e:
        logger.error(f"District search error: {e}")
        raise HTTPException(status_code=500, detail="Error searching by district")


@router.get("/stats", response_model=dict)
async def get_search_statistics(db: Session = Depends(get_db)):
    """
    Get statistics about locations in database.

    Useful for debugging and data quality checks.
    """
    try:
        total = db.query(func.count(Location.id)).scalar()
        by_type = db.query(
            Location.type,
            func.count(Location.id)
        ).group_by(Location.type).all()

        by_district = db.query(
            Location.district,
            func.count(Location.id)
        ).group_by(Location.district).all()

        stats = {
            'total_locations': total,
            'by_type': {loc_type: count for loc_type, count in by_type},
            'by_district': {district: count for district, count in by_district},
            'database_ready': total > 0
        }

        return stats

    except Exception as e:
        logger.error(f"Stats error: {e}")
        raise HTTPException(status_code=500, detail="Error retrieving statistics")
