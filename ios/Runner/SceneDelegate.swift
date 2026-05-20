import Flutter
import UIKit
import FirebaseAuth

class SceneDelegate: FlutterSceneDelegate {

  // ── Firebase Phone Auth: reCAPTCHA URL via scene-based routing ─────────────
  // In scene-based apps `UIApplication.shared.keyWindow` is nil, so Firebase
  // would crash trying to present reCAPTCHA. We intercept the URL here instead.
  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    for context in URLContexts {
      if Auth.auth().canHandle(context.url) {
        return
      }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
