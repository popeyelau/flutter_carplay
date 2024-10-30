//
//  FCPTabBarTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPTabBarTemplate {
  private(set) var _super: CPTabBarTemplate?
  private(set) var elementId: String
  private var title: String?
  private var templates: [CPTemplate]
  private var objcTemplates: [FCPListTemplate]
  
  init(obj: [String : Any]) {
    self.elementId = obj["_elementId"] as! String
    self.title = obj["title"] as? String
    self.objcTemplates = (obj["templates"] as! Array<[String: Any]>).map {
      FCPListTemplate(obj: $0, templateType: FCPListTemplateTypes.PART_OF_GRID_TEMPLATE)
    }
    self.templates = self.objcTemplates.map {
      $0.get
    }
  }
  
  var get: CPTabBarTemplate {
    let tabBarTemplate = CPTabBarTemplate.init(templates: templates)
    tabBarTemplate.tabTitle = title
    self._super = tabBarTemplate
    return tabBarTemplate
  }
  
  public func getTemplates() -> [FCPListTemplate] {
    return objcTemplates
  }

  public func updateTemplates(newTemplates: Array<[String : Any]>) {
    self.objcTemplates = newTemplates.map {
      FCPListTemplate(obj: $0, templateType: FCPListTemplateTypes.PART_OF_GRID_TEMPLATE)
    }
    self.templates = self.objcTemplates.map {
        $0.get
    }
    self._super?.updateTemplates(self.templates)
  }
}

@available(iOS 14.0, *)
extension FCPTabBarTemplate: FCPRootTemplate { }
