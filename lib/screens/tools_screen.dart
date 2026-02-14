import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'mistake_book_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('tools')),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.book, color: Colors.blue),
            title: Text(l10n.get('mistakeBook')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MistakeBookScreen(),
                ),
              );
            },
          ),
          // Add more tools here in the future
        ],
      ),
    );
  }
}
