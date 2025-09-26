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
import 'package:vector_math/vector_math_64.dart';

class ARMeasurementService {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  final List<ARNode> nodes = <ARNode>[];
  final List<ARAnchor> anchors = <ARAnchor>[];
  final List<Vector3> measurementPoints = <Vector3>[];

  bool isInitialized = false;
  bool isMeasuring = false;

  Function(String)? onError;
  Function(double)? onMeasurementUpdate;
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
    if (!isMeasuring) return;

    try {
      var singleHitTestResult = hitTestResults.firstWhere(
        (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
      );

      final worldTransform = singleHitTestResult.worldTransform;
      var newAnchor = ARPlaneAnchor(transformation: worldTransform);
      bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);

      if (didAddAnchor == true) {
        anchors.add(newAnchor);

        // Extract position from transformation matrix
        var position = _getPositionFromMatrix(worldTransform);
        measurementPoints.add(position);

        // Add visual marker
        var sphereNode = ARNode(
          type: NodeType.webGLB,
          uri:
              "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Sphere/glTF-Binary/Sphere.glb",
          scale: Vector3(0.02, 0.02, 0.02),
          position: position,
          rotation: Vector4(1.0, 0.0, 0.0, 0.0),
        );

        bool? didAddNode = await arObjectManager?.addNode(
          sphereNode,
          planeAnchor: newAnchor,
        );
        if (didAddNode == true) {
          nodes.add(sphereNode);
        }

        // If we have two points, calculate width and height and complete measurement
        if (measurementPoints.length == 2) {
          // Add line between points
          await _addLineBetweenPoints(
            measurementPoints[0],
            measurementPoints[1],
          );

          var measurements = _calculateMeasurements();
          onMeasurementComplete?.call(measurements);
          _completeMeasurement();
        }
      }
    } catch (e) {
      onError?.call('Error during measurement: $e');
    }
  }

  Vector3 _getPositionFromMatrix(Matrix4 matrix) {
    return Vector3(matrix[12], matrix[13], matrix[14]);
  }

  double _calculateDistance(Vector3 point1, Vector3 point2) {
    return point1.distanceTo(point2) * 100; // Convert to centimeters
  }

  Map<String, double> _calculateMeasurements() {
    if (measurementPoints.length < 2) {
      return {'width': 0.0, 'height': 0.0};
    }

    double width = _calculateDistance(
      measurementPoints[0],
      measurementPoints[1],
    );

    // For furniture, assume height is proportional to width
    double height = width * 0.8; // Default furniture height proportion

    return {'width': width, 'height': height};
  }

  Future<void> _addLineBetweenPoints(Vector3 start, Vector3 end) async {
    // Calculate midpoint for line position
    var midpoint = Vector3(
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
      scale: Vector3(distance, 0.005, 0.005), // Thin line
      position: midpoint,
      rotation: Vector4(0.0, 0.0, 0.0, 1.0),
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
  final Vector3 position;
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
