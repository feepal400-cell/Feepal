import sys

file_path = r'c:\Users\Administrator\Desktop\FeePal Project\lib\parent_dashboard_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
skip = False

for line in lines:
    if 'SystemChrome.setSystemUIOverlayStyle(' in line:
        skip = True
        continue
    if skip and '));' in line:
        skip = False
        continue
    if not skip:
        new_lines.append(line)

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("Done")
