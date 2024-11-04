//
//  SwiftFlutterCarplayPlugin.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay
import Flutter
import Intents

@available(iOS 14.0, *)
public class SwiftFlutterCarplayPlugin: NSObject, FlutterPlugin {
    private static var streamHandler: FCPStreamHandlerPlugin?
    private(set) static var registrar: FlutterPluginRegistrar?
    private static var objcRootTemplate: FCPRootTemplate?
    private static var templateStack: [FCPRootTemplate] = []
    private static var _rootTemplate: CPTemplate?
    public static var animated: Bool = false
    private var objcPresentTemplate: FCPPresentTemplate?

    public static var rootTemplate: CPTemplate? {
        get {
            return _rootTemplate
        }
        set(tabBarTemplate) {
            _rootTemplate = tabBarTemplate
        }
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: makeFCPChannelId(event: ""),
                                           binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterCarplayPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        self.registrar = registrar

        self.streamHandler = FCPStreamHandlerPlugin(registrar: registrar)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case FCPChannelTypes.setRootTemplate:
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }

            SwiftFlutterCarplayPlugin.templateStack = []
            var rootTemplate: FCPRootTemplate?
            switch args["runtimeType"] as! String {
            case String(describing: FCPTabBarTemplate.self):
                rootTemplate = FCPTabBarTemplate(obj: args["rootTemplate"] as! [String: Any])
                if (rootTemplate as! FCPTabBarTemplate).getTemplates().count > 5 {
                    result(FlutterError(code: "ERROR",
                                        message: "CarPlay cannot have more than 5 templates on one screen.",
                                        details: nil))
                    return
                }
                SwiftFlutterCarplayPlugin.rootTemplate = (rootTemplate as! FCPTabBarTemplate).get
            case String(describing: FCPGridTemplate.self):
                rootTemplate = FCPGridTemplate(obj: args["rootTemplate"] as! [String: Any])
                SwiftFlutterCarplayPlugin.rootTemplate = (rootTemplate as! FCPGridTemplate).get
            case String(describing: FCPInformationTemplate.self):
                rootTemplate = FCPInformationTemplate(obj: args["rootTemplate"] as! [String: Any])
                SwiftFlutterCarplayPlugin.rootTemplate = (rootTemplate as! FCPInformationTemplate).get
            case String(describing: FCPPointOfInterestTemplate.self):
                rootTemplate = FCPPointOfInterestTemplate(obj: args["rootTemplate"] as! [String: Any])
                SwiftFlutterCarplayPlugin.rootTemplate = (rootTemplate as! FCPPointOfInterestTemplate).get
            case String(describing: FCPListTemplate.self):
                rootTemplate = FCPListTemplate(obj: args["rootTemplate"] as! [String: Any], templateType: FCPListTemplateTypes.DEFAULT)
                SwiftFlutterCarplayPlugin.rootTemplate = (rootTemplate as! FCPListTemplate).get
            default:
                result(false)
                return
            }
            SwiftFlutterCarplayPlugin.objcRootTemplate = rootTemplate
            let animated = args["animated"] as! Bool
            SwiftFlutterCarplayPlugin.animated = animated
            result(true)
        case FCPChannelTypes.forceUpdateRootTemplate:
            FlutterCarPlaySceneDelegate.forceUpdateRootTemplate()
            result(true)
        case FCPChannelTypes.updateListItem:
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            let elementId = args["_elementId"] as! String
            let text = args["text"] as? String
            let detailText = args["detailText"] as? String
            let image = args["image"] as? String
            let playbackProgress = args["playbackProgress"] as? CGFloat
            let isPlaying = args["isPlaying"] as? Bool
            let playingIndicatorLocation = args["playingIndicatorLocation"] as? String
            let accessoryType = args["accessoryType"] as? String
            SwiftFlutterCarplayPlugin.findItem(elementId: elementId, actionWhenFound: { item in
                item.update(text: text, detailText: detailText, image: image, playbackProgress: playbackProgress, isPlaying: isPlaying, playingIndicatorLocation: playingIndicatorLocation, accessoryType: accessoryType)
            })
            result(true)

        case FCPChannelTypes.updateListTemplate:
            guard let args = call.arguments as? [String: Any],
                  let elementId = args["_elementId"] as? String,
                  let sections = args["sections"] as? [[String: Any]]
            else {
                result(false)
                return
            }

            self.updateListTemplate(elementId: elementId, sections: sections, args: args)
            result(true)

        case FCPChannelTypes.onListItemSelectedComplete:
            guard let args = call.arguments as? String else {
                result(false)
                return
            }
            SwiftFlutterCarplayPlugin.findItem(elementId: args, actionWhenFound: { item in
                item.stopHandler()
            })
            result(true)
        case FCPChannelTypes.setAlert:
            guard self.objcPresentTemplate == nil else {
                result(FlutterError(code: "ERROR",
                                    message: "CarPlay can only present one modal template at a time.",
                                    details: nil))
                return
            }
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            let alertTemplate = FCPAlertTemplate(obj: args["rootTemplate"] as! [String: Any])
            self.objcPresentTemplate = alertTemplate
            let animated = args["animated"] as! Bool
            FlutterCarPlaySceneDelegate
                .presentTemplate(template: alertTemplate.get, animated: animated, completion: { completed, _ in
                    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onPresentStateChanged,
                                                     data: ["completed": completed])
                })
            result(true)
        case FCPChannelTypes.setActionSheet:
            guard self.objcPresentTemplate == nil else {
                result(FlutterError(code: "ERROR",
                                    message: "CarPlay can only present one modal template at a time.",
                                    details: nil))
                return
            }
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            let actionSheetTemplate = FCPActionSheetTemplate(obj: args["rootTemplate"] as! [String: Any])
            self.objcPresentTemplate = actionSheetTemplate
            let animated = args["animated"] as! Bool
            FlutterCarPlaySceneDelegate.presentTemplate(template: actionSheetTemplate.get, animated: animated, completion: { _, _ in })
            result(true)
        case FCPChannelTypes.popTemplate:
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            for _ in 1 ... (args["count"] as! Int) {
                SwiftFlutterCarplayPlugin.templateStack.removeLast()
                FlutterCarPlaySceneDelegate.pop(animated: args["animated"] as! Bool)
            }
            result(true)
        case FCPChannelTypes.closePresent:
            guard let animated = call.arguments as? Bool else {
                result(false)
                return
            }
            FlutterCarPlaySceneDelegate.closePresent(animated: animated)
            self.objcPresentTemplate = nil
            result(true)
        case FCPChannelTypes.showNowPlaying:
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }

            let animated = args["animated"] as? Bool ?? false
            let template = FCPSharedNowPlayingTemplate(obj: args)
            SwiftFlutterCarplayPlugin.templateStack.append(template)
            FlutterCarPlaySceneDelegate.push(template: template.get, animated: animated)
            result(true)

        case FCPChannelTypes.updateNowPlaying:
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }

            let isFavorited = args["isFavorited"] as? Bool ?? false
            let isShuffle = args["isShuffle"] as? Bool ?? false
            FCPSharedNowPlayingTemplate.updateNowPlayingButtons(isFavorited: isFavorited, isShuffle: isShuffle)

            result(true)

        case FCPChannelTypes.pushTemplate:
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            var pushTemplate: CPTemplate?
            let animated = args["animated"] as! Bool
            switch args["runtimeType"] as! String {
            case String(describing: FCPGridTemplate.self):
                let template = FCPGridTemplate(obj: args["template"] as! [String: Any])
                SwiftFlutterCarplayPlugin.templateStack.append(template)
                pushTemplate = template.get
            case String(describing: FCPPointOfInterestTemplate.self):
                let template = FCPPointOfInterestTemplate(obj: args["template"] as! [String: Any])
                SwiftFlutterCarplayPlugin.templateStack.append(template)
                pushTemplate = template.get
            case String(describing: FCPInformationTemplate.self):
                let template = FCPInformationTemplate(obj: args["template"] as! [String: Any])
                SwiftFlutterCarplayPlugin.templateStack.append(template)
                pushTemplate = template.get

            case String(describing: FCPListTemplate.self):
                let template = FCPListTemplate(obj: args["template"] as! [String: Any], templateType: FCPListTemplateTypes.DEFAULT)
                SwiftFlutterCarplayPlugin.templateStack.append(template)
                pushTemplate = template.get
            default:
                result(false)
                return
            }
            FlutterCarPlaySceneDelegate.push(template: pushTemplate!, animated: animated)
            result(true)
        case FCPChannelTypes.popToRootTemplate:
            guard let animated = call.arguments as? Bool else {
                result(false)
                return
            }
            SwiftFlutterCarplayPlugin.templateStack = []
            FlutterCarPlaySceneDelegate.popToRootTemplate(animated: animated)
            self.objcPresentTemplate = nil
            result(true)



        case FCPChannelTypes.setVoiceControl:
            guard let args = call.arguments as? [String: Any],
                              let animated = args["animated"] as? Bool,
                              let rootTemplateArgs = args["rootTemplate"] as? [String: Any]
                        else {
                            result(false)
                            return
                        }

                        if objcPresentTemplate != nil {
                            objcPresentTemplate = nil
                            FlutterCarPlaySceneDelegate.closePresent(animated: animated, completion: { _, _ in
                                showVoiceTemplate()
                            })
                        } else {
                            showVoiceTemplate()
                        }

                        func showVoiceTemplate() {
                            let voiceControlTemplate = FCPVoiceControlTemplate(obj: rootTemplateArgs)
                            objcPresentTemplate = voiceControlTemplate
                            FlutterCarPlaySceneDelegate.presentTemplate(template: voiceControlTemplate.get, animated: animated, completion: { completed, _ in
                                FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onPresentStateChanged,
                                                                 data: ["completed": completed])
                                result(completed)
                            })
                        }


        case FCPChannelTypes.activateVoiceControlState:
            guard objcPresentTemplate != nil else {
                            result(FlutterError(code: "ERROR",
                                                message: "To activate a voice control state, a voice control template must be presented to CarPlay Screen at first.",
                                                details: nil))
                            return
                        }
                        guard let args = call.arguments as? String else {
                            result(false)
                            return
                        }

                        if let voiceControlTemplate = objcPresentTemplate as? FCPVoiceControlTemplate {
                            voiceControlTemplate.activateVoiceControlState(identifier: args)
                            result(true)
                        } else {
                            result(false)
                        }
        case FCPChannelTypes.getActiveVoiceControlStateIdentifier:
                guard objcPresentTemplate != nil else {
                    result(FlutterError(code: "ERROR",
                                        message: "To get the active voice control state identifier, a voice control template must be presented to CarPlay Screen at first.",
                                        details: nil))
                    return
                }

                if let voiceControlTemplate = objcPresentTemplate as? FCPVoiceControlTemplate {
                    let identifier = voiceControlTemplate.getActiveVoiceControlStateIdentifier()
                    result(identifier)
                } else {
                    result(nil)
                }


        case FCPChannelTypes.startVoiceControl:
                   guard objcPresentTemplate != nil else {
                       result(FlutterError(code: "ERROR",
                                           message: "To start the voice control, a voice control template must be presented to CarPlay Screen at first.",
                                           details: nil))
                       return
                   }
                   if let voiceControlTemplate = objcPresentTemplate as? FCPVoiceControlTemplate {
                       voiceControlTemplate.start()
                       result(true)
                   } else {
                       result(false)
                   }
               case FCPChannelTypes.stopVoiceControl:
                   guard objcPresentTemplate != nil else {
                       result(FlutterError(code: "ERROR",
                                           message: "To stop the voice control, a voice control template must be presented to CarPlay Screen at first.",
                                           details: nil))
                       return
                   }
                   if let voiceControlTemplate = objcPresentTemplate as? FCPVoiceControlTemplate {
                       voiceControlTemplate.stop()
                       result(true)
                   } else {
                       result(false)
                   }
               case FCPChannelTypes.speak:
                   guard let args = call.arguments as? [String: Any],
                         let text = args["text"] as? String,
                         let language = args["language"] as? String,
                         let elementId = args["_elementId"] as? String,
                         let onCompleted = args["onCompleted"] as? Bool
                   else {
                       result(false)
                       return
                   }
                   _ = FCPSpeaker.shared.setLanguage(locale: Locale(identifier: language))
                   FCPSpeaker.shared.speak(text) {
                       if onCompleted {
                           FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onSpeechCompleted,
                                                            data: ["elementId": elementId])
                       }
                   }
                   result(true)
               case FCPChannelTypes.playAudio:
                   guard let args = call.arguments as? [String: Any],
                         let soundPath = args["soundPath"] as? String,
                         let volume = args["volume"] as? NSNumber
                   else {
                       result(false)
                       return
                   }
                   FCPSoundEffects.shared.prepare(sound: soundPath, volume: volume.floatValue)
                   FCPSoundEffects.shared.play()
                   result(true)



        case FCPChannelTypes.updateTabBarTemplates:
            guard let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            guard let objcRootTemplate = SwiftFlutterCarplayPlugin.objcRootTemplate as? FCPTabBarTemplate else {
                result(false)
                return
            }
            SwiftFlutterCarplayPlugin.templateStack = []
            let newTemplates = args["newTemplates"] as! [[String: Any]]
            objcRootTemplate.updateTemplates(newTemplates: newTemplates)
            result(true)
        default:
            result(false)
        }
    }

    static func createEventChannel(event: String?) -> FlutterEventChannel {
        let eventChannel = FlutterEventChannel(name: makeFCPChannelId(event: event),
                                               binaryMessenger: SwiftFlutterCarplayPlugin.registrar!.messenger())
        return eventChannel
    }

    static func onCarplayConnectionChange(status: String) {
        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onCarplayConnectionChange,
                                         data: ["status": status])
    }

    static func sendSpeechRecognitionTranscriptChangeEvent(transcript: String) {
        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onVoiceControlTranscriptChanged,
                                         data: ["transcript": transcript])
    }

    static func findItem(elementId: String, actionWhenFound: (_ item: FCPListItem) -> Void) {
        let objcRootTemplateType = String(describing: SwiftFlutterCarplayPlugin.objcRootTemplate).match(#"(.*flutter_carplay\.(.*)\))"#)[0][2]
        var templates: [FCPListTemplate] = []
        if objcRootTemplateType.elementsEqual(String(describing: FCPListTemplate.self)) {
            templates.append(SwiftFlutterCarplayPlugin.objcRootTemplate as! FCPListTemplate)
            NSLog("FCP: FCPListTemplate")
        } else if objcRootTemplateType.elementsEqual(String(describing: FCPTabBarTemplate.self)) {
            templates = (SwiftFlutterCarplayPlugin.objcRootTemplate as! FCPTabBarTemplate).getTemplates()
            NSLog("FCP: FCPTabBarTemplate")
        } else {
            NSLog("FCP: No Template")
            return
        }
        for t in self.templateStack {
            if t is FCPListTemplate {
                guard let template = t as? FCPListTemplate else {
                    break
                }
                templates.append(template)
            }
        }

        for t in templates {
            for s in t.getSections() {
                for i in s.getItems() {
                    if i.elementId == elementId {
                        actionWhenFound(i)
                        return
                    }
                }
            }
        }
    }

    static func getFCPListTemplatesFromHistory() -> [FCPListTemplate] {
        let objcRootTemplateType = String(describing: SwiftFlutterCarplayPlugin.objcRootTemplate).match(#"(.*flutter_carplay\.(.*)\))"#)[0][2]
        var templates: [FCPListTemplate] = []
        if objcRootTemplateType.elementsEqual(String(describing: FCPListTemplate.self)) {
            templates.append(SwiftFlutterCarplayPlugin.objcRootTemplate as! FCPListTemplate)
        } else if objcRootTemplateType.elementsEqual(String(describing: FCPTabBarTemplate.self)) {
            templates = (SwiftFlutterCarplayPlugin.objcRootTemplate as! FCPTabBarTemplate).getTemplates()
        }

        for t in self.templateStack {
            if t is FCPListTemplate {
                guard let template = t as? FCPListTemplate else {
                    break
                }
                templates.append(template)
            }
        }
        return templates
    }

    static func findListTemplate(elementId: String, actionWhenFound: (_ listTemplate: FCPListTemplate) -> Void) {
        // Get the array of FCPListTemplate instances.
        let templates = self.getFCPListTemplatesFromHistory()
        // Iterate through the templates to find the one with the matching element ID.
        for template in templates where template.elementId == elementId {
            // Perform the specified action when the template is found.
            actionWhenFound(template)
            break
        }
    }

    private func updateListTemplate(elementId: String, sections: [[String: Any]], args: [String: Any]) {
        // Find the list template based on the provided element ID
        SwiftFlutterCarplayPlugin.findListTemplate(elementId: elementId) { listTemplate in
            // Update the list template with the extracted data
            listTemplate.update(sections: sections.map { FCPListSection(obj: $0) },
                                emptyViewTitleVariants: args["emptyViewTitleVariants"] as? [String],
                                emptyViewSubtitleVariants: args["emptyViewSubtitleVariants"] as? [String])
        }
    }

     public static func searchViaSiri(intent: INPlayMediaIntent) {
        let mediaName = intent.mediaSearch?.mediaName ?? ""
        let albumName = intent.mediaSearch?.albumName ?? ""
        let artistName = intent.mediaSearch?.artistName ?? ""
         
        if mediaName.isEmpty && albumName.isEmpty && artistName.isEmpty {
             return
        }
         
        FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onSearchViaSiri,
                                         data: ["mediaName": mediaName, "albumName": albumName, "artistName": artistName])

    }
}
