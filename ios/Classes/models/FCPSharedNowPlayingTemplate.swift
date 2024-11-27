//
//  FCPSharedNowPlaying.swift
//  flutter_carplay
//
//  Created by Koen Van Looveren on 16/09/2022.
//

import CarPlay

@available(iOS 14.0, *)
class FCPSharedNowPlayingTemplate {

    private var isFavorited: Bool
    private var isShuffle: Bool

    init(obj: [String : Any]) {
        self.isFavorited = obj["isFavorited"] as? Bool ?? false
        self.isShuffle = obj["isShuffle"] as? Bool ?? false
    }


    var get: CPNowPlayingTemplate {
        let shared = CPNowPlayingTemplate.shared
        shared.isUpNextButtonEnabled = true
        shared.upNextTitle = "播放队列"
        FCPSharedNowPlayingTemplate.updateNowPlayingButtons(isFavorited: self.isFavorited, isShuffle: self.isShuffle)
        return shared
    }


    static func updateNowPlayingButtons(isFavorited: Bool, isShuffle: Bool) {
        let shared = CPNowPlayingTemplate.shared
        var carTraitCollection: UITraitCollection?
        
        for screen in UIScreen.screens {
            if screen.traitCollection.userInterfaceIdiom == .carPlay {
                carTraitCollection = screen.traitCollection
            }
          }
        
        
        let favoriteSystemName = isFavorited ? "heart.fill" : "heart"
        let favoriteButton = CPNowPlayingImageButton(image: UIImage(systemName: favoriteSystemName, compatibleWith: carTraitCollection)!, handler: { _ in
            DispatchQueue.main.async {
                FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onNowPlayingButtonPressed,
                                                 data: ["action": "favorite"])
            }
        })

        let shuffleSystemName = isShuffle ? "shuffle" : "repeat"
        let shuffleButton = CPNowPlayingImageButton(image: UIImage(systemName: shuffleSystemName, compatibleWith: carTraitCollection)!,handler: { _ in
            DispatchQueue.main.async {
                FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onNowPlayingButtonPressed,
                                                 data: ["action": "shuffle"])
            }
        })

        let journalButton = CPNowPlayingImageButton(image: UIImage(systemName: "ellipsis.circle", compatibleWith: carTraitCollection)!,handler: { _ in
            DispatchQueue.main.async {
                FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onNowPlayingButtonPressed,
                                                 data: ["action": "more"])
            }
        })
        
       
        let artistButton = CPNowPlayingImageButton(image: UIImage(systemName: "music.note.list", compatibleWith: carTraitCollection)!,handler: { _ in
            DispatchQueue.main.async {
                FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onNowPlayingButtonPressed,
                                                 data: ["action": "artist"])
            }
        })

        shared.updateNowPlayingButtons([favoriteButton, shuffleButton, artistButton, journalButton])
    }
}

@available(iOS 14.0, *)
extension FCPSharedNowPlayingTemplate: FCPRootTemplate {}
