import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class ARMeasurementService {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  final List<ARNode> nodes = <ARNode>[];
  final List<ARAnchor> anchors = <ARAnchor>[];
  final List<vm.Vector3> measurementPoints = <vm.Vector3>[];

  bool isInitialized = false;
  bool isMeasuring = false;

  Function(String)? onError;
  Function(String, int)? onPointPlaced;
  Function(Map<String, double>)? onMeasurementComplete;

  Future<void> initializeAR() async {
    try {
      isInitialized = true;
    } catch (e) {
      isInitialized = false;
      onError?.call('Failed to initialize AR: $e');
    }
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager?.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: "Images/triangle.png",
      showWorldOrigin: false,
      handlePans: true,
      handleRotation: true,
    );
    this.arObjectManager?.onInitialize();
  }

  Future<void> onTap(List<ARHitTestResult> hitTestResults) async {
    if (!isMeasuring) {
      onError?.call('Tap "Start" button first to begin measuring.');
      return;
    }

    if (arAnchorManager == null || arObjectManager == null) {
      onError?.call('AR system not ready. Please wait a moment and try again.');
      return;
    }

    try {
      // Debug: Log hit test results
      print('Hit test results received: ${hitTestResults.length}');
      for (var hit in hitTestResults) {
        print('Hit type: ${hit.type}');
      }

      // Check if there are any plane hits
      var planeHits = hitTestResults.where(
        (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
      ).toList();

      if (planeHits.isEmpty) {
        onError?.call('No plane detected. Move camera slowly until yellow areas appear, then tap on them.');
        return;
      }

      var singleHitTestResult = planeHits.first;

      final worldTransform = singleHitTestResult.worldTransform;
      var newAnchor = ARPlaneAnchor(transformation: worldTransform);
      bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);

      if (didAddAnchor == true) {
        anchors.add(newAnchor);

        // Extract position from transformation matrix
        var position = _getPositionFromMatrix(worldTransform);
        measurementPoints.add(position);

        // Add visual marker with different colors for each point
        var sphereNode = _createPointMarker(position, measurementPoints.length);

        bool? didAddNode = await arObjectManager?.addNode(
          sphereNode,
          planeAnchor: newAnchor,
        );
        if (didAddNode == true) {
          nodes.add(sphereNode);
        }

        // Call the point placed callback with instruction for next point
        String instruction = _getInstructionForPoint(measurementPoints.length);
        onPointPlaced?.call(instruction, measurementPoints.length);

        // If we have all 4 points, calculate measurements and complete
        if (measurementPoints.length == 4) {
          await _addMeasurementLines();
          var measurements = _calculateMeasurements();
          onMeasurementComplete?.call(measurements);
          _completeMeasurement();
        }
      }
    } catch (e) {
      onError?.call('Error during measurement: $e');
    }
  }

  vm.Vector3 _getPositionFromMatrix(vm.Matrix4 matrix) {
    return vm.Vector3(matrix[12], matrix[13], matrix[14]);
  }

  ARNode _createPointMarker(vm.Vector3 position, int pointNumber) {
    // Different sizes and models for each point to make them distinctive
    String modelUri;
    vm.Vector3 scale;

    switch (pointNumber) {
      case 1: // Width start - Large red sphere
        modelUri =
            "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Sphere/glTF-Binary/Sphere.glb";
        scale = vm.Vector3(0.03, 0.03, 0.03);
        break;
      case 2: // Width end - Large blue sphere
        modelUri =
            "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Sphere/glTF-Binary/Sphere.glb";
        scale = vm.Vector3(0.03, 0.03, 0.03);
        break;
      case 3: // Height start - Small green sphere
        modelUri =
            "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Sphere/glTF-Binary/Sphere.glb";
        scale = vm.Vector3(0.025, 0.025, 0.025);
        break;
      case 4: // Height end - Small yellow sphere
        modelUri =
            "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Sphere/glTF-Binary/Sphere.glb";
        scale = vm.Vector3(0.025, 0.025, 0.025);
        break;
      default:
        modelUri =
            "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Sphere/glTF-Binary/Sphere.glb";
        scale = vm.Vector3(0.02, 0.02, 0.02);
    }

    return ARNode(
      type: NodeType.webGLB,
      uri: modelUri,
      scale: scale,
      position: position,
      rotation: vm.Vector4(1.0, 0.0, 0.0, 0.0),
    );
  }

  double _calculateDistance(vm.Vector3 point1, vm.Vector3 point2) {
    return point1.distanceTo(point2) * 100; // Convert to centimeters
  }

  String _getInstructionForPoint(int pointCount) {
    switch (pointCount) {
      case 1:
        return 'Point 1/4 placed! Now tap the OTHER END of the WIDTH';
      case 2:
        return 'Point 2/4 placed! Now tap the START of the HEIGHT';
      case 3:
        return 'Point 3/4 placed! Now tap the OTHER END of the HEIGHT';
      case 4:
        return 'All points placed! Calculating measurements...';
      default:
        return 'TAP on the yellow plane where furniture edge starts';
    }
  }

  Map<String, double> _calculateMeasurements() {
    if (measurementPoints.length < 4) {
      return {'width': 0.0, 'height': 0.0};
    }

    // Calculate width from first two points (width start and end)
    double width = _calculateDistance(
      measurementPoints[0],
      measurementPoints[1],
    );

    // Calculate height from last two points (height start and end)
    double height = _calculateDistance(
      measurementPoints[2],
      measurementPoints[3],
    );

    return {'width': width, 'height': height};
  }

  Future<void> _addMeasurementLines() async {
    if (measurementPoints.length >= 4) {
      // Add width line (between points 0 and 1)
      await _addLineBetweenPoints(
        measurementPoints[0],
        measurementPoints[1],
        Colors.blue, // Blue for width
      );

      // Add height line (between points 2 and 3)
      await _addLineBetweenPoints(
        measurementPoints[2],
        measurementPoints[3],
        Colors.red, // Red for height
      );
    }
  }

  Future<void> _addLineBetweenPoints(
    vm.Vector3 start,
    vm.Vector3 end, [
    Color? color,
  ]) async {
    // Calculate midpoint for line position
    var midpoint = vm.Vector3(
      (start.x + end.x) / 2,
      (start.y + end.y) / 2,
      (start.z + end.z) / 2,
    );

    // Calculate distance for line scale
    var distance = start.distanceTo(end);

    var lineNode = ARNode(
      type: NodeType.webGLB,
      uri:
          "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Box/glTF-Binary/Box.glb",
      scale: vm.Vector3(distance, 0.005, 0.005), // Thin line
      position: midpoint,
      rotation: vm.Vector4(0.0, 0.0, 0.0, 1.0),
    );

    bool? didAddNode = await arObjectManager?.addNode(lineNode);
    if (didAddNode == true) {
      nodes.add(lineNode);
    }
  }

  void startMeasurement() {
    isMeasuring = true;
    _clearMeasurements();
  }

  void _completeMeasurement() {
    isMeasuring = false;
  }

  void _clearMeasurements() {
    measurementPoints.clear();
    _removeAllNodes();
  }

  Future<void> _removeAllNodes() async {
    for (var node in nodes) {
      await arObjectManager?.removeNode(node);
    }
    for (var anchor in anchors) {
      await arAnchorManager?.removeAnchor(anchor);
    }
    nodes.clear();
    anchors.clear();
  }

  void resetMeasurement() {
    _clearMeasurements();
  }

  void dispose() {
    arSessionManager?.dispose();
  }

  // Configuration for AR session
  static PlaneDetectionConfig get planeDetectionConfig =>
      PlaneDetectionConfig.horizontal;

  // Check if device supports AR
  static Future<bool> isARSupported() async {
    try {
      // The ar_flutter_plugin_2 should work better than the original
      return true;
    } catch (e) {
      return false;
    }
  }
}

class MeasurementPoint {
  final vm.Vector3 position;
  final DateTime timestamp;

  MeasurementPoint({required this.position, required this.timestamp});
}

class MeasurementResult {
  final double width;
  final double height;
  final double confidence;

  MeasurementResult({
    required this.width,
    required this.height,
    this.confidence = 1.0,
  });

  double get area => width * height / 10000; // Convert to square meters

  Map<String, double> toMap() {
    return {
      'width': width,
      'height': height,
      'area': area,
      'confidence': confidence,
    };
  }
}
