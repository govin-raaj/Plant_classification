import 'package:flutter/material.dart';

String formatPlantInfo(Map<String, dynamic> data, {int indent = 0}) {
  StringBuffer buffer = StringBuffer();
  data.forEach((key, value) {
    final spaces = ' ' * indent;
    if (value is Map) {
      buffer.writeln('$spaces$key:');
      buffer.write(formatPlantInfo(Map<String, dynamic>.from(value), indent: indent + 2));
    } else if (value is List) {
      buffer.writeln('$spaces$key: ${value.join(", ")}');
    } else {
      buffer.writeln('$spaces$key: $value');
    }
  });
  return buffer.toString();
}



class PlantDetailCards extends StatelessWidget {
  final Map<String, dynamic> plantData;
  const PlantDetailCards({Key? key, required this.plantData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String plantName;
    Map<String, dynamic> details;

    // Handle two possible shapes:
    // (a) If plantData has one key, and its value is a Map, treat that as { name: {...} }
    // (b) Else, just show the map itself
    if (plantData.length == 1 && plantData.values.first is Map && plantData.values.first is Map<String, dynamic>) {
      plantName = plantData.keys.first;
      details = Map<String, dynamic>.from(plantData.values.first);
    } else {
      plantName = plantData['predicted_class'] ?? 'Plant Details';
      details = Map<String, dynamic>.from(plantData);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Colors.green[100],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Center(
              child: Text(
                plantName,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[800]),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        ...details.entries.map((entry) => _buildFieldCard(entry)).toList(),
      ],
    );
  }

  Widget _buildFieldCard(MapEntry<String, dynamic> entry) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(14),
        child: _buildField(entry.key, entry.value),
      ),
    );
  }

  Widget _buildField(String key, dynamic value) {
    if (value is Map<String, dynamic>) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$key:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[900])),
          ...value.entries.map((e) => Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: _buildField('${e.key}', e.value),
          )),
        ],
      );
    } else if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$key:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[900])),
          ...value.map((item) => Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: Colors.green[700])),
                Expanded(child: Text(item.toString())),
              ],
            ),
          ))
        ],
      );
    } else {
      return RichText(
        text: TextSpan(
          text: "$key: ",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green[900]),
          children: [
            TextSpan(
              text: value.toString(),
              style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15, color: Colors.green[800]),
            ),
          ],
        ),
      );
    }
  }
}
