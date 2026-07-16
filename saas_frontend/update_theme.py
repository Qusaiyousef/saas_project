import re

with open('lib/theme/app_theme.dart', 'r') as f:
    content = f.read()

# Replace dark palette
new_dark_palette = """
  // Dark palette matching Stitch design
  static const Color darkBackground = Color(0xFF0B1121);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceRaised = Color(0xFF1F2937);
  static const Color darkOutline = Color(0xFF374151);
  static const Color darkOnSurface = Color(0xFFF9FAFB);
  static const Color darkOnSurfaceVariant = Color(0xFF9CA3AF);
  static const Color darkPrimary = Color(0xFF00E5FF);
"""

# Find and replace the dark palette
content = re.sub(r'  // Dark palette.*?static const Color darkPrimary = Color\(0xFF[A-Z0-9]+\);', new_dark_palette.strip(), content, flags=re.DOTALL)

# Ensure dark theme textTheme applies the colors correctly
text_theme_replacement = """      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: darkOnSurface,
        displayColor: darkOnSurface,
      ).copyWith("""
content = re.sub(r'      textTheme: GoogleFonts\.interTextTheme\(base\.textTheme\)\.copyWith\(', text_theme_replacement, content)

# Write back
with open('lib/theme/app_theme.dart', 'w') as f:
    f.write(content)
