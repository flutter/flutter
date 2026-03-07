import re

# Comprehensive list of TN towns/villages (Name, Lat, Lon)
# We will use approx coordinates if exact not easily known, but many are known.
# For a script, let's just use geopy to get exact coords for 150 real TN towns!
import urllib.request
import json
import time

towns = [
    "Sivakasi", "Rajapalayam", "Aruppukottai", "Kovilpatti", "Srivilliputhur",
    "Palani", "Udumalaipettai", "Pollachi", "Mettur", "Bhavani",
    "Gobichettipalayam", "Sathyamangalam", "Dharapuram", "Kangeyam", "Vellakoil",
    "Tiruchengode", "Namakkal", "Rasipuram", "Attur", "Edappadi",
    "Omalur", "Sankari", "Yercaud", "Harur", "Pennagaram",
    "Palacode", "Krishnagiri", "Hosur", "Denkanikottai", "Uthangarai",
    "Vaniyambadi", "Ambur", "Jolarpet", "Tirupathur", "Gudiyatham",
    "Arcot", "Ranipet", "Walajapet", "Arakkonam", "Sholinghur",
    "Nemili", "Kaveripakkam", "Arni", "Polur", "Vandavasi",
    "Cheyyar", "Chengam", "Tindivanam", "Gingee", "Villupuram",
    "Vikravandi", "Vanur", "Marakkanam", "Kallakurichi", "Sankarapuram",
    "Chinnasalem", "Ulundurpet", "Tirukkoyilur", "Vridhachalam", "Tittakudi",
    "Veppur", "Kattumannarkoil", "Chidambaram", "Bhuvanagiri", "Kurinjipadi",
    "Panruti", "Neyveli", "Sirkazhi", "Mayiladuthurai", "Kuthalam",
    "Tharangambadi", "Kilvelur", "Thirukuvalai", "Vedaranyam", "Nannilam",
    "Kodavasal", "Valangaiman", "Mannargudi", "Needamangalam", "Thiruthuraipoondi",
    "Kumbakonam", "Thiruvidaimarudur", "Papanasam", "Orathanadu", "Pattukkottai",
    "Peravurani", "Aranthangi", "Avadaiyarkoil", "Manamelkudi", "Gandarvakottai",
    "Kulathur", "Illuppur", "Alangudi", "Thirumayam", "Ponnamaravathi",
    "Karur", "Aravakurichi", "Krishnarayapuram", "Kulithalai", "Manapparai",
    "Srirangam", "Lalgudi", "Manachanallur", "Thuraiyur", "Musiri",
    "Veppanthattai", "Kunnam", "Alathur", "Sendurai", "Udayarpalayam",
    "Andimadam", "Paramakudi", "Kamuthi", "Mudukulathur", "Kadaladi",
    "Tiruvadanai", "R.S. Mangalam", "Ilayangudi", "Manamadurai", "Tiruppuvanam",
    "Devakottai", "Karaikudi", "Tirupathur (Sivaganga)", "Singampunari", "Melur",
    "Vadipatti", "Usilampatti", "Tirumangalam", "Peraiyur", "Sedapatti",
    "Kottampatti", "Natham", "Nilakkottai", "Batlagundu", "Palani",
    "Oddanchatram", "Vedasandur", "Guziliyamparai", "Kodaikanal", "Theni Allinagaram",
    "Bodinayakanur", "Periyakulam", "Cumbum", "Uthamapalayam", "Andipatti",
    "Sankarankoil", "Tenkasi", "Kadayanallur", "Shencottai", "Alangulam",
    "Ambasamudram", "Cheranmahadevi", "Nanguneri", "Radhapuram", "Vallioor",
    "Tiruchendur", "Sathankulam", "Eral", "Srivaikuntam", "Vilathikulam",
    "Ettayapuram", "Kayathar", "Ottapidaram", "Vilavancode", "Kalkulam",
    "Agasteeswaram", "Thovalai", "Sriperumbudur", "Tambaram", "Pallavaram",
    "Alandur", "Sholinganallur", "Chengalpattu", "Tiruporur", "Cheyyur",
    "Maduranthakam", "Uthiramerur", "Kanchipuram", "Walajabad", "Tiruvallur",
    "Poonamallee", "Avadi", "Ponneri", "Gummidipoondi", "Uthukkottai"
]

results = []
print(f"Geocoding {len(towns)} towns in Tamil Nadu...")

for town in towns:
    url = f"https://nominatim.openstreetmap.org/search?q={urllib.parse.quote(town + ', Tamil Nadu, India')}&format=json&limit=1"
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'HazardMonitorApp/1.0'})
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode())
            if data:
                lat = round(float(data[0]['lat']), 4)
                lon = round(float(data[0]['lon']), 4)
                results.append((town, "Tamil Nadu", lat, lon, "town"))
                print(f"OK {town}: {lat}, {lon}")
    except Exception as e:
        print(f"FAIL {town}: {e}")
    time.sleep(1.1)  # Nominatim rate limit is 1 req/sec

out_path = "C:/flutter/bin/hazard_monitor/backend/india_data/tn_locations.json"
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(results, f, indent=2)

print(f"Saved {len(results)} locations to JSON.")
