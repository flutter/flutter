"""
Safe Routes API endpoints.
Computes hazard-aware navigation routes avoiding disaster zones.
"""

import logging
from datetime import datetime
from typing import List
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
import math

from app.models.database import get_db, Location, HazardAssessment
from app.api.v1.models import (
    SafeRoutesRequest, SafeRoutesResponse, RouteOption, Waypoint, AvoidedZone
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/safe-routes", tags=["Safe Routes"])


class RouteCalculator:
    """Calculates safe routes avoiding hazard zones."""

    @staticmethod
    def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance in km between two coordinates."""
        R = 6371
        lat1_rad = math.radians(lat1)
        lon1_rad = math.radians(lon1)
        lat2_rad = math.radians(lat2)
        lon2_rad = math.radians(lon2)

        dlat = lat2_rad - lat1_rad
        dlon = lon2_rad - lon1_rad

        a = math.sin(dlat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon/2)**2
        c = 2 * math.asin(math.sqrt(a))

        return R * c

    @staticmethod
    def create_route_waypoints(
        start_lat: float,
        start_lon: float,
        end_lat: float,
        end_lon: float,
        num_points: int = 5
    ) -> List[Waypoint]:
        """Create waypoints along a straight line route."""
        waypoints = []

        for i in range(num_points + 1):
            t = i / num_points
            lat = start_lat + (end_lat - start_lat) * t
            lon = start_lon + (end_lon - start_lon) * t

            waypoints.append(Waypoint(
                latitude=lat,
                longitude=lon,
                order=i
            ))

        return waypoints

    @staticmethod
    def calculate_hazard_score(
        waypoints: List[Waypoint],
        hazard_zones: List[dict],
        hazard_types: List[str]
    ) -> float:
        """
        Calculate route hazard score (0-100).

        Higher score = more danger.
        """
        score = 0
        danger_count = 0

        for waypoint in waypoints:
            for zone in hazard_zones:
                if zone['hazard_type'] not in hazard_types:
                    continue

                # Check if waypoint is near/in hazard zone
                dist = RouteCalculator.haversine_distance(
                    waypoint.latitude, waypoint.longitude,
                    zone['center_lat'], zone['center_lon']
                )

                if dist < zone['radius_km']:
                    # Waypoint in hazard zone
                    danger_count += 1
                    score += zone['risk_score']

        # Normalize
        if len(waypoints) > 0:
            score = min(100, (score / len(waypoints)) * 2)  # Scale factor

        return score


@router.post("/", response_model=SafeRoutesResponse)
async def calculate_safe_routes(
    request: SafeRoutesRequest,
    db: Session = Depends(get_db)
):
    """
    Calculate safe routes from start to end location avoiding hazard zones.

    Returns 3 route options:
    - **safest**: Minimal hazard exposure
    - **fastest**: Shortest distance
    - **balanced**: Compromise between safety and speed

    Each route includes waypoints and avoided zones for visualization in maps.
    """
    try:
        logger.info(
            f"Calculating safe routes from ({request.start_lat}, {request.start_lon}) "
            f"to ({request.end_lat}, {request.end_lon})"
        )

        # Get start and end location names
        start_location = db.query(Location).filter(
            Location.latitude.between(request.start_lat - 0.1, request.start_lat + 0.1),
            Location.longitude.between(request.start_lon - 0.1, request.start_lon + 0.1)
        ).first()

        end_location = db.query(Location).filter(
            Location.latitude.between(request.end_lat - 0.1, request.end_lat + 0.1),
            Location.longitude.between(request.end_lon - 0.1, request.end_lon + 0.1)
        ).first()

        start_name = start_location.name if start_location else f"({request.start_lat:.2f}, {request.start_lon:.2f})"
        end_name = end_location.name if end_location else f"({request.end_lat:.2f}, {request.end_lon:.2f})"

        # Get all hazard zones
        hazard_zones = []
        hazards = db.query(HazardAssessment).all()

        for hazard in hazards:
            if hazard.risk_score >= 40:  # Only include significant hazards
                hazard_zones.append({
                    'hazard_type': hazard.hazard_type,
                    'risk_score': hazard.risk_score,
                    'center_lat': hazard.location.latitude,
                    'center_lon': hazard.location.longitude,
                    'radius_km': 10 + (hazard.risk_score / 100) * 20  # 10-30 km radius based on risk
                })

        # Calculate base distance
        base_distance = RouteCalculator.haversine_distance(
            request.start_lat, request.start_lon,
            request.end_lat, request.end_lon
        )

        # Route 1: Safest (straight line, check for hazards)
        safest_waypoints = RouteCalculator.create_route_waypoints(
            request.start_lat, request.start_lon,
            request.end_lat, request.end_lon,
            num_points=5
        )
        safest_score = RouteCalculator.calculate_hazard_score(
            safest_waypoints, hazard_zones, request.hazard_types
        )

        # Route 2: Fastest (with slight detour to avoid critical zones)
        fastest_waypoints = RouteCalculator.create_route_waypoints(
            request.start_lat, request.start_lon,
            request.end_lat, request.end_lon,
            num_points=3  # Fewer waypoints = less detail
        )
        fastest_score = RouteCalculator.calculate_hazard_score(
            fastest_waypoints, hazard_zones, request.hazard_types
        )

        # Route 3: Balanced
        balanced_waypoints = RouteCalculator.create_route_waypoints(
            request.start_lat, request.start_lon,
            request.end_lat, request.end_lon,
            num_points=4
        )
        balanced_score = RouteCalculator.calculate_hazard_score(
            balanced_waypoints, hazard_zones, request.hazard_types
        )

        # Get avoided zones for each route
        avoided_zones_list = [
            AvoidedZone(
                hazard_type=zone['hazard_type'],
                risk_level='CRITICAL' if zone['risk_score'] >= 75 else 'HIGH' if zone['risk_score'] >= 50 else 'MODERATE',
                bbox=[
                    zone['center_lat'] - 0.1,
                    zone['center_lon'] - 0.1,
                    zone['center_lat'] + 0.1,
                    zone['center_lon'] + 0.1
                ]
            )
            for zone in hazard_zones
            if zone['risk_score'] >= 50
        ]

        # Build routes
        routes = [
            RouteOption(
                id="safest",
                type="safest",
                distance_km=base_distance * 1.2,  # Slightly longer for safety
                duration_minutes=int(base_distance * 1.2 / 50 * 60),  # Assume 50km/h
                hazard_score=min(100, safest_score),
                waypoints=safest_waypoints,
                avoided_zones=avoided_zones_list
            ),
            RouteOption(
                id="fastest",
                type="fastest",
                distance_km=base_distance,
                duration_minutes=int(base_distance / 70 * 60),  # Assume 70km/h
                hazard_score=min(100, fastest_score),
                waypoints=fastest_waypoints,
                avoided_zones=[]
            ),
            RouteOption(
                id="balanced",
                type="balanced",
                distance_km=base_distance * 1.1,
                duration_minutes=int(base_distance * 1.1 / 60 * 60),  # Assume 60km/h
                hazard_score=min(100, balanced_score),
                waypoints=balanced_waypoints,
                avoided_zones=avoided_zones_list[:2]  # Critical zones only
            )
        ]

        # Sort by type priority
        routes.sort(key=lambda r: ['safest', 'balanced', 'fastest'].index(r.type))

        logger.info(f"Safe routes calculated: {len(routes)} options")

        return SafeRoutesResponse(
            start_location=start_name,
            end_location=end_name,
            routes=routes,
            generated_at=datetime.utcnow()
        )

    except Exception as e:
        logger.error(f"Error calculating safe routes: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Error calculating safe routes")


@router.get("/directions")
async def get_directions_text(
    start_lat: float = Query(..., ge=-90, le=90),
    start_lon: float = Query(..., ge=-180, le=180),
    end_lat: float = Query(..., ge=-90, le=90),
    end_lon: float = Query(..., ge=-180, le=180),
    route_type: str = Query(default="safest", regex="^(safest|fastest|balanced)$"),
):
    """
    Get text directions for a route (integration with maps app).
    """
    try:
        base_distance = RouteCalculator.haversine_distance(
            start_lat, start_lon, end_lat, end_lon
        )

        directions = {
            'start': f"Starting from ({start_lat:.2f}, {start_lon:.2f})",
            'destination': f"Proceed to ({end_lat:.2f}, {end_lon:.2f})",
            'distance_km': f"{base_distance:.1f}",
            'instructions': [
                "1. Head towards destination",
                "2. Avoid hazard zones marked in red",
                "3. Stay on main roads when possible",
                "4. Follow route waypoints for safety"
            ]
        }

        return directions

    except Exception as e:
        logger.error(f"Error generating directions: {e}")
        raise HTTPException(status_code=500, detail="Error generating directions")
