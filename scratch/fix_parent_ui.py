import sys

file_path = r'c:\Users\Administrator\Desktop\FeePal Project\lib\parent_dashboard_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
skip = False

for i, line in enumerate(lines):
    if 'AnnotatedRegion<SystemUiOverlayStyle>' in line:
        skip = True
        new_lines.append('    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(\n')
        new_lines.append('      statusBarColor: Colors.transparent,\n')
        new_lines.append('      statusBarIconBrightness: Brightness.light,\n')
        new_lines.append('      systemNavigationBarColor: Colors.white,\n')
        new_lines.append('      systemNavigationBarIconBrightness: Brightness.dark,\n')
        new_lines.append('      systemNavigationBarDividerColor: Colors.transparent,\n')
        new_lines.append('    ));\n\n')
        continue
    
    if skip and 'child: ValueListenableBuilder<bool>(' in line:
        new_lines.append('    return ValueListenableBuilder<bool>(\n')
        skip = False
        continue
        
    if not skip:
        new_lines.append(line)

# Also fix the end of the file (remove extra braces)
final_lines = []
brace_count = 0
for line in new_lines:
    if 'builder: (context, isUrdu, child) {' in line:
        brace_count += 1
    # This is a very crude way to fix the end, but let's try to find the specific pattern
    final_lines.append(line)

# Let's just write a clean version of the build method end
content = "".join(final_lines)
# Remove the extra ); that was for AnnotatedRegion
content = content.replace('      ),\n    );\n  }\n}', '    );\n  }\n}')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
