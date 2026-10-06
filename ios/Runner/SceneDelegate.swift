import Flutter
import UIKit

/// Flutter 3.38+ and receive_sharing_intent 1.9 use the UIScene lifecycle.
/// Keeping this delegate intentionally small lets Flutter/plugin lifecycle
/// delegates process ShareMedia URLs while preserving normal scene behavior.
class SceneDelegate: FlutterSceneDelegate {}
