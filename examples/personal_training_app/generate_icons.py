from PIL import Image, ImageDraw
import os

# Create simple square icons with blue gradient background
def create_icon(size, output_path):
    # Create a square image with gradient
    img = Image.new('RGB', (size, size), color='white')
    draw = ImageDraw.Draw(img)
    
    # Draw gradient background (blue)
    for y in range(size):
        ratio = y / size
        r = int(37 + (124 - 37) * ratio)   # 2563EB to 7C3AED gradient
        g = int(99 + (58 - 99) * ratio)
        b = int(235 + (237 - 235) * ratio)
        draw.rectangle([(0, y), (size, y+1)], fill=(r, g, b))
    
    # Try to load and paste the logo
    try:
        logo = Image.open('assets/logo.png')
        # Resize logo to fit (80% of icon size)
        logo_size = int(size * 0.8)
        logo = logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
        
        # Convert to RGBA if not already
        if logo.mode != 'RGBA':
            logo = logo.convert('RGBA')
        
        # Center the logo
        position = ((size - logo_size) // 2, (size - logo_size) // 2)
        img.paste(logo, position, logo)
    except Exception as e:
        print(f"Could not load logo: {e}")
        # Just use gradient background
        pass
    
    img.save(output_path, 'PNG')
    print(f"Created {output_path}")

# Generate all required icons
os.makedirs('web/icons', exist_ok=True)

create_icon(192, 'web/icons/Icon-192.png')
create_icon(512, 'web/icons/Icon-512.png')
create_icon(192, 'web/icons/Icon-maskable-192.png')
create_icon(512, 'web/icons/Icon-maskable-512.png')

print("\nAll icons generated successfully!")
