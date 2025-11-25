import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// Helper class to detect device manufacturer and provide manufacturer-specific guidance
class DeviceInfoHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static String? _cachedManufacturer;
  static String? _cachedModel;
  static bool _isInitialized = false;

  /// Initialize device info (call once at app startup)
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _cachedManufacturer = androidInfo.manufacturer.toLowerCase();
        _cachedModel = androidInfo.model.toLowerCase();
      }
      _isInitialized = true;
    } catch (e) {
      // Fallback to unknown if detection fails
      _cachedManufacturer = 'unknown';
      _cachedModel = 'unknown';
      _isInitialized = true;
    }
  }

  /// Get the device manufacturer (lowercase)
  static Future<String> getManufacturer() async {
    if (!_isInitialized) await init();
    return _cachedManufacturer ?? 'unknown';
  }

  /// Get the device model (lowercase)
  static Future<String> getModel() async {
    if (!_isInitialized) await init();
    return _cachedModel ?? 'unknown';
  }

  /// Check if device is from a problematic manufacturer
  static Future<bool> isProblematicManufacturer() async {
    final manufacturer = await getManufacturer();
    return isRealmeOppo(manufacturer) ||
        isXiaomi(manufacturer) ||
        isVivo(manufacturer) ||
        isOnePlus(manufacturer);
  }

  /// Check if device is Realme or Oppo (ColorOS)
  static bool isRealmeOppo(String manufacturer) {
    return manufacturer.contains('realme') ||
        manufacturer.contains('oppo') ||
        manufacturer
            .contains('oneplus'); // OnePlus also uses ColorOS in some regions
  }

  /// Check if device is Xiaomi (MIUI)
  static bool isXiaomi(String manufacturer) {
    return manufacturer.contains('xiaomi') ||
        manufacturer.contains('redmi') ||
        manufacturer.contains('poco');
  }

  /// Check if device is Vivo (FunTouch OS)
  static bool isVivo(String manufacturer) {
    return manufacturer.contains('vivo') || manufacturer.contains('iqoo');
  }

  /// Check if device is OnePlus (OxygenOS/ColorOS)
  static bool isOnePlus(String manufacturer) {
    return manufacturer.contains('oneplus');
  }

  /// Get manufacturer-specific troubleshooting data
  static Future<ManufacturerGuide?> getManufacturerGuide() async {
    final manufacturer = await getManufacturer();

    if (isRealmeOppo(manufacturer)) {
      return ManufacturerGuide(
        name: 'Realme/Oppo (ColorOS)',
        icon: '🔴',
        description:
            'ColorOS has aggressive battery optimization that can prevent alarms from ringing on the lockscreen.',
        steps: [
          GuideStep(
            title: 'Enable Autostart',
            description: 'Settings → App Management → Autostart → Enable upNow',
            critical: true,
          ),
          GuideStep(
            title: 'Lock Screen Notifications',
            description:
                'Settings → Notifications & Status Bar → Lock Screen Notifications → Enable for upNow',
            critical: true,
          ),
          GuideStep(
            title: 'Battery Optimization',
            description:
                'Settings → Battery → More Battery Settings → Optimize Battery Use → upNow → Don\'t Optimize',
            critical: true,
          ),
          GuideStep(
            title: 'Alarm & Reminders Permission',
            description:
                'Settings → Apps → Special App Access → Alarm & Reminders → Enable upNow',
            critical: true,
          ),
          GuideStep(
            title: 'Background Apps',
            description:
                'Settings → Battery → App Battery Management → upNow → No Restrictions',
            critical: false,
          ),
        ],
      );
    } else if (isXiaomi(manufacturer)) {
      return ManufacturerGuide(
        name: 'Xiaomi (MIUI)',
        icon: '🟠',
        description:
            'MIUI has strict background restrictions that can prevent alarms from working properly.',
        steps: [
          GuideStep(
            title: 'Enable Autostart',
            description:
                'Settings → Apps → Manage Apps → upNow → Autostart → Enable',
            critical: true,
          ),
          GuideStep(
            title: 'Battery Saver',
            description:
                'Settings → Battery & Performance → Choose Apps → upNow → No Restrictions',
            critical: true,
          ),
          GuideStep(
            title: 'MIUI Optimization',
            description:
                'Settings → Additional Settings → Developer Options → MIUI Optimization → Disable',
            critical: false,
          ),
          GuideStep(
            title: 'Lock Screen Notifications',
            description:
                'Settings → Notifications → Lock Screen Notifications → Show all notifications',
            critical: true,
          ),
        ],
      );
    } else if (isVivo(manufacturer)) {
      return ManufacturerGuide(
        name: 'Vivo (FunTouch OS)',
        icon: '🔵',
        description:
            'FunTouch OS restricts background apps aggressively to save battery.',
        steps: [
          GuideStep(
            title: 'Background Apps',
            description:
                'Settings → Battery → Background Apps Management → upNow → Allow',
            critical: true,
          ),
          GuideStep(
            title: 'High Background Power Consumption',
            description:
                'Settings → Battery → High Background Power Consumption → upNow → Allow',
            critical: true,
          ),
          GuideStep(
            title: 'Autostart',
            description:
                'Settings → More Settings → Applications → Autostart → Enable upNow',
            critical: true,
          ),
        ],
      );
    } else if (isOnePlus(manufacturer)) {
      return ManufacturerGuide(
        name: 'OnePlus (OxygenOS)',
        icon: '🟢',
        description:
            'OnePlus devices may restrict background processes and battery usage.',
        steps: [
          GuideStep(
            title: 'Battery Optimization',
            description:
                'Settings → Battery → Battery Optimization → upNow → Don\'t Optimize',
            critical: true,
          ),
          GuideStep(
            title: 'Adaptive Battery',
            description:
                'Settings → Battery → Adaptive Battery → Disable or whitelist upNow',
            critical: false,
          ),
          GuideStep(
            title: 'App Auto-Launch',
            description:
                'Settings → Apps → Special Access → App Auto-Launch → Enable upNow',
            critical: true,
          ),
        ],
      );
    }

    return null; // No specific guide for this manufacturer
  }
}

/// Manufacturer-specific troubleshooting guide
class ManufacturerGuide {
  final String name;
  final String icon;
  final String description;
  final List<GuideStep> steps;

  const ManufacturerGuide({
    required this.name,
    required this.icon,
    required this.description,
    required this.steps,
  });
}

/// Individual step in the troubleshooting guide
class GuideStep {
  final String title;
  final String description;
  final bool critical; // Whether this step is critical for alarm functionality

  const GuideStep({
    required this.title,
    required this.description,
    this.critical = false,
  });
}
