import re

file_path = 'lib/features/match/match_stat_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace Typography
content = content.replace("GoogleFonts.oswald", "GoogleFonts.plusJakartaSans")
content = content.replace("GoogleFonts.montserrat", "GoogleFonts.inter")
content = content.replace("const TextStyle", "GoogleFonts.inter")
content = content.replace("TextStyle(", "GoogleFonts.inter(")

# Add ExportScreen import
content = content.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../export/export_screen.dart';")

# Replace Actions
actions_original = '''        actions: [
          IconButton(icon: const Icon(Icons.share, color: Colors.white, size: 18), onPressed: () {}),
          IconButton(icon: const Icon(Icons.download, color: Colors.white, size: 18), onPressed: () {}),
        ],'''

actions_new = '''        actions: [
          if (_match != null)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white, size: 18),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ExportScreen(match: _match!)));
              },
            ),
          if (_match != null)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white, size: 18),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ExportScreen(match: _match!)));
              },
            ),
        ],'''

content = content.replace(actions_original, actions_new)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Success')
