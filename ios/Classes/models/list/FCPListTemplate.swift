//
//  FCPListTemplate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPListTemplate {
    private(set) var _super: CPListTemplate?
    private(set) var elementId: String
    private var title: String?
    private var systemIcon: String
    private var sections: [CPListSection] = []
    private var objcSections: [FCPListSection] = []
    private var emptyViewTitleVariants: [String] = []
    private var emptyViewSubtitleVariants: [String] = []
    private var showsTabBadge: Bool = false
    private var templateType: FCPListTemplateTypes
    private var objcBackButton: FCPBarButton?
    private var backButton: CPBarButton?
    private var showSiri: Bool = false
  
    init(obj: [String: Any], templateType: FCPListTemplateTypes) {
        self.elementId = obj["_elementId"] as! String
        self.title = obj["title"] as? String
        self.systemIcon = obj["systemIcon"] as! String
        self.emptyViewTitleVariants = obj["emptyViewTitleVariants"] as? [String] ?? []
        self.emptyViewSubtitleVariants = obj["emptyViewSubtitleVariants"] as? [String] ?? []
        self.showsTabBadge = obj["showsTabBadge"] as! Bool
        self.showSiri = obj["showSiri"] as? Bool ?? false
        self.templateType = templateType
        self.objcSections = (obj["sections"] as! [[String: Any]]).map {
            FCPListSection(obj: $0)
        }
        self.sections = objcSections.map {
            $0.get
        }
        let backButtonData = obj["backButton"] as? [String: Any]
        if backButtonData != nil {
            self.objcBackButton = FCPBarButton(obj: backButtonData!)
            self.backButton = objcBackButton?.get
        }
    }
  
    var get: CPListTemplate {
        
        var listTemplate: CPListTemplate
        
        if #available(iOS 15.0, *), showSiri {
            let configuration = CPAssistantCellConfiguration(
                                    position: .top,
                                    visibility: .always,
                                    assistantAction: .playMedia)
            listTemplate = CPListTemplate(title: title, sections: sections, assistantCellConfiguration: configuration)
                                
            } else {
                listTemplate = CPListTemplate(title: title, sections: sections)
                                
            }
        
        listTemplate.emptyViewTitleVariants = emptyViewTitleVariants
        listTemplate.emptyViewSubtitleVariants = emptyViewSubtitleVariants
        listTemplate.showsTabBadge = showsTabBadge
        listTemplate.tabImage = UIImage().fromCorrectSource(name: systemIcon)
        if templateType == FCPListTemplateTypes.DEFAULT {
            listTemplate.backButton = backButton
        }
        _super = listTemplate
        return listTemplate
    }
  
    public func getSections() -> [FCPListSection] {
        return objcSections
    }
    
    public func update(sections: [FCPListSection]?, emptyViewTitleVariants: [String]?, emptyViewSubtitleVariants: [String]?) {
        if let _sections = sections {
            objcSections = _sections
            self.sections = _sections.map {
                $0.get
            }
            _super?.updateSections(self.sections)
        }
        
        if let _emptyViewTitleVariants = emptyViewTitleVariants {
            self.emptyViewTitleVariants = _emptyViewTitleVariants
            _super?.emptyViewTitleVariants = _emptyViewTitleVariants
        }
        
        if let _emptyViewSubtitleVariants = emptyViewSubtitleVariants {
            self.emptyViewSubtitleVariants = _emptyViewSubtitleVariants
            _super?.emptyViewSubtitleVariants = _emptyViewSubtitleVariants
        }
    }
}

@available(iOS 14.0, *)
extension FCPListTemplate: FCPRootTemplate {}
