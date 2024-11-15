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

  init(obj: [String : Any]) {
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
          return  UIImage().fromCorrectSource(name: $0)
      }
      
      var listItem: CPListImageRowItem
      if let titles = titles, #available(iOS 17.4, *) {
          listItem = CPListImageRowItem(text: text, images: uiImages!, imageTitles: titles)
      } else {
          listItem = CPListImageRowItem(text: text, images: uiImages!)
      }
      
      listItem.listImageRowHandler = ((CPListImageRowItem, Int, @escaping () -> Void) -> Void)? { item, index, complete in
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

      listItem.handler = ((CPSelectableListItem, @escaping () -> Void) -> Void)? { selectedItem, complete in
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


    let listItem = CPListItem.init(text: text, detailText: detailText)
    listItem.handler = ((CPSelectableListItem, @escaping () -> Void) -> Void)? { selectedItem, complete in
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
    
    if playbackProgress != nil {
      listItem.playbackProgress = playbackProgress!
    }
    if isPlaying != nil {
      listItem.isPlaying = isPlaying!
    }
    if playingIndicatorLocation != nil {
      listItem.playingIndicatorLocation = playingIndicatorLocation!
    }
    if accessoryType != nil {
      listItem.accessoryType = accessoryType!
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
    if text != nil {
        if _super is CPListItem {
            (self._super as? CPListItem)?.setText(text!)
        }
      self.text = text!
    }
    if detailText != nil {

        if _super is CPListItem {
            (self._super as? CPListItem)?.setDetailText(detailText)
        }


      self.detailText = detailText
    }
    if image != nil {
      DispatchQueue.global(qos: .background).async {
        let uiImage = UIImage().fromCorrectSource(name: image!)
        DispatchQueue.main.async {

            if self._super is CPListItem {
                (self._super as? CPListItem)?.setImage(uiImage)
            }

        }
      }

      self.image = image
    }
    if playbackProgress != nil {
        if _super is CPListItem {
            (self._super as? CPListItem)?.playbackProgress = playbackProgress!
        }

      self.playbackProgress = playbackProgress
    }
    if isPlaying != nil {
        if _super is CPListItem {
            (self._super as? CPListItem)?.isPlaying = isPlaying!
        }


      self.isPlaying = isPlaying
    }
    if playingIndicatorLocation != nil {
      self.setPlayingIndicatorLocation(fromString: playingIndicatorLocation)
      if self.playingIndicatorLocation != nil {

          if _super is CPListItem {
              (self._super as? CPListItem)?.playingIndicatorLocation = self.playingIndicatorLocation!
          }

      }
    }
    if accessoryType != nil {
      self.setAccessoryType(fromString: accessoryType)
      if self.accessoryType != nil {
          if _super is CPListItem {
              (self._super as? CPListItem)?.accessoryType = self.accessoryType!
          }
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

