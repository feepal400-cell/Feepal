import sys

file_path = r'c:\Users\Administrator\Desktop\FeePal Project\lib\parent_dashboard_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Remove line 1109 (0-indexed 1108)
if len(lines) >= 1109 and ');' in lines[1108]:
    del lines[1108]

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("Done")
