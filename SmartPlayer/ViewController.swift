//
//  ViewController.swift
//  SmartPlayer
//
//  Created by Mahsa Haratiannejad on 04.05.17.
//  Copyright © 2017 mahsajjad. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox


class ViewController: UIViewController {
    
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var modeStackView: UIStackView!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var loopButton: UIButton!
    
    
    var audioManager = AudioManager.init()
    var loopIsEnabled = false
    var playerIsStarted = false
   

    override func viewDidLoad() {
        super.viewDidLoad()
        audioManager.delegate = self
        modeStackView.isHidden = true
        songNameLabel.text = audioManager.firstTitle
    }
    
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    @IBAction func sliderDidPress(_ sender: UISlider) {    
        audioManager.avPlayer?.currentTime = TimeInterval(sender.value)
    }

    @IBAction func loopButtonDidPress(_ sender: UIButton) {
        loopIsEnabled = !loopIsEnabled
        sender.setImage(UIImage(named: loopIsEnabled ? "PressedLoop.png" : "Loop.png"), for: .normal)
        audioManager.loop(loopIsEnabled: loopIsEnabled)
    }
    
    @IBAction func previousButtonDidPress(_ sender: Any) {        
        audioManager.playNewTrack(next: false)
        playButton.setImage( UIImage(named: "Pause.png"), for: .normal)
        playerIsStarted = true
        loopIsEnabled = false
        loopButton.setImage(UIImage(named: "Loop.png"), for: .normal)
    }
    
    @IBAction func playButtonDidPress(_ sender: Any) {
        playerIsStarted = !playerIsStarted
        playButton.setImage( UIImage(named: playerIsStarted ? "Pause.png" : "Play.png"), for: .normal)
        playerIsStarted ? audioManager.start() : audioManager.stop()
        if let duration = audioManager.avPlayer?.duration {
            setupSlider(maxValue: Float(duration))
        }
    }
    
    @IBAction func nextButtonDidPress(_ sender: Any) {
        audioManager.playNewTrack(next: true)
        playButton.setImage( UIImage(named: "Pause.png"), for: .normal)
        playerIsStarted = true
        loopIsEnabled = false
        loopButton.setImage(UIImage(named: "Loop.png"), for: .normal)
    }
    
    @IBAction func handModeButtonDidPress(_ sender: Any) {
        
        
    }
    
    @IBAction func pocketModeDidPress(_ sender: Any) {
        
        
    }
    
    @IBAction func sportModeDidPress(_ sender: Any) {
        
        
    }

    func setupSlider(maxValue: Float){
        slider.minimumValue = 0.0
        slider.maximumValue = maxValue
    }
    
}

extension ViewController: AvPlayerDelegate {
   
    func avPlayerSongDidChanged(_ player: AVAudioPlayer) {
        setupSlider(maxValue: Float(player.duration))
    }
    
    func avPlayer(_ player: AVAudioPlayer, updateSliderWith value: Float) {
        slider.setValue(value, animated: false)
    }
    
    func avPlayer(_ player: AVAudioPlayer, updateSongTitleWith value: String) {
        songNameLabel.text = value
    }
   
}


