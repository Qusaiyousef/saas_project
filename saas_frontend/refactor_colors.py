import os
import re

SCREENS_DIR = 'lib/screens'

replacements = [
    # Grey variations -> onSurfaceVariant
    (r'Colors\.grey\.shade\d+', r'Theme.of(context).colorScheme.onSurfaceVariant'),
    (r'Colors\.grey', r'Theme.of(context).colorScheme.onSurfaceVariant'),
    
    # Specific hardcoded brand color -> primary
    (r'Color\(0xFF006A61\)', r'Theme.of(context).colorScheme.primary'),
    
    # Black with opacity/values -> shadowColor
    (r'Colors\.black\.withOpacity\(([^)]+)\)', r'Theme.of(context).shadowColor.withValues(alpha: \1)'),
    (r'Colors\.black\.withValues\(alpha:\s*([^)]+)\)', r'Theme.of(context).shadowColor.withValues(alpha: \1)'),
    
    # Blue/Green -> primary
    (r'Colors\.blue\.shade\d+', r'Theme.of(context).colorScheme.primary'),
    (r'Colors\.blue(?:Grey)?', r'Theme.of(context).colorScheme.primary'),
    (r'Colors\.green\.shade\d+', r'Theme.of(context).colorScheme.primary'),
    (r'Colors\.green', r'Theme.of(context).colorScheme.primary'),
    
    # Red -> error
    (r'Colors\.red\.shade\d+', r'Theme.of(context).colorScheme.error'),
    (r'Colors\.red', r'Theme.of(context).colorScheme.error'),
    
    # Orange -> secondary (using secondary as a generic accent/warning)
    (r'Colors\.orange\.shade\d+', r'Theme.of(context).colorScheme.secondary'),
    (r'Colors\.orange', r'Theme.of(context).colorScheme.secondary'),
    
    # Black text color -> onSurface
    (r'Colors\.black', r'Theme.of(context).colorScheme.onSurface'),
]

for filename in os.listdir(SCREENS_DIR):
    if not filename.endswith('.dart'): continue
    filepath = os.path.join(SCREENS_DIR, filename)
    
    with open(filepath, 'r') as f:
        content = f.read()
        
    for pattern, repl in replacements:
        content = re.sub(pattern, repl, content)
        
    with open(filepath, 'w') as f:
        f.write(content)

