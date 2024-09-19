import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyMap extends StatefulWidget {
  const MyMap({Key? key}) : super(key: key);

  @override
  _MyMapState createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  GoogleMapController? _controller;
  LatLng _center = const LatLng(-33.852, 151.211); // Default center
  bool _locationPermissionGranted = false;
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<Map<String, dynamic>> _routes = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadRoutes();
    _addInitialMarkers();
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.location.status;
    if (status.isGranted || status.isLimited) {
      _locationPermissionGranted = true;
      _getCurrentLocation();
    } else if (status.isDenied) {
      final result = await Permission.location.request();
      if (result.isGranted) {
        _locationPermissionGranted = true;
        _getCurrentLocation();
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_locationPermissionGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _center = _currentPosition!;
          _controller?.animateCamera(CameraUpdate.newLatLng(_center));
        });
      } catch (e) {
        print('Erro ao obter localização: $e');
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _getCurrentLocation();
  }

  // Função para salvar a rota no Supabase
  Future<void> _saveRoute(String title, LatLng position) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;  // Recupera o ID do usuário logado

    if (userId == null) {
      print("Usuário não autenticado");
      return;
    }

    final response = await supabase
        .from('routes')
        .insert({
          'user_id': userId,
          'title': title,
          'latitude': position.latitude,
          'longitude': position.longitude,
        }).execute();

    if (response.error == null) {
      print("Rota salva com sucesso");
    } else {
      print("Erro ao salvar rota: ${response.error!.message}");
    }
  }

  // Função para carregar rotas do Supabase
  Future<void> _loadRoutes() async {
    final supabase = Supabase.instance.client;
    
    final response = await supabase
        .from('routes')
        .select()
        .execute();

    if (response.error == null && response.data != null) {
      final List<dynamic> data = response.data as List<dynamic>;

      setState(() {
        _routes = data.map((e) => e as Map<String, dynamic>).toList();
        for (var route in _routes) {
          _markers.add(Marker(
            markerId: MarkerId(route['title']),
            position: LatLng(route['latitude'], route['longitude']),
            infoWindow: InfoWindow(title: route['title']),
            onTap: () {
              _onMarkerTapped(LatLng(route['latitude'], route['longitude']));
            },
          ));
        }
      });
    } else {
      print("Erro ao carregar rotas: ${response.error!.message}");
    }
  }

  void _addInitialMarkers() {
    _markers.add(
      Marker(
        markerId: MarkerId('ponto_1'),
        position: LatLng(-27.096234590439202, -52.66679448070092),
        infoWindow: InfoWindow(title: 'Ponto 1'),
        onTap: () {
          _onMarkerTapped(LatLng(-27.096234590439202, -52.66679448070092));
        },
      ),
    );
  }

  void _onMarkerTapped(LatLng destination) async {
    if (_currentPosition == null) return;

    final directions = await _getDirections(_currentPosition!, destination);
    setState(() {
      _polylines.clear(); // Limpa a rota existente antes de adicionar a nova
      _polylines.add(Polyline(
        polylineId: PolylineId('route'),
        points: directions,
        color: Colors.blue,
        width: 5,
      ));
    });
  }

  Future<List<LatLng>> _getDirections(LatLng start, LatLng end) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=YOUR_API_KEY';

    try {
      final response = await http.get(Uri.parse(url));
      final json = jsonDecode(response.body);

      if (json['routes'].isNotEmpty) {
        final points = json['routes'][0]['overview_polyline']['points'];
        return _decodePolyline(points);
      }
    } catch (e) {
      print('Erro ao obter direções: $e');
    }
    return [];
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      LatLng p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      polyline.add(p);
    }
    return polyline;
  }

  void _addNewStop(String title, LatLng position) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(title),
          position: position,
          infoWindow: InfoWindow(title: title),
          onTap: () {
            _onMarkerTapped(position);
          },
        ),
      );
    });
    _saveRoute(title, position); // Salva a rota no Supabase
  }

  void _showAddStopDialog() {
    final _titleController = TextEditingController();
    final _latController = TextEditingController();
    final _lngController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Nova Parada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: _latController,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _lngController,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final title = _titleController.text;
                final lat = double.tryParse(_latController.text);
                final lng = double.tryParse(_lngController.text);

                if (title.isNotEmpty && lat != null && lng != null) {
                  final position = LatLng(lat, lng);
                  _addNewStop(title, position);
                }

                Navigator.of(context).pop();
              },
              child: const Text('Adicionar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Example'),
        backgroundColor: Colors.blue,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_location),
              title: const Text('Adicionar Parada'),
              onTap: () {
                Navigator.pop(context);
                _showAddStopDialog();
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
          ),
        ],
      ),
    );
  }
}
