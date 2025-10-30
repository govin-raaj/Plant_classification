import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'scan_detail_page.dart';
import 'utils.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  File? _image;
  bool _loading = false;
  Map<String, dynamic>? _result;
  final picker = ImagePicker();
  List<Map<String, dynamic>> history = [];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
  }

  Future<void> _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> stored = prefs.getStringList('history') ?? [];
    setState(() {
      history = stored.map((e) => json.decode(e) as Map<String, dynamic>).toList();
    });
  }

  Future<void> _addToHistory(Map<String, dynamic> plantData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    history.insert(0, plantData);
    if (history.length > 10) history = history.sublist(0, 10);
    List<String> encoded = history.map((e) => json.encode(e)).toList();
    prefs.setStringList('history', encoded);
  }

  Future<void> _clearHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('history');
    setState(() {
      history.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('History cleared successfully')),
    );
  }

  void _deleteSingleHistory(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    history.removeAt(index);
    List<String> encoded = history.map((e) => json.encode(e)).toList();
    await prefs.setStringList('history', encoded);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Scan deleted successfully')),
    );
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);
    if (!allGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please grant all permissions to proceed')),
      );
    }
    return allGranted;
  }

  Future<void> _pickImage(ImageSource source) async {
    Permission permission;

    if (source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
      permission = Platform.isIOS ? Permission.photos : Permission.storage;
    }

    PermissionStatus status = await permission.status;

    if (status.isGranted) {
      final pickedFile = await picker.pickImage(source: source, maxWidth: 1024);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final size = await file.length();
        if (size > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File too large. Max 5MB allowed.')),
          );
          return;
        }

        setState(() {
          _image = file;
          _result = null;
        });
        _animationController.forward(from: 0);
      }
    } else if (status.isDenied) {
      PermissionStatus newStatus = await permission.request();
      if (newStatus.isGranted) {
        _pickImage(source);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission denied. Cannot access ${source == ImageSource.camera ? "camera" : "gallery"}')),
        );
      }
    } else if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permission permanently denied. Please enable it in app settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;
    setState(() => _loading = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://192.168.1.2:8000/predict'));
      request.files.add(await http.MultipartFile.fromPath('file', _image!.path));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        setState(() {
          _result = jsonData;
        });
        await _addToHistory(jsonData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('API Error: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

 Widget _buildResult() {
  if (_result == null) return SizedBox.shrink();

  // _result should be your parsed API response as a Map
  return AnimatedContainer(
    duration: Duration(milliseconds: 500),
    margin: EdgeInsets.all(16),
    padding: EdgeInsets.all(0),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.green.shade100, blurRadius: 8, offset: Offset(0, 4)),
      ],
    ),
    child: PlantDetailCards(plantData: _result!),
  );
}


  Widget _buildHistoryGallery() {
    if (history.isEmpty) return SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Scans',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800])),
              TextButton.icon(
                onPressed: _clearHistory,
                icon: Icon(Icons.delete, color: Colors.red),
                label: Text('Clear History', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: history.length,
            itemBuilder: (context, index) {
              var plant = history[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScanDetailPage(
                        scanData: plant,
                        onDelete: () {
                          _deleteSingleHistory(index);
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 100,
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.green.shade100, blurRadius: 6, offset: Offset(0, 3))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_florist, size: 40, color: Colors.green),
                      SizedBox(height: 8),
                      Text(plant['predicted_class'] ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTips() {
    List<String> tips = [
      'Use natural light for photos',
      'Keep the plant centered',
      'Avoid blurry images',
      'Capture leaves clearly',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Quick Tips', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800])),
        ),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            itemBuilder: (context, index) => Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.green[100], borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(tips[index], style: TextStyle(fontSize: 12))),
            ),
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🌿 Plant Classifier')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 16),
            _image == null
                ? Text('Upload a plant image', style: TextStyle(fontSize: 16, color: Colors.green[700]))
                : ScaleTransition(
                    scale: Tween(begin: 0.8, end: 1.0).animate(CurvedAnimation(
                        parent: _animationController, curve: Curves.easeOutBack)),
                    child: Image.file(_image!, height: 250, fit: BoxFit.cover)),
            SizedBox(height: 16),
            if (_loading) CircularProgressIndicator(),
            if (!_loading && _image != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: _uploadImage, child: Text('Analyze')),
                  SizedBox(width: 16),
                  ElevatedButton(onPressed: () => setState(() => _image = null), child: Text('Retake')),
                  SizedBox(width: 16),
                  ElevatedButton(onPressed: () => _pickImage(ImageSource.gallery), child: Text('Gallery')),
                ],
              ),
            SizedBox(height: 16),
            _buildResult(),
            _buildHistoryGallery(),
            _buildQuickTips(),
            SizedBox(height: 16),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickImage(ImageSource.camera),
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}
