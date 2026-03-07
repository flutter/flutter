"""
Comprehensive Tamil Nadu locations database.
All villages, towns, and cities across 38 districts.
Used for search/autocomplete — NOT pipeline-monitored (too many for hourly API calls).
On-demand data is fetched via /api/live-location when a user selects one.
"""

# Format: (Name, State, Lat, Lon, Type)
# Types: "village", "town", "city"

TN_LOCATIONS = [
    # ══════════════════════════════════════════════════════════════
    # CHENNAI METRO AREA
    # ══════════════════════════════════════════════════════════════
    ("Tambaram", "Tamil Nadu", 12.9258, 80.1179, "town"),
    ("Pallavaram", "Tamil Nadu", 12.9655, 80.1451, "town"),
    ("Alandur", "Tamil Nadu", 13.0028, 80.1719, "town"),
    ("Sholinganallur", "Tamil Nadu", 12.9174, 80.2165, "town"),
    ("Avadi", "Tamil Nadu", 13.1195, 80.1027, "town"),
    ("Ambattur", "Tamil Nadu", 13.0982, 80.1620, "town"),
    ("Madhavaram", "Tamil Nadu", 13.1489, 80.2309, "town"),
    ("Tondiarpet", "Tamil Nadu", 13.1275, 80.2829, "town"),
    ("Perambur", "Tamil Nadu", 13.1100, 80.2434, "town"),
    ("Adyar", "Tamil Nadu", 13.0067, 80.2572, "town"),
    ("Guindy", "Tamil Nadu", 13.0067, 80.2206, "town"),
    ("Velachery", "Tamil Nadu", 12.9792, 80.2187, "town"),
    ("Chromepet", "Tamil Nadu", 12.9516, 80.1462, "town"),
    ("Porur", "Tamil Nadu", 13.0382, 80.1566, "town"),
    ("Poonamallee", "Tamil Nadu", 13.0492, 80.1011, "town"),
    ("Sriperumbudur", "Tamil Nadu", 12.9666, 79.9458, "town"),
    ("Maraimalai Nagar", "Tamil Nadu", 12.7900, 80.0230, "town"),
    ("Vandalur", "Tamil Nadu", 12.8922, 80.0814, "town"),
    ("Thiruverkadu", "Tamil Nadu", 13.0670, 80.1180, "town"),
    ("Ennore", "Tamil Nadu", 13.2100, 80.3200, "town"),
    ("Tiruvottiyur", "Tamil Nadu", 13.1600, 80.3000, "town"),
    ("Mylapore", "Tamil Nadu", 13.0339, 80.2678, "town"),
    ("T. Nagar", "Tamil Nadu", 13.0418, 80.2341, "town"),

    # ══════════════════════════════════════════════════════════════
    # CHENGALPATTU DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Chengalpattu", "Tamil Nadu", 12.6841, 79.9836, "town"),
    ("Mamallapuram", "Tamil Nadu", 12.6262, 80.1927, "town"),
    ("Tiruporur", "Tamil Nadu", 12.7476, 80.1882, "town"),
    ("Maduranthakam", "Tamil Nadu", 12.5082, 79.8882, "town"),
    ("Uthiramerur", "Tamil Nadu", 12.6494, 79.7806, "town"),
    ("Thirukazhukundram", "Tamil Nadu", 12.6100, 80.0600, "town"),
    ("Kelambakkam", "Tamil Nadu", 12.7883, 80.2194, "town"),
    ("Padappai", "Tamil Nadu", 12.8767, 80.0330, "village"),
    ("Guduvancheri", "Tamil Nadu", 12.8444, 80.0597, "town"),
    ("Singaperumal Koil", "Tamil Nadu", 12.7580, 80.0069, "village"),

    # ══════════════════════════════════════════════════════════════
    # TIRUVALLUR DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Tiruvallur", "Tamil Nadu", 13.1394, 79.9071, "town"),
    ("Ponneri", "Tamil Nadu", 13.3711, 80.2428, "town"),
    ("Gummidipoondi", "Tamil Nadu", 13.4309, 80.0821, "town"),
    ("Uthukkottai", "Tamil Nadu", 13.2850, 79.9636, "town"),
    ("Tiruttani", "Tamil Nadu", 13.1760, 79.6120, "town"),
    ("Arakkonam", "Tamil Nadu", 13.0840, 79.6701, "town"),
    ("Sholinghur", "Tamil Nadu", 13.1152, 79.4231, "town"),
    ("RK Pet", "Tamil Nadu", 13.2100, 79.4500, "village"),
    ("Minjur", "Tamil Nadu", 13.2800, 80.2600, "town"),
    ("Kadambathur", "Tamil Nadu", 13.1800, 79.7800, "village"),

    # ══════════════════════════════════════════════════════════════
    # KANCHIPURAM DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Kanchipuram", "Tamil Nadu", 12.8342, 79.7036, "city"),
    ("Walajabad", "Tamil Nadu", 12.7918, 79.8284, "town"),
    ("Sriperumbudur", "Tamil Nadu", 12.9666, 79.9458, "town"),
    ("Kundrathur", "Tamil Nadu", 12.9983, 80.0997, "town"),

    # ══════════════════════════════════════════════════════════════
    # VELLORE DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Vellore", "Tamil Nadu", 12.9165, 79.1325, "city"),
    ("Gudiyatham", "Tamil Nadu", 12.9486, 78.8705, "town"),
    ("Katpadi", "Tamil Nadu", 12.9700, 79.1450, "town"),
    ("Vaniyambadi", "Tamil Nadu", 12.6787, 78.6200, "town"),
    ("Ambur", "Tamil Nadu", 12.7874, 78.7188, "town"),
    ("Anaicut", "Tamil Nadu", 12.9300, 79.0400, "village"),
    ("Kalavai", "Tamil Nadu", 12.7600, 79.4200, "village"),
    ("Pernambut", "Tamil Nadu", 12.7400, 78.7200, "town"),

    # ══════════════════════════════════════════════════════════════
    # RANIPET DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Ranipet", "Tamil Nadu", 12.9321, 79.3333, "town"),
    ("Arcot", "Tamil Nadu", 12.9079, 79.3204, "town"),
    ("Walajapet", "Tamil Nadu", 12.9255, 79.3638, "town"),
    ("Sholinghur", "Tamil Nadu", 13.1152, 79.4231, "town"),
    ("Nemili", "Tamil Nadu", 12.9984, 79.9557, "town"),
    ("Kaveripakkam", "Tamil Nadu", 12.9079, 79.4625, "village"),

    # ══════════════════════════════════════════════════════════════
    # TIRUPATHUR DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Tirupathur", "Tamil Nadu", 12.4530, 78.5531, "town"),
    ("Jolarpet", "Tamil Nadu", 12.5643, 78.5797, "town"),
    ("Natrampalli", "Tamil Nadu", 12.5900, 78.6000, "town"),
    ("Vaniyambadi", "Tamil Nadu", 12.6787, 78.6200, "town"),

    # ══════════════════════════════════════════════════════════════
    # TIRUVANNAMALAI DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Tiruvannamalai", "Tamil Nadu", 12.2253, 79.0747, "city"),
    ("Arni", "Tamil Nadu", 12.6677, 79.2853, "town"),
    ("Polur", "Tamil Nadu", 12.5938, 79.1385, "town"),
    ("Vandavasi", "Tamil Nadu", 12.5056, 79.6050, "town"),
    ("Cheyyar", "Tamil Nadu", 12.6564, 79.5405, "town"),
    ("Chengam", "Tamil Nadu", 12.3502, 78.8768, "town"),
    ("Kalasapakkam", "Tamil Nadu", 12.3800, 79.2000, "village"),
    ("Chetpet", "Tamil Nadu", 12.4100, 79.1200, "village"),
    ("Thandarampattu", "Tamil Nadu", 12.1800, 78.8100, "village"),
    ("Arani", "Tamil Nadu", 12.6700, 79.2800, "town"),

    # ══════════════════════════════════════════════════════════════
    # VILLUPURAM DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Villupuram", "Tamil Nadu", 11.9398, 79.4946, "city"),
    ("Tindivanam", "Tamil Nadu", 12.2292, 79.6515, "town"),
    ("Gingee", "Tamil Nadu", 12.2544, 79.4158, "town"),
    ("Vikravandi", "Tamil Nadu", 12.0473, 79.4476, "town"),
    ("Vanur", "Tamil Nadu", 12.0538, 79.7179, "town"),
    ("Marakkanam", "Tamil Nadu", 12.1959, 79.9442, "town"),
    ("Olakkur", "Tamil Nadu", 12.0200, 79.4700, "village"),
    ("Koliyanur", "Tamil Nadu", 11.9700, 79.5400, "village"),
    ("Thiruvennainallur", "Tamil Nadu", 11.9800, 79.2200, "village"),
    ("Mugaiyur", "Tamil Nadu", 12.1300, 79.4800, "village"),

    # ══════════════════════════════════════════════════════════════
    # KALLAKURICHI DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Kallakurichi", "Tamil Nadu", 11.7382, 78.9622, "town"),
    ("Sankarapuram", "Tamil Nadu", 11.8556, 78.9858, "town"),
    ("Chinnasalem", "Tamil Nadu", 11.6355, 78.8810, "town"),
    ("Ulundurpet", "Tamil Nadu", 11.7020, 79.3182, "town"),
    ("Tirukkoyilur", "Tamil Nadu", 11.9637, 79.1501, "town"),
    ("Rishivandiyam", "Tamil Nadu", 11.7100, 78.9300, "village"),

    # ══════════════════════════════════════════════════════════════
    # CUDDALORE DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Cuddalore", "Tamil Nadu", 11.7447, 79.7689, "city"),
    ("Vridhachalam", "Tamil Nadu", 11.6433, 79.6932, "town"),
    ("Tittakudi", "Tamil Nadu", 11.4422, 79.1153, "town"),
    ("Panruti", "Tamil Nadu", 11.7723, 79.5519, "town"),
    ("Neyveli", "Tamil Nadu", 11.5360, 79.4824, "town"),
    ("Chidambaram", "Tamil Nadu", 11.3921, 79.7030, "city"),
    ("Bhuvanagiri", "Tamil Nadu", 11.4979, 79.6637, "town"),
    ("Kurinjipadi", "Tamil Nadu", 11.5825, 79.6500, "town"),
    ("Kattumannarkoil", "Tamil Nadu", 11.2605, 79.5758, "town"),
    ("Veppur", "Tamil Nadu", 11.5513, 79.0748, "village"),
    ("Mangalore (TN)", "Tamil Nadu", 11.8700, 79.8200, "village"),
    ("Sethiathoppu", "Tamil Nadu", 11.4200, 79.6700, "village"),

    # ══════════════════════════════════════════════════════════════
    # MAYILADUTHURAI DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Mayiladuthurai", "Tamil Nadu", 11.1019, 79.6503, "town"),
    ("Sirkazhi", "Tamil Nadu", 11.2378, 79.7396, "town"),
    ("Kuthalam", "Tamil Nadu", 11.0382, 79.5915, "town"),
    ("Tharangambadi", "Tamil Nadu", 11.0299, 79.8522, "town"),
    ("Poompuhar", "Tamil Nadu", 11.1500, 79.8600, "village"),

    # ══════════════════════════════════════════════════════════════
    # NAGAPATTINAM DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Nagapattinam", "Tamil Nadu", 10.7672, 79.8449, "city"),
    ("Kilvelur", "Tamil Nadu", 10.6894, 79.7172, "town"),
    ("Thirukuvalai", "Tamil Nadu", 10.6313, 79.7226, "village"),
    ("Vedaranyam", "Tamil Nadu", 10.4279, 79.7490, "town"),

    # ══════════════════════════════════════════════════════════════
    # TIRUVARUR DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Tiruvarur", "Tamil Nadu", 10.7726, 79.6342, "city"),
    ("Nannilam", "Tamil Nadu", 10.9072, 79.6128, "town"),
    ("Kodavasal", "Tamil Nadu", 10.8553, 79.4810, "town"),
    ("Valangaiman", "Tamil Nadu", 10.8562, 79.3570, "town"),
    ("Mannargudi", "Tamil Nadu", 10.6751, 79.4554, "town"),
    ("Needamangalam", "Tamil Nadu", 10.7250, 79.4700, "town"),
    ("Thiruthuraipoondi", "Tamil Nadu", 10.5317, 79.6401, "town"),
    ("Muthupet", "Tamil Nadu", 10.3900, 79.5100, "town"),

    # ══════════════════════════════════════════════════════════════
    # THANJAVUR DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Thanjavur", "Tamil Nadu", 10.7870, 79.1378, "city"),
    ("Kumbakonam", "Tamil Nadu", 10.9604, 79.3821, "city"),
    ("Thiruvidaimarudur", "Tamil Nadu", 11.0742, 79.4752, "town"),
    ("Papanasam", "Tamil Nadu", 10.8604, 79.2358, "town"),
    ("Orathanadu", "Tamil Nadu", 10.5753, 79.2971, "town"),
    ("Pattukkottai", "Tamil Nadu", 10.4163, 79.3206, "town"),
    ("Peravurani", "Tamil Nadu", 10.2857, 79.2007, "town"),
    ("Thiruvaiyaru", "Tamil Nadu", 10.8700, 79.1100, "town"),
    ("Sengipatti", "Tamil Nadu", 10.7200, 79.0700, "village"),
    ("Budalur", "Tamil Nadu", 10.7500, 79.2700, "village"),

    # ══════════════════════════════════════════════════════════════
    # PUDUKKOTTAI DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Pudukkottai", "Tamil Nadu", 10.3833, 78.8001, "city"),
    ("Aranthangi", "Tamil Nadu", 10.1686, 78.9928, "town"),
    ("Avudaiyarkoil", "Tamil Nadu", 9.9939, 79.0583, "town"),
    ("Manamelkudi", "Tamil Nadu", 10.0419, 79.2300, "town"),
    ("Gandarvakottai", "Tamil Nadu", 10.5729, 79.0149, "town"),
    ("Illuppur", "Tamil Nadu", 10.5137, 78.6216, "town"),
    ("Alangudi", "Tamil Nadu", 10.3604, 78.9779, "town"),
    ("Thirumayam", "Tamil Nadu", 10.2449, 78.7464, "town"),
    ("Ponnamaravathi", "Tamil Nadu", 10.2800, 78.5400, "town"),
    ("Karambakudi", "Tamil Nadu", 10.4500, 79.1200, "village"),

    # ══════════════════════════════════════════════════════════════
    # ARIYALUR DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Ariyalur", "Tamil Nadu", 11.1400, 79.0786, "town"),
    ("Sendurai", "Tamil Nadu", 11.2720, 79.1866, "town"),
    ("Udayarpalayam", "Tamil Nadu", 11.1588, 79.3444, "town"),
    ("Andimadam", "Tamil Nadu", 11.3159, 79.3539, "town"),
    ("Jayamkondam", "Tamil Nadu", 11.2100, 79.3800, "town"),
    ("T. Palur", "Tamil Nadu", 11.1700, 79.1600, "village"),

    # ══════════════════════════════════════════════════════════════
    # PERAMBALUR DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Perambalur", "Tamil Nadu", 11.2320, 78.8802, "town"),
    ("Kunnam", "Tamil Nadu", 11.2943, 79.0145, "town"),
    ("Alathur", "Tamil Nadu", 11.1347, 78.9081, "town"),
    ("Veppanthattai", "Tamil Nadu", 11.3994, 78.8869, "town"),

    # ══════════════════════════════════════════════════════════════
    # TIRUCHIRAPPALLI (TRICHY) DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Tiruchirappalli", "Tamil Nadu", 10.7905, 78.7047, "city"),
    ("Trichy", "Tamil Nadu", 10.7905, 78.7047, "city"),
    ("Srirangam", "Tamil Nadu", 10.8628, 78.6893, "town"),
    ("Lalgudi", "Tamil Nadu", 10.8754, 78.8153, "town"),
    ("Manachanallur", "Tamil Nadu", 10.9114, 78.6998, "town"),
    ("Thuraiyur", "Tamil Nadu", 11.2302, 78.5651, "town"),
    ("Musiri", "Tamil Nadu", 11.0488, 78.5282, "town"),
    ("Manapparai", "Tamil Nadu", 10.6082, 78.4231, "town"),
    ("Thiruverumbur", "Tamil Nadu", 10.7700, 78.7600, "town"),
    ("Thottiyam", "Tamil Nadu", 11.0100, 78.3400, "town"),

    # ══════════════════════════════════════════════════════════════
    # KARUR DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Karur", "Tamil Nadu", 10.9601, 78.0766, "city"),
    ("Aravakurichi", "Tamil Nadu", 10.7770, 77.9094, "town"),
    ("Krishnarayapuram", "Tamil Nadu", 10.8359, 78.3519, "town"),
    ("Kulithalai", "Tamil Nadu", 10.8155, 78.4881, "town"),
    ("Pugalur", "Tamil Nadu", 10.9100, 78.2000, "village"),

    # ══════════════════════════════════════════════════════════════
    # NAMAKKAL DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Namakkal", "Tamil Nadu", 11.2189, 78.1674, "city"),
    ("Rasipuram", "Tamil Nadu", 11.4537, 78.1785, "town"),
    ("Tiruchengode", "Tamil Nadu", 11.3787, 77.8949, "town"),
    ("Paramathi Velur", "Tamil Nadu", 11.1100, 78.0000, "town"),
    ("Komarapalayam", "Tamil Nadu", 11.4400, 77.7000, "town"),
    ("Mohanur", "Tamil Nadu", 11.0600, 78.1300, "village"),
    ("Sendamangalam", "Tamil Nadu", 11.2600, 78.2200, "village"),

    # ══════════════════════════════════════════════════════════════
    # SALEM DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Salem", "Tamil Nadu", 11.6643, 78.1460, "city"),
    ("Mettur", "Tamil Nadu", 11.7928, 77.8649, "town"),
    ("Attur", "Tamil Nadu", 11.5900, 78.5900, "town"),
    ("Edappadi", "Tamil Nadu", 11.5838, 77.8348, "town"),
    ("Omalur", "Tamil Nadu", 11.7429, 78.0473, "town"),
    ("Sankari", "Tamil Nadu", 11.5331, 77.9734, "town"),
    ("Yercaud", "Tamil Nadu", 11.7852, 78.2075, "town"),
    ("Vazhapadi", "Tamil Nadu", 11.6600, 78.4000, "town"),
    ("Gangavalli", "Tamil Nadu", 11.5200, 78.6500, "village"),
    ("Tharamangalam", "Tamil Nadu", 11.6900, 78.0100, "town"),
    ("Panamarathupatti", "Tamil Nadu", 11.6000, 78.1800, "village"),
    ("Kolathur (S)", "Tamil Nadu", 11.7400, 78.3500, "village"),

    # ══════════════════════════════════════════════════════════════
    # DHARMAPURI DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Dharmapuri", "Tamil Nadu", 12.1211, 78.1582, "city"),
    ("Harur", "Tamil Nadu", 12.0546, 78.4786, "town"),
    ("Pennagaram", "Tamil Nadu", 12.1125, 77.8677, "town"),
    ("Palacode", "Tamil Nadu", 12.3041, 78.0729, "town"),
    ("Nallampalli", "Tamil Nadu", 12.0700, 78.2200, "town"),
    ("Karimangalam", "Tamil Nadu", 12.2300, 78.1100, "village"),
    ("Pappireddipatti", "Tamil Nadu", 11.9200, 78.3600, "town"),
    ("Morappur", "Tamil Nadu", 12.0000, 78.0400, "village"),

    # ══════════════════════════════════════════════════════════════
    # KRISHNAGIRI DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Krishnagiri", "Tamil Nadu", 12.5152, 78.0094, "city"),
    ("Hosur", "Tamil Nadu", 12.7183, 77.8229, "city"),
    ("Denkanikottai", "Tamil Nadu", 12.5128, 77.7611, "town"),
    ("Uthangarai", "Tamil Nadu", 12.2753, 78.4939, "town"),
    ("Pochampalli", "Tamil Nadu", 12.3700, 77.9300, "village"),
    ("Bargur", "Tamil Nadu", 12.3100, 78.3600, "town"),
    ("Kaveripattinam", "Tamil Nadu", 12.4200, 78.1700, "town"),
    ("Mathur (K)", "Tamil Nadu", 12.5500, 77.8800, "village"),
    ("Shoolagiri", "Tamil Nadu", 12.6600, 77.9700, "town"),
    ("Thally", "Tamil Nadu", 12.5700, 77.7100, "town"),
    ("Kelamangalam", "Tamil Nadu", 12.5600, 77.8300, "village"),
    ("Rayakottai", "Tamil Nadu", 12.4800, 78.0500, "village"),

    # ══════════════════════════════════════════════════════════════
    # ERODE DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Erode", "Tamil Nadu", 11.3410, 77.7172, "city"),
    ("Bhavani", "Tamil Nadu", 11.2265, 76.7675, "town"),
    ("Gobichettipalayam", "Tamil Nadu", 11.4552, 77.4351, "town"),
    ("Sathyamangalam", "Tamil Nadu", 11.5524, 77.2654, "town"),
    ("Perundurai", "Tamil Nadu", 11.2783, 77.5883, "town"),
    ("Kangeyam", "Tamil Nadu", 10.9903, 77.6282, "town"),
    ("Nambiyur", "Tamil Nadu", 11.3500, 77.3200, "village"),
    ("Anthiyur", "Tamil Nadu", 11.5700, 77.5800, "town"),
    ("Bhavanisagar", "Tamil Nadu", 11.4700, 77.0800, "town"),
    ("Modakkurichi", "Tamil Nadu", 11.3600, 77.8800, "village"),

    # ══════════════════════════════════════════════════════════════
    # TIRUPPUR DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Tiruppur", "Tamil Nadu", 11.1085, 77.3411, "city"),
    ("Dharapuram", "Tamil Nadu", 10.7369, 77.5261, "town"),
    ("Udumalaipettai", "Tamil Nadu", 10.5839, 77.2500, "town"),
    ("Vellakoil", "Tamil Nadu", 10.7951, 77.5391, "town"),
    ("Avinashi", "Tamil Nadu", 11.1950, 77.2700, "town"),
    ("Palladam", "Tamil Nadu", 10.9900, 77.2800, "town"),
    ("Kundadam", "Tamil Nadu", 10.8500, 77.6000, "village"),
    ("Kangeyam", "Tamil Nadu", 10.9900, 77.6300, "town"),
    ("Madathukulam", "Tamil Nadu", 10.5500, 77.3500, "town"),

    # ══════════════════════════════════════════════════════════════
    # COIMBATORE DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Coimbatore", "Tamil Nadu", 11.0168, 76.9558, "city"),
    ("Pollachi", "Tamil Nadu", 10.6600, 77.0100, "town"),
    ("Mettupalayam", "Tamil Nadu", 11.2900, 76.9300, "town"),
    ("Valparai", "Tamil Nadu", 10.3272, 76.9520, "town"),
    ("Sulur", "Tamil Nadu", 11.0345, 77.1204, "town"),
    ("Kinathukadavu", "Tamil Nadu", 10.8100, 76.9800, "town"),
    ("Annur", "Tamil Nadu", 11.2300, 77.1000, "town"),
    ("Karamadai", "Tamil Nadu", 11.2400, 76.9600, "town"),
    ("Thondamuthur", "Tamil Nadu", 11.0100, 76.8100, "town"),
    ("Perur", "Tamil Nadu", 10.9800, 76.8800, "town"),
    ("Madukkarai", "Tamil Nadu", 10.9000, 76.9600, "town"),
    ("Perianaickenpalayam", "Tamil Nadu", 11.1500, 76.9500, "town"),

    # ══════════════════════════════════════════════════════════════
    # NILGIRIS DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Ooty", "Tamil Nadu", 11.4101, 76.6950, "town"),
    ("Coonoor", "Tamil Nadu", 11.3530, 76.7950, "town"),
    ("Kotagiri", "Tamil Nadu", 11.4225, 76.8609, "town"),
    ("Gudalur", "Tamil Nadu", 11.5039, 76.4923, "town"),
    ("Pandalur", "Tamil Nadu", 11.4800, 76.3300, "village"),
    ("Kundah", "Tamil Nadu", 11.3100, 76.5700, "village"),
    ("Aruvankadu", "Tamil Nadu", 11.3800, 76.7100, "village"),
    ("Lovedale", "Tamil Nadu", 11.3900, 76.7000, "village"),
    ("Wellington", "Tamil Nadu", 11.3700, 76.7800, "village"),
    ("Ketti", "Tamil Nadu", 11.3600, 76.7600, "village"),

    # ══════════════════════════════════════════════════════════════
    # MADURAI DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Madurai", "Tamil Nadu", 9.9252, 78.1198, "city"),
    ("Vadipatti", "Tamil Nadu", 10.0790, 78.0360, "town"),
    ("Usilampatti", "Tamil Nadu", 9.9709, 77.7933, "town"),
    ("Tirumangalam", "Tamil Nadu", 9.8238, 77.9862, "town"),
    ("Peraiyur", "Tamil Nadu", 9.7482, 77.7387, "town"),
    ("Sedapatti", "Tamil Nadu", 10.2638, 77.8395, "town"),
    ("Melur", "Tamil Nadu", 10.0300, 78.3400, "town"),
    ("Kalligudi", "Tamil Nadu", 9.8900, 78.0200, "village"),
    ("Alanganallur", "Tamil Nadu", 10.0400, 78.0800, "village"),
    ("Sholavandan", "Tamil Nadu", 10.0100, 78.0000, "village"),
    ("T. Kallupatti", "Tamil Nadu", 9.8800, 77.7600, "village"),
    ("Kottampatti", "Tamil Nadu", 10.0700, 78.3400, "village"),

    # ══════════════════════════════════════════════════════════════
    # THENI DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Theni", "Tamil Nadu", 10.0127, 77.4772, "city"),
    ("Theni Allinagaram", "Tamil Nadu", 10.0146, 77.4777, "town"),
    ("Bodinayakanur", "Tamil Nadu", 10.0324, 77.3505, "town"),
    ("Periyakulam", "Tamil Nadu", 10.1199, 77.5467, "town"),
    ("Cumbum", "Tamil Nadu", 9.7394, 77.2853, "town"),
    ("Uthamapalayam", "Tamil Nadu", 9.7663, 77.3299, "town"),
    ("Andipatti", "Tamil Nadu", 9.8034, 77.5269, "town"),
    ("Chinnamanur", "Tamil Nadu", 9.8400, 77.3900, "town"),
    ("Gudalur (Th)", "Tamil Nadu", 9.6800, 77.2700, "village"),

    # ══════════════════════════════════════════════════════════════
    # DINDIGUL DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Dindigul", "Tamil Nadu", 10.3624, 77.9695, "city"),
    ("Palani", "Tamil Nadu", 10.4511, 77.5154, "town"),
    ("Oddanchatram", "Tamil Nadu", 10.4851, 77.7460, "town"),
    ("Kodaikanal", "Tamil Nadu", 10.2337, 77.4920, "town"),
    ("Nilakkottai", "Tamil Nadu", 10.1648, 77.8529, "town"),
    ("Batlagundu", "Tamil Nadu", 10.1636, 77.7591, "town"),
    ("Vedasandur", "Tamil Nadu", 10.5990, 78.0017, "town"),
    ("Natham", "Tamil Nadu", 10.2200, 78.1300, "town"),

    # ══════════════════════════════════════════════════════════════
    # SIVAGANGA DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Sivaganga", "Tamil Nadu", 9.8432, 78.4826, "city"),
    ("Karaikudi", "Tamil Nadu", 10.0728, 78.7795, "city"),
    ("Devakottai", "Tamil Nadu", 9.8961, 78.8067, "town"),
    ("Manamadurai", "Tamil Nadu", 9.7298, 78.4183, "town"),
    ("Tiruppuvanam", "Tamil Nadu", 9.8279, 78.2555, "town"),
    ("Singampunari", "Tamil Nadu", 10.1834, 78.4216, "town"),
    ("Ilayangudi", "Tamil Nadu", 9.6288, 78.6267, "town"),
    ("Kalayarkoil", "Tamil Nadu", 9.8700, 78.5400, "village"),
    ("Nattarasankottai", "Tamil Nadu", 9.8800, 78.7200, "village"),
    ("Pallathur", "Tamil Nadu", 10.1200, 78.8100, "village"),

    # ══════════════════════════════════════════════════════════════
    # VIRUDHUNAGAR DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Virudhunagar", "Tamil Nadu", 9.5775, 77.9519, "city"),
    ("Sivakasi", "Tamil Nadu", 9.4628, 77.7891, "city"),
    ("Rajapalayam", "Tamil Nadu", 9.4032, 77.5183, "city"),
    ("Aruppukottai", "Tamil Nadu", 9.8505, 78.0977, "town"),
    ("Srivilliputhur", "Tamil Nadu", 9.5601, 77.6091, "town"),
    ("Sattur", "Tamil Nadu", 9.3600, 77.9200, "town"),
    ("Tiruchuli", "Tamil Nadu", 9.4300, 78.2100, "town"),
    ("Watrap", "Tamil Nadu", 9.5400, 77.5600, "village"),
    ("Vembakottai", "Tamil Nadu", 9.5700, 77.8400, "village"),
    ("Narikudi", "Tamil Nadu", 9.4300, 78.0800, "village"),

    # ══════════════════════════════════════════════════════════════
    # RAMANATHAPURAM DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Ramanathapuram", "Tamil Nadu", 9.3711, 78.8313, "city"),
    ("Rameswaram", "Tamil Nadu", 9.2876, 79.3129, "town"),
    ("Paramakudi", "Tamil Nadu", 9.4867, 78.6723, "town"),
    ("Kamuthi", "Tamil Nadu", 9.4086, 78.3684, "town"),
    ("Mudukulathur", "Tamil Nadu", 9.3821, 78.5516, "town"),
    ("Tiruvadanai", "Tamil Nadu", 9.7419, 78.9200, "town"),
    ("R.S. Mangalam", "Tamil Nadu", 9.6370, 78.8469, "village"),
    ("Kadaladi", "Tamil Nadu", 9.3400, 78.9200, "village"),
    ("Mandapam", "Tamil Nadu", 9.2700, 79.1200, "town"),
    ("Thondi", "Tamil Nadu", 9.7400, 79.0100, "town"),

    # ══════════════════════════════════════════════════════════════
    # THOOTHUKUDI DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Thoothukudi", "Tamil Nadu", 8.7924, 78.1348, "city"),
    ("Kovilpatti", "Tamil Nadu", 9.1756, 77.8687, "town"),
    ("Tiruchendur", "Tamil Nadu", 8.4956, 78.1233, "town"),
    ("Sathankulam", "Tamil Nadu", 8.4448, 77.9055, "town"),
    ("Eral", "Tamil Nadu", 8.6254, 78.0229, "town"),
    ("Vilathikulam", "Tamil Nadu", 9.1682, 78.1997, "town"),
    ("Ettayapuram", "Tamil Nadu", 9.1806, 78.0231, "town"),
    ("Kayathar", "Tamil Nadu", 8.9479, 77.7724, "town"),
    ("Ottapidaram", "Tamil Nadu", 8.9503, 78.0182, "town"),
    ("Srivaikuntam", "Tamil Nadu", 8.6300, 77.9100, "town"),
    ("Kulasekarapattinam", "Tamil Nadu", 8.4100, 78.0800, "village"),

    # ══════════════════════════════════════════════════════════════
    # TIRUNELVELI DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Tirunelveli", "Tamil Nadu", 8.7139, 77.7567, "city"),
    ("Ambasamudram", "Tamil Nadu", 8.7083, 77.4383, "town"),
    ("Cheranmahadevi", "Tamil Nadu", 8.6793, 77.5617, "town"),
    ("Nanguneri", "Tamil Nadu", 8.4893, 77.6597, "town"),
    ("Radhapuram", "Tamil Nadu", 8.2875, 77.6410, "town"),
    ("Palayamkottai", "Tamil Nadu", 8.7200, 77.7400, "town"),
    ("Sankarankoil", "Tamil Nadu", 9.1473, 77.5866, "town"),
    ("Alangulam", "Tamil Nadu", 8.8597, 77.4882, "town"),
    ("Kadayam", "Tamil Nadu", 8.6800, 77.5700, "village"),
    ("Kalakkad", "Tamil Nadu", 8.5100, 77.5200, "village"),
    ("Vasudevanallur", "Tamil Nadu", 8.9600, 77.4100, "village"),
    ("Tenkasi", "Tamil Nadu", 8.9602, 77.3152, "city"),

    # ══════════════════════════════════════════════════════════════
    # TENKASI DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Kadayanallur", "Tamil Nadu", 9.0842, 77.3462, "town"),
    ("Shencottai", "Tamil Nadu", 8.9747, 77.2507, "town"),
    ("Alangulam (Tk)", "Tamil Nadu", 8.8600, 77.4900, "town"),
    ("Surandai", "Tamil Nadu", 8.9800, 77.4100, "town"),
    ("Courtallam", "Tamil Nadu", 8.9300, 77.2700, "town"),
    ("Puliyangudi", "Tamil Nadu", 9.1700, 77.3900, "town"),
    ("Sivagiri", "Tamil Nadu", 9.1200, 77.5300, "village"),

    # ══════════════════════════════════════════════════════════════
    # KANYAKUMARI DISTRICT
    # ══════════════════════════════════════════════════════════════
    ("Kanyakumari", "Tamil Nadu", 8.0883, 77.5385, "town"),
    ("Nagercoil", "Tamil Nadu", 8.1833, 77.4119, "city"),
    ("Vilavancode", "Tamil Nadu", 8.3831, 77.2056, "town"),
    ("Kalkulam", "Tamil Nadu", 8.3364, 77.3245, "town"),
    ("Agasteeswaram", "Tamil Nadu", 8.1056, 77.5214, "town"),
    ("Thovalai", "Tamil Nadu", 8.2303, 77.5037, "town"),
    ("Marthandam", "Tamil Nadu", 8.3100, 77.2200, "town"),
    ("Kuzhithurai", "Tamil Nadu", 8.3200, 77.2100, "town"),
    ("Colachel", "Tamil Nadu", 8.1800, 77.2500, "town"),
    ("Manavalakurichi", "Tamil Nadu", 8.1500, 77.3100, "village"),
    ("Padmanabhapuram", "Tamil Nadu", 8.2400, 77.3300, "town"),
    ("Sucindram", "Tamil Nadu", 8.1500, 77.4700, "village"),
    ("Thuckalay", "Tamil Nadu", 8.2500, 77.2700, "town"),
    ("Eraniel", "Tamil Nadu", 8.2100, 77.3100, "village"),

    # ══════════════════════════════════════════════════════════════
    # OTHER MAJOR INDIA CITIES (for cross-state search)
    # ══════════════════════════════════════════════════════════════
    ("Mumbai", "Maharashtra", 19.0760, 72.8777, "metro"),
    ("Delhi", "Delhi", 28.6139, 77.2090, "metro"),
    ("Bangalore", "Karnataka", 12.9716, 77.5946, "metro"),
    ("Hyderabad", "Telangana", 17.3850, 78.4867, "metro"),
    ("Kolkata", "West Bengal", 22.5726, 88.3639, "metro"),
    ("Pune", "Maharashtra", 18.5204, 73.8567, "city"),
    ("Kochi", "Kerala", 9.9312, 76.2673, "city"),
    ("Thiruvananthapuram", "Kerala", 8.5241, 76.9366, "city"),
    ("Pondicherry", "Puducherry", 11.9416, 79.8083, "city"),
    ("Mysore", "Karnataka", 12.2958, 76.6394, "city"),
]

def get_location_by_name(name: str):
    """Search TN_LOCATIONS for a location by name."""
    q = name.lower().strip()
    for loc_name, state, lat, lon, loc_type in TN_LOCATIONS:
        if loc_name.lower() == q:
            return {"name": loc_name, "state": state, "lat": lat, "lon": lon, "type": loc_type}
    return None
