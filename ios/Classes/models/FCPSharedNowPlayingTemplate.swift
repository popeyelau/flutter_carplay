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
        updateNowPlayingButtons()
        return shared
    }
    
    
    func updateNowPlayingButtons() {
        let shared = CPNowPlayingTemplate.shared
        let favoriteSystemName = isFavorited ? "heart.fill" : "heart"
        let favoriteButton = CPNowPlayingImageButton(image: UIImage(systemName: favoriteSystemName)!, handler: {[weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
               
                FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onNowPlayingButtonPressed,
                                                 data: ["action": "favorite"])
                self.isFavorited = !self.isFavorited
                self.updateNowPlayingButtons()
            }
        })

        let shuffleSystemName = isShuffle ? "shuffle" : "repeat"
        let shuffleButton = CPNowPlayingImageButton(image: UIImage(systemName: shuffleSystemName)!,handler: { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onNowPlayingButtonPressed,
                                                 data: ["action": "shuffle"])
                self.isShuffle = !self.isShuffle
                self.updateNowPlayingButtons()
            }
        })
        
        shared.updateNowPlayingButtons([favoriteButton, shuffleButton])
    }
}

@available(iOS 14.0, *)
extension FCPSharedNowPlayingTemplate: FCPRootTemplate {}
