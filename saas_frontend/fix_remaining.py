import re, os

def fix_file(path, replacements):
    with open(path, 'r') as f:
        content = f.read()
    for old, new in replacements:
        content = content.replace(old, new)
    with open(path, 'w') as f:
        f.write(content)
    print(f"Fixed {path}")

# subscriptions_screen.dart
fix_file('lib/screens/subscriptions_screen.dart', [
    ('Theme.of(context).primaryColor.withOpacity(0.05)', 'Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)'),
    ('Theme.of(context).primaryColor.withOpacity(0.1)', 'Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)'),
    ('Theme.of(context).primaryColor.withValues(alpha: 0.05)', 'Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)'),
    # After the withOpacity/withValues replacements, now fix remaining .primaryColor
    ('Theme.of(context).primaryColor,', 'Theme.of(context).colorScheme.primary,'),
    ('Theme.of(\n                                              context,\n                                            ).primaryColor,', 'Theme.of(\n                                              context,\n                                            ).colorScheme.primary,'),
    ('foregroundColor: Colors.white,', 'foregroundColor: Theme.of(context).colorScheme.onPrimary,'),
])

# users_screen.dart
fix_file('lib/screens/users_screen.dart', [
    ('foregroundColor: Colors.white,', 'foregroundColor: Theme.of(context).colorScheme.onPrimary,'),
])

# login_screen.dart
fix_file('lib/screens/login_screen.dart', [
    ('.colorScheme.primary.withOpacity(0.05)', '.colorScheme.primary.withValues(alpha: 0.05)'),
    ('.colorScheme.primary.withOpacity(0.2)', '.colorScheme.primary.withValues(alpha: 0.2)'),
])

