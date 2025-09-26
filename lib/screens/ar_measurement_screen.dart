import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import '../services/ar_measurement_service.dart';

class ARMeasurementScreen extends StatefulWidget {
  const ARMeasurementScreen({super.key});

  @override
  State<ARMeasurementScreen> createState() => _ARMeasurementScreenState();
}

class _ARMeasurementScreenState extends State<ARMeasurementScreen> {
  final ARMeasurementService _arService = ARMeasurementService();

  double? _currentMeasurement;
  Map<String, double>? _finalMeasurements;
  String _instructionText = 'Move camera slowly over furniture until yellow planes appear, then tap Start';
  bool _isARReady = false;
  bool _isMeasuring = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAR();
  }

  @override
  void dispose() {
    _arService.dispose();
    super.dispose();
  }

  void _initializeAR() async {
    _arService.onError = (error) {
      setState(() {
        _errorMessage = error;
      });
    };

    _arService.onMeasurementUpdate = (distance) {
      setState(() {
        _currentMeasurement = distance;
        _instructionText = 'Good! Now TAP on the yellow plane at the other end of furniture';
      });
    };

    _arService.onMeasurementComplete = (measurements) {
      setState(() {
        _finalMeasurements = measurements;
        _instructionText = 'Measurement complete!';
        _isMeasuring = false;
      });
    };

    await _arService.initializeAR();
    setState(() {
      _isARReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Measurement'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_finalMeasurements != null)
            TextButton(
              onPressed: _saveMeasurements,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _errorMessage != null
          ? _buildErrorWidget()
          : _isARReady
              ? _buildARView()
              : _buildLoadingWidget(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'AR Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing AR...'),
        ],
      ),
    );
  }

  Widget _buildARView() {
    return Stack(
      children: [
        ARView(
          onARViewCreated: _onARViewCreated,
          planeDetectionConfig: PlaneDetectionConfig.horizontal,
        ),
        _buildInstructionOverlay(),
        _buildControlsOverlay(),
        if (_finalMeasurements != null) _buildResultsOverlay(),
      ],
    );
  }

  Widget _buildInstructionOverlay() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _instructionText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (_isMeasuring) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    color: Colors.yellow[300],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Look for yellow planes on furniture surface',
                    style: TextStyle(
                      color: Colors.yellow[300],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton.extended(
            onPressed: _isMeasuring ? _resetMeasurement : _startMeasurement,
            icon: Icon(_isMeasuring ? Icons.refresh : Icons.straighten),
            label: Text(_isMeasuring ? 'Reset' : 'Start'),
            backgroundColor: _isMeasuring
                ? Colors.orange
                : Theme.of(context).colorScheme.primary,
          ),
          if (_currentMeasurement != null || _finalMeasurements != null)
            FloatingActionButton.extended(
              onPressed: _saveMeasurements,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              backgroundColor: Colors.green,
            ),
        ],
      ),
    );
  }

  Widget _buildResultsOverlay() {
    return Positioned(
      bottom: 200,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Measurements',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildMeasurementRow('Width', _finalMeasurements!['width']!),
            _buildMeasurementRow('Height', _finalMeasurements!['height']!),
            const Divider(),
            Text(
              'Area: ${(_finalMeasurements!['width']! * _finalMeasurements!['height']! / 10000).toStringAsFixed(3)} m²',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('${value.toStringAsFixed(1)} cm'),
        ],
      ),
    );
  }

  void _onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    _arService.onARViewCreated(
      arSessionManager,
      arObjectManager,
      arAnchorManager,
      arLocationManager,
    );

    arSessionManager.onPlaneOrPointTap = _onPlaneTap;
  }

  void _onPlaneTap(List<ARHitTestResult> hitTestResults) {
    _arService.onTap(hitTestResults);
  }

  void _startMeasurement() {
    setState(() {
      _isMeasuring = true;
      _instructionText = 'TAP on the yellow plane where furniture edge starts';
      _currentMeasurement = null;
      _finalMeasurements = null;
    });
    _arService.startMeasurement();
  }

  void _resetMeasurement() {
    setState(() {
      _isMeasuring = false;
      _instructionText = 'Move camera slowly over furniture until yellow planes appear, then tap Start';
      _currentMeasurement = null;
      _finalMeasurements = null;
    });
    _arService.resetMeasurement();
  }

  void _saveMeasurements() {
    if (_finalMeasurements != null) {
      Navigator.of(context).pop({
        'width': _finalMeasurements!['width'],
        'height': _finalMeasurements!['height'],
      });
    } else if (_currentMeasurement != null) {
      // If we only have one measurement, treat it as width
      Navigator.of(context).pop({
        'width': _currentMeasurement,
        'height': null,
      });
    }
  }
}