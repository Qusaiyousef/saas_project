import os
import re

SCREENS_DIR = 'lib/screens'

# We want to find "const [WidgetName](...Theme.of(context)...)" and remove the const.
# Because regex is tricky with nested parentheses, we can just replace "const " with ""
# on the exact line if the line contains "Theme.of(context)".
# Actually, replacing "const " on a line containing "Theme.of(context)" might be safe enough for most cases, 
# but we have to be careful about things like "const SizedBox(height: 16), Text(..., color: Theme.of(context)...)"

def remove_const_on_line(line):
    if "Theme.of(context)" in line and "const " in line:
        # We replace specific known usages
        line = re.sub(r'const\s+(TextStyle|Icon|BoxShadow|BorderSide|Border|Center|Padding|Column|Row|Container|Text|SizedBox|EdgeInsets)', r'\1', line)
    return line

for filename in os.listdir(SCREENS_DIR):
    if not filename.endswith('.dart'): continue
    filepath = os.path.join(SCREENS_DIR, filename)
    
    with open(filepath, 'r') as f:
        lines = f.readlines()
        
    new_lines = [remove_const_on_line(line) for line in lines]
    
    with open(filepath, 'w') as f:
        f.writelines(new_lines)

