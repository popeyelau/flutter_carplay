//
//  FlutterCarPlayPluginsSceneDelegate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FlutterCarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
  static private var interfaceController: CPInterfaceController?
  
  static public func forceUpdateRootTemplate() {
    let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate
    let animated = SwiftFlutterCarplayPlugin.animated
      
    self.interfaceController?.setRootTemplate(rootTemplate!, animated: animated, completion: nil)
  }
  
  // Fired when just before the carplay become active
  func sceneDidBecomeActive(_ scene: UIScene) {
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
  }
  
  // Fired when carplay entered background
  func sceneDidEnterBackground(_ scene: UIScene) {
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.background)
  }
  
  static public func pop(animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
      self.interfaceController?.popTemplate(animated: animated, completion: completion)
  }
  
  static public func popToRootTemplate(animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
      self.interfaceController?.popToRootTemplate(animated: animated, completion: completion)
  }
  
  static public func push(template: CPTemplate, animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
    self.interfaceController?.pushTemplate(template, animated: animated, completion: completion)
  }
  
  static public func closePresent(animated: Bool, completion: ((Bool, Error?) -> Void)? = nil) {
    self.interfaceController?.dismissTemplate(animated: animated, completion: completion)
  }
  
  static public func presentTemplate(template: CPTemplate, animated: Bool,
                                     completion: ((Bool, Error?) -> Void)? = nil) {
      
     self.interfaceController?.presentTemplate(template, animated: animated, completion: completion)

  }
  
  func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didConnect interfaceController: CPInterfaceController) {
    FlutterCarPlaySceneDelegate.interfaceController = interfaceController
    interfaceController.delegate = self
    
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
    let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate

    if rootTemplate != nil {
      FlutterCarPlaySceneDelegate.interfaceController?.setRootTemplate(rootTemplate!, animated: SwiftFlutterCarplayPlugin.animated, completion: nil)
    } else {
      //FIXME:
      let ooops = CPListTemplate(title: "雀乐", sections: [])
      ooops.emptyViewTitleVariants = ["正在加载中..."]
      FlutterCarPlaySceneDelegate.interfaceController?.setRootTemplate(ooops, animated: SwiftFlutterCarplayPlugin.animated, completion: nil)
    }
  }
  
  func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)
    
    //FlutterCarPlaySceneDelegate.interfaceController = nil
  }
  
  func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didDisconnectInterfaceController interfaceController: CPInterfaceController) {
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)
    
    //FlutterCarPlaySceneDelegate.interfaceController = nil
  }
}

extension FlutterCarPlaySceneDelegate: CPInterfaceControllerDelegate {
    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) {
        if let temeplate = aTemplate as? CPListTemplate {
            FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onNowPlayingButtonPressed,
                                             data: ["action": temeplate.title ?? ""])
        }
    }
}


