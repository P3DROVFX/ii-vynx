import os
import re

appearance_path = '/home/pedro/.config/quickshell/ii/modules/common/Appearance.qml'

color_outline = "#ece6e9" # default m3onSecondaryContainer
color_error   = "#ffb4ab" # default m3error
color_fill    = "#B5CCBA" # m3success

# Try to parse Appearance.qml
try:
    with open(appearance_path, 'r') as f:
        content = f.read()
        match_sec = re.search(r'm3onSecondaryContainer:\s*"([^"]+)"', content)
        if match_sec: color_outline = match_sec.group(1)
        
        match_err = re.search(r'm3error:\s*"([^"]+)"', content)
        if match_err: color_error = match_err.group(1)
        
        match_suc = re.search(r'm3success:\s*"([^"]+)"', content)
        if match_suc: color_fill = match_suc.group(1)
except Exception as e:
    pass

output_dir = '/home/pedro/.config/quickshell/ii/assets/icons/android16'
os.makedirs(output_dir, exist_ok=True)

svg_template = """<svg xmlns="http://www.w3.org/2000/svg" height="24px" viewBox="0 -960 960 960" width="24px">
  <path d="M 160 -240 a 120 120 0 0 1 -120 -120 v -240 a 120 120 0 0 1 120 -120 h 540 a 120 120 0 0 1 120 120 v 240 a 120 120 0 0 1 -120 120 Z M 160 -320 h 540 a 40 40 0 0 0 40 -40 v -240 a 40 40 0 0 0 -40 -40 h -540 a 40 40 0 0 0 -40 40 v 240 a 40 40 0 0 0 40 40 Z" fill-rule="evenodd" fill="{outline_color}"/>
  <path d="M 820 -540 h 30 a 30 30 0 0 1 30 30 v 60 a 30 30 0 0 1 -30 30 h -30 Z" fill="{outline_color}"/>
{fill_rect}
</svg>"""

for level in range(0, 101, 10):
    is_critical = level <= 10
    is_low = level <= 20
    
    current_outline = color_error if is_low else color_outline
    
    # Matching BatteryIndicator logic for fill
    if is_critical:
        current_fill = "#E53935"
    elif is_low:
        current_fill = "#FB8C00"
    else:
        current_fill = color_fill
        
    width = int(620 * (level / 100.0))
    
    if level > 0:
        fill_rect = f'  <rect x="120" y="-640" width="{width}" height="320" rx="40" fill="{current_fill}"/>'
    else:
        fill_rect = ""
        
    svg_content = svg_template.format(outline_color=current_outline, fill_rect=fill_rect)
    
    filename = f"battery_{level}.svg"
    with open(os.path.join(output_dir, filename), 'w') as f:
        f.write(svg_content)

print(f"Generated SVGs in {output_dir}")
