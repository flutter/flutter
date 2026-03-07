"""
Indian Locations Database
Comprehensive database of Indian cities, towns, and villages with coordinates.
Supports fuzzy text search for the frontend search bar.
"""

from typing import List, Dict, Optional

# Comprehensive Indian locations database
# Format: (name, state, lat, lon, type, population_approx)
INDIA_LOCATIONS = [
    # Metro Cities
    ("Mumbai", "Maharashtra", 19.076, 72.8777, "metro", 20411000),
    ("Delhi", "Delhi", 28.6139, 77.209, "metro", 16787941),
    ("Bangalore", "Karnataka", 12.9716, 77.5946, "metro", 8443675),
    ("Hyderabad", "Telangana", 17.385, 78.4867, "metro", 6809970),
    ("Ahmedabad", "Gujarat", 23.0225, 72.5714, "metro", 5570585),
    ("Chennai", "Tamil Nadu", 13.0827, 80.2707, "metro", 7088000),
    ("Kolkata", "West Bengal", 22.5726, 88.3639, "metro", 14681000),
    ("Pune", "Maharashtra", 18.5204, 73.8567, "metro", 3124458),
    ("Jaipur", "Rajasthan", 26.9124, 75.7873, "metro", 3073350),
    ("Lucknow", "Uttar Pradesh", 26.8467, 80.9462, "metro", 2815601),

    # Major Cities
    ("Surat", "Gujarat", 21.1702, 72.8311, "city", 4467000),
    ("Kanpur", "Uttar Pradesh", 26.4499, 80.3319, "city", 2767031),
    ("Nagpur", "Maharashtra", 21.1458, 79.0882, "city", 2405665),
    ("Indore", "Madhya Pradesh", 22.7196, 75.8577, "city", 1994397),
    ("Thane", "Maharashtra", 19.2183, 72.9781, "city", 1818872),
    ("Bhopal", "Madhya Pradesh", 23.2599, 77.4126, "city", 1798218),
    ("Visakhapatnam", "Andhra Pradesh", 17.6868, 83.2185, "city", 1730320),
    ("Patna", "Bihar", 25.6093, 85.1376, "city", 1684222),
    ("Vadodara", "Gujarat", 22.3072, 73.1812, "city", 1666703),
    ("Ghaziabad", "Uttar Pradesh", 28.6692, 77.4538, "city", 1648643),
    ("Ludhiana", "Punjab", 30.901, 75.8573, "city", 1613878),
    ("Agra", "Uttar Pradesh", 27.1767, 78.0081, "city", 1585704),
    ("Nashik", "Maharashtra", 19.9975, 73.7898, "city", 1486053),
    ("Faridabad", "Haryana", 28.4089, 77.3178, "city", 1414050),
    ("Meerut", "Uttar Pradesh", 28.9845, 77.7064, "city", 1305429),
    ("Rajkot", "Gujarat", 22.3039, 70.8022, "city", 1286995),
    ("Varanasi", "Uttar Pradesh", 25.3176, 82.9739, "city", 1201815),
    ("Srinagar", "Jammu & Kashmir", 34.0837, 74.7973, "city", 1180570),
    ("Aurangabad", "Maharashtra", 19.8762, 75.3433, "city", 1175116),
    ("Dhanbad", "Jharkhand", 23.7957, 86.4304, "city", 1161561),
    ("Amritsar", "Punjab", 31.634, 74.8723, "city", 1132761),
    ("Allahabad", "Uttar Pradesh", 25.4358, 81.8463, "city", 1112544),
    ("Ranchi", "Jharkhand", 23.3441, 85.3096, "city", 1073440),
    ("Howrah", "West Bengal", 22.5958, 88.2636, "city", 1072161),
    ("Coimbatore", "Tamil Nadu", 11.0168, 76.9558, "city", 1061447),
    ("Jabalpur", "Madhya Pradesh", 23.1815, 79.9864, "city", 1054336),
    ("Gwalior", "Madhya Pradesh", 26.2183, 78.1828, "city", 1054420),
    ("Vijayawada", "Andhra Pradesh", 16.5062, 80.648, "city", 1048240),
    ("Jodhpur", "Rajasthan", 26.2389, 73.0243, "city", 1033918),
    ("Madurai", "Tamil Nadu", 9.9252, 78.1198, "city", 1016885),
    ("Raipur", "Chhattisgarh", 21.2514, 81.6296, "city", 1010087),
    ("Kota", "Rajasthan", 25.2138, 75.8648, "city", 1001694),
    ("Chandigarh", "Chandigarh", 30.7333, 76.7794, "city", 1055450),
    ("Guwahati", "Assam", 26.1445, 91.7362, "city", 957352),
    ("Solapur", "Maharashtra", 17.6599, 75.9064, "city", 951118),
    ("Tiruchirappalli", "Tamil Nadu", 10.7905, 78.7047, "city", 916857),
    ("Bareilly", "Uttar Pradesh", 28.367, 79.4304, "city", 903668),
    ("Mysore", "Karnataka", 12.2958, 76.6394, "city", 893062),
    ("Thiruvananthapuram", "Kerala", 8.5241, 76.9366, "city", 889191),
    ("Kochi", "Kerala", 9.9312, 76.2673, "city", 677381),
    ("Dehradun", "Uttarakhand", 30.3165, 78.0322, "city", 578420),
    ("Shimla", "Himachal Pradesh", 31.1048, 77.1734, "city", 169578),
    ("Gangtok", "Sikkim", 27.3389, 88.6065, "city", 98658),
    ("Imphal", "Manipur", 24.817, 93.9368, "city", 264986),
    ("Shillong", "Meghalaya", 25.5788, 91.8933, "city", 354759),
    ("Aizawl", "Mizoram", 23.7271, 92.7176, "city", 293416),
    ("Kohima", "Nagaland", 25.6751, 94.1086, "city", 99039),
    ("Itanagar", "Arunachal Pradesh", 27.0844, 93.6053, "city", 59490),
    ("Agartala", "Tripura", 23.8315, 91.2868, "city", 400004),
    ("Panaji", "Goa", 15.4909, 73.8278, "city", 40017),
    ("Silvassa", "Dadra & Nagar Haveli", 20.2736, 72.9967, "city", 99000),
    ("Daman", "Daman & Diu", 20.397, 72.8397, "city", 39737),
    ("Kavaratti", "Lakshadweep", 10.5593, 72.6358, "city", 11210),
    ("Port Blair", "Andaman & Nicobar", 11.6234, 92.7265, "city", 100186),

    # District/Important Towns
    ("Ujjain", "Madhya Pradesh", 23.1765, 75.7885, "town", 515215),
    ("Nanded", "Maharashtra", 19.1383, 77.321, "town", 550439),
    ("Jamnagar", "Gujarat", 22.4707, 70.0577, "town", 529308),
    ("Siliguri", "West Bengal", 26.7271, 88.3953, "town", 513264),
    ("Durgapur", "West Bengal", 23.5204, 87.3119, "town", 566517),
    ("Ajmer", "Rajasthan", 26.4499, 74.6399, "town", 542580),
    ("Udaipur", "Rajasthan", 24.5854, 73.7125, "town", 451735),
    ("Bikaner", "Rajasthan", 28.0229, 73.3119, "town", 644406),
    ("Jhansi", "Uttar Pradesh", 25.4484, 78.5685, "town", 505693),
    ("Gorakhpur", "Uttar Pradesh", 26.7606, 83.3732, "town", 673446),
    ("Tiruvallur", "Tamil Nadu", 13.1279, 79.9086, "town", 200000),
    ("Salem", "Tamil Nadu", 11.6643, 78.146, "town", 831038),
    ("Hubli-Dharwad", "Karnataka", 15.3647, 75.124, "town", 943857),
    ("Mangalore", "Karnataka", 12.9141, 74.856, "town", 619664),
    ("Belgaum", "Karnataka", 15.8497, 74.4977, "town", 481548),
    ("Gulbarga", "Karnataka", 17.3297, 76.8343, "town", 532031),
    ("Nellore", "Andhra Pradesh", 14.4426, 79.9865, "town", 558078),
    ("Warangal", "Telangana", 17.9689, 79.5941, "town", 753438),
    ("Karimnagar", "Telangana", 18.4386, 79.1288, "town", 261185),
    ("Bilaspur", "Chhattisgarh", 22.0797, 82.1409, "town", 365579),
    ("Bhilai", "Chhattisgarh", 21.2094, 81.3784, "town", 625138),
    ("Cuttack", "Odisha", 20.4625, 85.8828, "town", 606007),
    ("Bhubaneswar", "Odisha", 20.2961, 85.8245, "town", 838834),
    ("Rourkela", "Odisha", 22.2604, 84.8536, "town", 552970),
    ("Muzaffarpur", "Bihar", 26.1209, 85.3647, "town", 393724),
    ("Gaya", "Bihar", 24.7914, 84.9994, "town", 472002),
    ("Bhagalpur", "Bihar", 25.2425, 86.9842, "town", 410210),
    ("Jammu", "Jammu & Kashmir", 32.7266, 74.857, "town", 502197),
    ("Leh", "Ladakh", 34.1526, 77.5771, "town", 31440),
    ("Pondicherry", "Puducherry", 11.9416, 79.8083, "town", 241773),

    # Towns and Smaller Cities
    ("Darjeeling", "West Bengal", 27.0410, 88.2627, "town", 118805),
    ("Ooty", "Tamil Nadu", 11.4102, 76.6950, "town", 88430),
    ("Munnar", "Kerala", 10.0889, 77.0595, "town", 30000),
    ("Kodaikanal", "Tamil Nadu", 10.2381, 77.4892, "town", 36501),
    ("Hampi", "Karnataka", 15.3350, 76.4600, "town", 2777),
    ("Jaisalmer", "Rajasthan", 26.9157, 70.9083, "town", 65471),
    ("Pushkar", "Rajasthan", 26.4900, 74.5513, "town", 21626),
    ("McLeod Ganj", "Himachal Pradesh", 32.2427, 76.3213, "town", 11138),
    ("Rishikesh", "Uttarakhand", 30.0869, 78.2676, "town", 102138),
    ("Haridwar", "Uttarakhand", 29.9457, 78.1642, "town", 228832),
    ("Manali", "Himachal Pradesh", 32.2432, 77.1892, "town", 8096),
    ("Kullu", "Himachal Pradesh", 31.9592, 77.1089, "town", 18306),
    ("Nainital", "Uttarakhand", 29.3803, 79.4636, "town", 41377),
    ("Mussoorie", "Uttarakhand", 30.4598, 78.0644, "town", 30118),
    ("Almora", "Uttarakhand", 29.5971, 79.6591, "town", 34122),

    # Hazard-prone locations (important for monitoring)
    ("Kedarnath", "Uttarakhand", 30.7346, 79.0669, "village", 612),
    ("Chamoli", "Uttarakhand", 30.4025, 79.3240, "town", 10000),
    ("Joshimath", "Uttarakhand", 30.5550, 79.5650, "town", 16000),
    ("Uttarkashi", "Uttarakhand", 30.7268, 78.4354, "town", 16000),
    ("Idukki", "Kerala", 9.8530, 76.9721, "town", 52521),
    ("Wayanad", "Kerala", 11.6854, 76.1320, "town", 31515),
    ("Kodagu", "Karnataka", 12.4218, 75.7390, "town", 25000),
    ("Pithoragarh", "Uttarakhand", 29.5829, 80.2180, "town", 56044),
    ("Arunachal Border", "Arunachal Pradesh", 28.2180, 94.7278, "village", 5000),
    ("Mizoram Hills", "Mizoram", 23.1645, 92.9376, "village", 3000),
    ("Latur", "Maharashtra", 18.4088, 76.5604, "town", 382754),
    ("Bhuj", "Gujarat", 23.2420, 69.6669, "town", 185075),
    ("Barmer", "Rajasthan", 25.7532, 71.3967, "town", 89202),
    ("Jalore", "Rajasthan", 25.3463, 72.6157, "town", 54081),

    # Villages (representative samples across India)
    ("Mawsynram", "Meghalaya", 25.2974, 91.5825, "village", 500),
    ("Cherrapunji", "Meghalaya", 25.2700, 91.7314, "village", 11500),
    ("Ziro", "Arunachal Pradesh", 27.5432, 93.8131, "village", 24533),
    ("Khonoma", "Nagaland", 25.6590, 94.0392, "village", 2874),
    ("Mawlynnong", "Meghalaya", 25.2018, 91.9142, "village", 500),
    ("Dhanushkodi", "Tamil Nadu", 9.1714, 79.4147, "village", 500),
    ("Spiti Valley", "Himachal Pradesh", 32.2463, 78.0350, "village", 12000),
    ("Tawang", "Arunachal Pradesh", 27.5860, 91.8596, "village", 9531),
    ("Majuli", "Assam", 26.9500, 94.1700, "village", 167000),
    ("Malana", "Himachal Pradesh", 32.0756, 77.3287, "village", 1810),
    ("Sandakphu", "West Bengal", 27.1021, 88.0007, "village", 200),
    ("Kalap", "Uttarakhand", 31.1400, 78.4100, "village", 300),
    ("Nongriat", "Meghalaya", 25.2200, 91.6600, "village", 400),
    ("Chitkul", "Himachal Pradesh", 31.3516, 78.4369, "village", 700),
    ("Dholavira", "Gujarat", 23.8861, 70.2127, "village", 5000),
]


def search_locations(query: str, limit: int = 15) -> List[Dict]:
    """
    Search Indian locations with fuzzy matching.
    Returns matching locations sorted by relevance.
    """
    query_lower = query.lower().strip()
    if not query_lower:
        return []

    results = []
    for name, state, lat, lon, loc_type, pop in INDIA_LOCATIONS:
        name_lower = name.lower()
        state_lower = state.lower()

        # Exact match
        if name_lower == query_lower:
            score = 100
        # Starts with query
        elif name_lower.startswith(query_lower):
            score = 90
        # Contains query
        elif query_lower in name_lower:
            score = 70
        # State match
        elif query_lower in state_lower:
            score = 50
        # Partial match (first 3 chars)
        elif len(query_lower) >= 3 and query_lower[:3] in name_lower:
            score = 40
        else:
            continue

        # Boost by population/importance
        if pop > 5000000:
            score += 10
        elif pop > 1000000:
            score += 7
        elif pop > 100000:
            score += 3

        results.append({
            "name": name,
            "state": state,
            "lat": lat,
            "lon": lon,
            "type": loc_type,
            "population": pop,
            "relevance": score
        })

    results.sort(key=lambda x: (-x["relevance"], -x["population"]))
    return results[:limit]


def get_all_locations() -> List[Dict]:
    """Return all locations."""
    return [
        {
            "name": name,
            "state": state,
            "lat": lat,
            "lon": lon,
            "type": loc_type,
            "population": pop
        }
        for name, state, lat, lon, loc_type, pop in INDIA_LOCATIONS
    ]


def get_location_by_name(name: str) -> Optional[Dict]:
    """Get a specific location by exact name."""
    for loc_name, state, lat, lon, loc_type, pop in INDIA_LOCATIONS:
        if loc_name.lower() == name.lower():
            return {
                "name": loc_name,
                "state": state,
                "lat": lat,
                "lon": lon,
                "type": loc_type,
                "population": pop
            }
    return None
