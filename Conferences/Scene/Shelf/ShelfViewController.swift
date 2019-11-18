//
//  ShelfViewController.swift
//  Conferences
//
//  Created by Timon Blask on 12/02/19.
//  Copyright © 2019 Timon Blask. All rights reserved.
//

import Cocoa
import Kingfisher

protocol ShelfViewControllerDelegate: class {
    func shelfViewControllerDidSelectPlay(_ controller: ShelfViewController, talk: TalkModel)
}

class ShelfViewController: NSViewController {
    private var talk: TalkModel?
    private var imageDownloadOperation: DownloadTask?

    var playerController: Playable? {
        didSet {
            guard let playerController = playerController else { return }

            oldValue?.view.removeFromSuperview()
            oldValue?.removeFromParent()

            NSAnimationContext.runAnimationGroup({ _ in
                playerContainer.animator().isHidden = false
                playerContainer.animator().alphaValue = 1
            }, completionHandler: nil)

            playerContainer.addSubview(playerController.view)
            playerController.view.edgesToSuperview()

            addChild(playerController)

            playerController.play()
        }
    }

    weak var delegate: ShelfViewControllerDelegate?

    private lazy var previewImage = AspectFillImageView()
    private lazy var playerContainer = NSView()

    private lazy var playButton: VibrantButton = {
        let b = VibrantButton(frame: .zero)

        b.title = "Play"
        b.target = self
        b.action = #selector(play)

        return b
    }()

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = .black
        
        view.addSubview(previewImage)
        view.addSubview(playButton)
        view.addSubview(playerContainer)

        playButton.center(in: view)
        previewImage.edgesToSuperview(insets: .init(top: 20, left: 20, bottom: 20, right: 20))
        playerContainer.edgesToSuperview()

        view.height(min: 300, max: nil, priority: .defaultHigh, isActive: true)
    }

    func configureView(with talk: TalkModel) {
        self.talk = talk
        playButton.state = .off

        NSAnimationContext.runAnimationGroup({ _ in
            playerContainer.animator().alphaValue = 0
        }, completionHandler: {
            self.playerContainer.isHidden = true
        })

        previewImage.image = NSImage(named: "placeholder")
        imageDownloadOperation?.cancel()

        guard let imageUrl = URL(string: talk.previewImage) else { return }

        imageDownloadOperation = KingfisherManager.shared.retrieveImage(with: imageUrl) { result in
            if let image = try? result.get() {
                self.previewImage.image = image.image
            } else {
                self.previewImage.image = NSImage(named: "placeholder")
            }
        }
    }

    @objc private func play(_ sender: Any?) {
        guard let talk = talk else { return }
        playerContainer.subviews.forEach {$0.removeFromSuperview() }
        self.delegate?.shelfViewControllerDidSelectPlay(self, talk: talk)
    }
}
