# Relocata App 📏📦

A Flutter-based mobile application for cataloging and measuring furniture items for relocation planning. Capture images, record dimensions, and organize your inventory efficiently.

## 📱 Device Requirements

- **Test Device**: Google Pixel 6a (not limited to this model)
- **OS**: Android 16
- **Required**: ARCore support (Pixel 6a ✅)
- **Storage**: ~100MB for app + space for photos

## 🎯 Core Features

### User Flow
1. **Register Item** → Add furniture name and category
2. **Capture Image** → Take photo for visual reference  
3. **Take Dimensions** → Measure using AR or manual input
4. **Save Details** → Store in local database

## 🛠️ Technical Stack

### Dependencies
Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Core packages
  arcore_flutter_plugin: ^0.1.0  # AR measurement
  camera: ^0.10.5                # Camera access
  image_picker: ^1.0.4           # Gallery access
  path_provider: ^2.1.1          # File storage
  sqflite: ^2.3.0                # Local database
  
  # UI/UX
  provider: ^6.0.5               # State management
  cached_network_image: ^3.3.0   # Image handling
  flutter_speed_dial: ^7.0.0     # FAB menu
  
  # Utilities  
  uuid: ^4.1.0                   # Unique IDs
  intl: ^0.18.1                  # Formatting
  share_plus: ^7.2.1             # Export functionality
```

## 📋 App Structure

```
furniture_measure_app/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   └── furniture_item.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── item_registration_screen.dart
│   │   ├── camera_capture_screen.dart
│   │   ├── measurement_screen.dart
│   │   └── item_details_screen.dart
│   ├── services/
│   │   ├── database_service.dart
│   │   ├── ar_measurement_service.dart
│   │   └── storage_service.dart
│   └── widgets/
│       ├── item_card.dart
│       └── measurement_overlay.dart
```

## 🔄 Implementation Flow

### 1. Item Registration Screen

**Features:**
- Text input for item name (e.g., "2-seat sofa")
- Category dropdown (Sofa, Chair, Table, Bed, Storage, Appliance, Other)
- Room assignment (Living Room, Bedroom, Kitchen, etc.)
- Optional notes field

**Implementation:**
```dart
// Basic form fields
TextField(
  decoration: InputDecoration(
    labelText: 'Item Name',
    hintText: 'e.g., 2-seat sofa',
  ),
)
```

### 2. Image Capture Screen

**Features:**
- Camera preview with guide overlay
- Option to retake photo
- Gallery selection alternative
- Auto-save to app directory

**Tips for Best Results:**
- Ensure good lighting
- Include entire item in frame
- Capture from multiple angles (optional)
- Keep 3-5 feet distance

### 3. Measurement Screen

**Two Modes:**

#### AR Measurement Mode (Recommended)
- Point-to-point measurement
- Automatic edge detection
- Real-time dimension display
- Unit toggle (cm/inches)

#### Manual Input Mode (Fallback)
- Length, Width, Height input fields
- Weight (optional)
- Quick presets for common sizes

**Measurement Process:**
1. Detect surface plane
2. Place first anchor point
3. Drag to second point
4. Confirm measurement
5. Repeat for all dimensions

### 4. Save & View Details

**Stored Data:**
- Unique ID
- Item name & category
- Photo path
- Dimensions (L × W × H)
- Volume calculation
- Timestamp
- Room assignment
- Notes

## 📊 Database Schema

```sql
CREATE TABLE furniture_items (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT,
  room TEXT,
  image_path TEXT,
  length_cm REAL,
  width_cm REAL,
  height_cm REAL,
  weight_kg REAL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🎨 UI/UX Guidelines

### Color Scheme
- Primary: Material You (Android 16 Dynamic Color)
- Accent: Teal for measurement indicators
- Error: Red for invalid measurements
- Success: Green for saved items

### Navigation
- Bottom Navigation Bar:
  - Home (List view)
  - Add Item (+)
  - Categories
  - Export

### Measurement Interface
- Large, clear measurement readouts
- Visual feedback for detected surfaces
- Undo/Redo for measurements
- Lock aspect ratio option

## 🚀 Setup Instructions

### 1. Environment Setup
```bash
# Install Flutter (if not already installed)
flutter channel stable
flutter upgrade

# Verify setup
flutter doctor

# Create new project
flutter create furniture_measure_app
cd furniture_measure_app
```

### 2. Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-feature android:name="android.hardware.camera.ar" />

<application>
  <meta-data 
    android:name="com.google.ar.core" 
    android:value="required" />
</application>
```

### 3. Gradle Configuration
In `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34
    minSdkVersion 24  // Required for ARCore
    targetSdkVersion 34
}
```

### 4. Run the App
```bash
# Check connected devices
flutter devices

# Run on Pixel 6a
flutter run

# Build APK for installation
flutter build apk --release
```

## 📈 Features Roadmap

### Phase 1 (MVP) ✅
- [x] Basic item registration
- [x] Photo capture
- [x] Manual dimension input
- [x] Local storage

### Phase 2 (Current)
- [ ] AR measurement integration
- [ ] Multiple photos per item
- [ ] Category templates

### Phase 3 (Enhanced)
- [ ] Cloud backup
- [ ] Space planner (2D layout)
- [ ] Moving checklist
- [ ] QR labels for boxes

### Phase 4 (Advanced)
- [ ] 3D room visualization
- [ ] Volume optimization
- [ ] Moving cost calculator
- [ ] Share with movers

## 🐛 Troubleshooting

### Common Issues

**ARCore not working:**
- Ensure good lighting
- Clear camera lens
- Update Google Play Services for AR
- Restart app

**Measurements inaccurate:**
- Calibrate by measuring known object first
- Keep phone steady during measurement
- Ensure surface is detected (look for dots)

**App crashes on camera:**
- Check permissions in Settings
- Clear app cache
- Reduce photo quality in settings

## 📸 Best Practices

### For Accurate Measurements
1. **Prepare the space**: Clear area around furniture
2. **Good lighting**: Natural light or bright room lights
3. **Multiple measurements**: Measure twice for accuracy
4. **Reference object**: Place ruler/tape measure in first photo
5. **Document details**: Note special features (removable legs, foldable, etc.)

### For Organization
1. **Consistent naming**: "Room - Item - Size" (e.g., "Living - Sofa - 2 Seat")
2. **Take overview shots**: Include room context
3. **Measure assembled state**: Unless it ships disassembled
4. **Group by room**: Easier for planning layout
5. **Export regularly**: Backup your data

## 📤 Export Options

- **CSV**: Spreadsheet with all measurements
- **PDF**: Visual catalog with photos
- **JSON**: For import to other apps
- **Share**: Send to movers or family

## 🤝 Testing Checklist

- [ ] Register item with all fields
- [ ] Capture clear photo
- [ ] Test AR measurement on known object
- [ ] Verify saved measurements
- [ ] Edit existing item
- [ ] Delete item
- [ ] Export data
- [ ] Test in different lighting conditions
- [ ] Verify on Pixel 6a specifically

## 📝 Sample Data Entry

**Example: 2-Seat Sofa**
- Name: "Living Room 2-Seat Sofa"
- Category: Sofa
- Room: Living Room
- Dimensions: 150cm × 85cm × 90cm
- Weight: 45kg
- Notes: "Blue fabric, removable cushions, legs unscrew"

## 🔗 Resources

- [ARCore Documentation](https://developers.google.com/ar)
- [Flutter Camera Plugin](https://pub.dev/packages/camera)
- [Material Design 3 Guidelines](https://m3.material.io/)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)

## 📧 Support

For issues specific to Pixel 6a or Android 16:
- Check ARCore compatibility
- Ensure latest system updates
- Test with Google's Measure app first

---

**Version**: 1.0.0  
**Last Updated**: September 2025  
**Target Device**: Google Pixel 6a (Android 16)  
**Purpose**: Furniture cataloging for relocation planning