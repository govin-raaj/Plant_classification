import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'utils.dart'; 

class ScanDetailPage extends StatelessWidget {
  final Map<String, dynamic> scanData;
  final VoidCallback? onDelete;

  const ScanDetailPage({Key? key, required this.scanData, this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  
    String shareText = formatPlantInfo(scanData);

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Details'),
        actions: [
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                onDelete!();
                Navigator.pop(context);
              },
            ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              Share.share(shareText, subject: 'Plant Scan Result');
            },
          ),
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareText));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Scan info copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: PlantDetailCards(plantData: scanData),
        ),
      ),
    );
  }
}
