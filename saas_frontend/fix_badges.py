import os
import re

SCREENS_DIR = 'lib/screens'

replacements = [
    # Card Background: remove withValues(alpha: 0.6) so cards are solid, matching the theme exactly
    (r'Theme\.of\(context\)\.cardColor\.withValues\(alpha:\s*0\.6\)', r'Theme.of(context).cardColor'),
    
    # Dashboard Badges
    (r'color: isWarning \? Theme\.of\(context\)\.colorScheme\.secondary : \(primaryBadge \? Theme\.of\(context\)\.colorScheme\.primary : Theme\.of\(context\)\.primaryColor\.withValues\(alpha: 0\.1\)\)', 
     r'color: isWarning ? Theme.of(context).colorScheme.error.withValues(alpha: 0.15) : (primaryBadge ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05))'),
     
    (r'color: isWarning \? Theme\.of\(context\)\.colorScheme\.secondary : \(primaryBadge \? Theme\.of\(context\)\.colorScheme\.primary : Theme\.of\(context\)\.primaryColor\)',
     r'color: isWarning ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary'),

    # Users screen / Role badges
    (r'color: Theme\.of\(context\)\.colorScheme\.primary,', 
     r'color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),'),

    # Finance screen badges (e.g. Completed)
    (r'style: TextStyle\(fontSize: 11, color: Theme\.of\(context\)\.colorScheme\.primary\.withValues\(alpha: 0\.15\),', 
     r'style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary,'), # wait, the previous line made the text color withValues as well? 
     # Actually the above replacement `Theme.of(context).colorScheme.primary,` might match too broadly.
]

def fix_screen(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
        
    # We will specifically target the `Container` decorations for badges in each file.
    # Dashboard Screen:
    if 'dashboard_screen' in filepath:
        content = re.sub(
            r'color: isWarning \? Theme\.of\(context\)\.colorScheme\.secondary : \(primaryBadge \? Theme\.of\(context\)\.colorScheme\.primary : Theme\.of\(context\)\.primaryColor\.withValues\(alpha: 0\.1\)\)',
            r'color: isWarning ? Theme.of(context).colorScheme.error.withValues(alpha: 0.15) : (primaryBadge ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05))',
            content
        )
        content = re.sub(
            r'color: isWarning \? Theme\.of\(context\)\.colorScheme\.secondary : \(primaryBadge \? Theme\.of\(context\)\.colorScheme\.primary : Theme\.of\(context\)\.primaryColor\)',
            r'color: isWarning ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary',
            content
        )
        content = content.replace('Theme.of(context).cardColor.withValues(alpha: 0.6)', 'Theme.of(context).cardColor')
        
    # Finance Screen:
    if 'finance_screen' in filepath:
        # The badge is:
        # color: Theme.of(context).colorScheme.primary,
        # borderRadius: BorderRadius.circular(12),
        content = content.replace(
            'color: Theme.of(context).colorScheme.primary,\n                                            borderRadius: BorderRadius.circular(12),',
            'color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),\n                                            borderRadius: BorderRadius.circular(12),'
        )
        content = content.replace('Theme.of(context).cardColor.withValues(alpha: 0.6)', 'Theme.of(context).cardColor')
        
    # Users Screen:
    if 'users_screen' in filepath:
        content = content.replace(
            'color: Theme.of(context).colorScheme.primary,\n                                          borderRadius: BorderRadius.circular(12),',
            'color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),\n                                          borderRadius: BorderRadius.circular(12),'
        )
        # also active/inactive badges
        content = content.replace(
            'color: isActive\n                                                ? Theme.of(context).colorScheme.primary\n                                                : Theme.of(context).colorScheme.error,',
            'color: isActive\n                                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)\n                                                : Theme.of(context).colorScheme.error.withValues(alpha: 0.15),'
        )
        content = content.replace('Theme.of(context).cardColor.withValues(alpha: 0.6)', 'Theme.of(context).cardColor')
        
    # Subscriptions Screen:
    if 'subscriptions_screen' in filepath:
        content = content.replace(
            'color: planColor,\n                                            borderRadius: BorderRadius.circular(12),',
            'color: planColor.withValues(alpha: 0.15),\n                                            borderRadius: BorderRadius.circular(12),'
        )
        # active/cancelled badges
        content = content.replace(
            'color: isActive\n                                                ? Theme.of(context).colorScheme.primary\n                                                : Theme.of(context).colorScheme.error,',
            'color: isActive\n                                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)\n                                                : Theme.of(context).colorScheme.error.withValues(alpha: 0.15),'
        )
        content = content.replace('Theme.of(context).cardColor.withValues(alpha: 0.6)', 'Theme.of(context).cardColor')
        
    # Customers Screen:
    if 'customers_screen' in filepath:
        content = content.replace(
            'color: isActive\n                                                ? Theme.of(context).colorScheme.primary\n                                                : Theme.of(context).colorScheme.error,',
            'color: isActive\n                                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)\n                                                : Theme.of(context).colorScheme.error.withValues(alpha: 0.15),'
        )
        content = content.replace('Theme.of(context).cardColor.withValues(alpha: 0.6)', 'Theme.of(context).cardColor')
        
    with open(filepath, 'w') as f:
        f.write(content)

for filename in os.listdir(SCREENS_DIR):
    if not filename.endswith('.dart'): continue
    filepath = os.path.join(SCREENS_DIR, filename)
    fix_screen(filepath)

