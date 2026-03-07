import json

with open('c:/flutter/bin/hazard_monitor/backend/india_data/tn_locations.json', 'r', encoding='utf-8') as f:
    tn_locs = json.load(f)

# Format as python tuples
extra_lines = []
for loc in tn_locs:
    # loc = [name, state, lat, lon, type]
    if len(loc) >= 5:
        extra_lines.append(f'    ("{loc[0]}", "{loc[1]}", {loc[2]}, {loc[3]}, "{loc[4]}"),\n')

# Append to hazard_backend.py
with open('c:/flutter/bin/hazard_monitor/backend/hazard_backend.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if line.strip() == 'EXTRA_LOCATIONS = [':
        # Insert right after
        lines.insert(i + 1, ''.join(extra_lines))
        break

with open('c:/flutter/bin/hazard_monitor/backend/hazard_backend.py', 'w', encoding='utf-8') as f:
    f.writelines(lines)
    
print(f'Injected {len(tn_locs)} new TN locations into hazard_backend.py EXTRA_LOCATIONS!')
