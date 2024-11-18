//
//  FCPListItem.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay
import Kingfisher

@available(iOS 14.0, *)
class FCPListItem {
    private(set) var _super: CPSelectableListItem?
    private(set) var elementId: String
    private var text: String
    private var detailText: String?
    private var isOnPressListenerActive: Bool = false
    private var completeHandler: (() -> Void)?
    private var image: String?
    private var playbackProgress: CGFloat?
    private var isPlaying: Bool?
    private var playingIndicatorLocation: CPListItemPlayingIndicatorLocation?
    private var accessoryType: CPListItemAccessoryType?
    private var images: [String]?
    private var titles: [String]?

    init(obj: [String: Any]) {
        self.elementId = obj["_elementId"] as! String
        self.text = obj["text"] as! String
        self.detailText = obj["detailText"] as? String
        self.isOnPressListenerActive = obj["onPress"] as? Bool ?? false
        self.image = obj["image"] as? String
        self.playbackProgress = obj["playbackProgress"] as? CGFloat
        self.isPlaying = obj["isPlaying"] as? Bool
        self.setPlayingIndicatorLocation(fromString: obj["playingIndicatorLocation"] as? String)
        self.setAccessoryType(fromString: obj["accessoryType"] as? String)
        self.images = obj["images"] as? [String]
        self.titles = obj["titles"] as? [String]
    }

    var getImageRowItem: CPListTemplateItem {
        
        let uiImages = images?.compactMap {
            UIImage().fromCorrectSource(name: $0)
        }

        var listItem: CPListImageRowItem
        if let titles = titles, #available(iOS 17.4, *) {
            listItem = CPListImageRowItem(text: text, images: uiImages!, imageTitles: titles)
        } else {
            listItem = CPListImageRowItem(text: text, images: uiImages!)
        }

        listItem.listImageRowHandler = {[weak self] _, index, complete in
            guard let self = self else { return }
            
            if self.isOnPressListenerActive == true {
                DispatchQueue.main.async {
                    self.completeHandler = complete
                    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onListImageRowItemSelected,
                                                     data: ["elementId": self.elementId, "index": index])
                }
            } else {
                complete()
            }
        }

        listItem.handler = { [weak self] _, complete in
            guard let self = self else { return }
            
            if self.isOnPressListenerActive == true {
                DispatchQueue.main.async {
                    self.completeHandler = complete
                    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onListItemSelected,
                                                     data: ["elementId": self.elementId])
                }
            } else {
                complete()
            }
        }

        self._super = listItem
        return listItem
    }

    var get: CPListTemplateItem {
        if let _ = images {
            return getImageRowItem
        }

        let listItem = CPListItem(text: text, detailText: detailText)
        listItem.handler = { [weak self] _, complete in
            guard let self = self else { return }

            if self.isOnPressListenerActive == true {
                DispatchQueue.main.async {
                    self.completeHandler = complete
                    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onListItemSelected,
                                                     data: ["elementId": self.elementId])
                }
            } else {
                complete()
            }
        }

        if let image = image {
            UIGraphicsBeginImageContext(CGSize(width: 100, height: 100))
            let emptyImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            listItem.setImage(emptyImage)

            if image.starts(with: "http") {
                KingfisherManager.shared.retrieveImage(with: KF.ImageResource(downloadURL: URL(string: image)!), options: nil, progressBlock: nil, completionHandler: { result in
                    switch result {
                        case .success(let value):
                            listItem.setImage(value.image)
                        case .failure:
                            listItem.setImage(UIImage(systemName: "questionmark")!)
                    }
                })
            } else {
                DispatchQueue.global(qos: .background).async {
                    let uiImage = UIImage().fromCorrectSource(name: image)
                    DispatchQueue.main.async {
                        listItem.setImage(uiImage)
                    }
                }
            }
        }

        if let playbackProgress = playbackProgress {
            listItem.playbackProgress = playbackProgress
        }

        if let isPlaying = isPlaying {
            listItem.isPlaying = isPlaying
        }

        if let playingIndicatorLocation = playingIndicatorLocation {
            listItem.playingIndicatorLocation = playingIndicatorLocation
        }

        if let accessoryType = accessoryType {
            listItem.accessoryType = accessoryType
        }

        self._super = listItem
        return listItem
    }

    public func stopHandler() {
        guard self.completeHandler != nil else {
            return
        }
        self.completeHandler!()
        self.completeHandler = nil
    }

    public func update(text: String?, detailText: String?, image: String?, playbackProgress: CGFloat?, isPlaying: Bool?, playingIndicatorLocation: String?, accessoryType: String?) {
        guard let item = self._super as? CPListItem else {
            return
        }

        if let text = text {
            item.setText(text)
            self.text = text
        }

        if let detailText = detailText {
            item.setDetailText(detailText)
            self.detailText = detailText
        }

        if let image = image {
            DispatchQueue.global(qos: .background).async {
                let uiImage = UIImage().fromCorrectSource(name: image)
                DispatchQueue.main.async {
                    item.setImage(uiImage)
                }
            }
            self.image = image
        }

        if let playbackProgress = playbackProgress {
            item.playbackProgress = playbackProgress
            self.playbackProgress = playbackProgress
        }

        if let isPlaying = isPlaying {
            item.isPlaying = isPlaying
            self.isPlaying = isPlaying
        }

        if let playingIndicatorLocation = playingIndicatorLocation {
            self.setPlayingIndicatorLocation(fromString: playingIndicatorLocation)
            if let location = self.playingIndicatorLocation {
                item.playingIndicatorLocation = location
            }
        }

        if let accessoryType = accessoryType {
            self.setAccessoryType(fromString: accessoryType)
            if let type = self.accessoryType {
                item.accessoryType = type
            }
        }
    }

    private func setPlayingIndicatorLocation(fromString: String?) {
        if fromString == "leading" {
            self.playingIndicatorLocation = CPListItemPlayingIndicatorLocation.leading
        } else if fromString == "trailing" {
            self.playingIndicatorLocation = CPListItemPlayingIndicatorLocation.trailing
        }
    }

    private func setAccessoryType(fromString: String?) {
        if fromString == "cloud" {
            self.accessoryType = CPListItemAccessoryType.cloud
        } else if fromString == "disclosureIndicator" {
            self.accessoryType = CPListItemAccessoryType.disclosureIndicator
        } else {
            self.accessoryType = CPListItemAccessoryType.none
        }
    }
}
