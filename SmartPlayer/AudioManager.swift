//
//  AudioManager.swift
//  SmartPlayer
//
//  Created by Mahsa Haratiannejad on 04.05.17.
//  Copyright © 2017 mahsajjad. All rights reserved.
//

import AVFoundation
import AudioToolbox
import MediaPlayer



protocol AvPlayerDelegate: AnyObject {
    func avPlayerSongDidChanged(_ player: AVAudioPlayer)
    func avPlayer(_ player: AVAudioPlayer, updateSliderWith value: Float)
    func avPlayer(_ player: AVAudioPlayer, updateSongTitleWith value: String)
}

final class AudioManager: NSObject {
    
    fileprivate struct Constants {
        static let fadeDuration: TimeInterval = 0.5
        static let volumeRequestTimeInterval: TimeInterval = 0.3
    }
    
    weak var delegate: AvPlayerDelegate?
    var avRecorder: AVAudioRecorder?
    var avPlayer: AVAudioPlayer?
    var displayeLink: CADisplayLink?
    var timer: Timer?
    var currentSongUrl: URL?
    var urls: [URL] = []
    let recorderQueue = DispatchQueue(label: "de.PrimeDay.AudioRecorder", qos: .userInitiated)
    let playerQueue = DispatchQueue(label: "de.PrimeDay.AudioPlayer", qos: .userInitiated)
    let mediaItems = MPMediaQuery.songs().items
    var firstTitle = "This song has no title!"
    
    
    override init() {
        super.init()
        setupAudioSession()
        
        if let mediaItems = mediaItems  {
            mediaItems.forEach {
                urls.append($0.value(forProperty: MPMediaItemPropertyAssetURL) as! URL)
            }
            
            if let mediaTitle = mediaItems[0].title {
                firstTitle = mediaTitle
            }
            
            let url = Bundle.main.url(forResource: "song", withExtension: "mp3")!
            setupAvPlayer( url: urls.isEmpty ? url : urls[0], title: firstTitle)
            setupAvRecorder()
        }
    }   
    
    func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("Audio Session didn't set properly due to : \(error)")
        }
    }
}




// MARK : - Audio Recorder
extension AudioManager {

    func setupAvRecorder(){
        do {
            let url = URL(fileURLWithPath: "/dev/null")
            let settings:[String:Any] = [
                AVSampleRateKey: 44100.0,
                AVFormatIDKey: kAudioFormatAppleLossless,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
            ]
            avRecorder = try AVAudioRecorder(url: url, settings: settings)
        } catch {
            print("AVRecorder properties weren't set properly due to : \(error)")
        }
    }
    
    
    
    func startRecording() {
        recorderQueue.async() {
            self.avRecorder?.prepareToRecord()
            self.avRecorder?.isMeteringEnabled = true
            self.avRecorder?.record()
        }
    }
    
    func readVolumePower() {
        guard let avRecorder = avRecorder else {
            return
        }
        avRecorder.updateMeters()
        
        //To convert dB to the linear value this formula should be used : pow(10, value*0.05)
        // For normalizing the value the result of above mentioned formula is multiplied to 100. the result value is between 0 and 1.
        
        let normalizedValue = pow(10, avRecorder.averagePower(forChannel: 0)*0.05)*100+0.5
        updateVolume(volume: normalizedValue)
    }
    
    func stopRecording() {
        recorderQueue.async() {
            self.avRecorder?.stop()
        }
    }
}


//MARK : - Audio Player
extension AudioManager: AVAudioPlayerDelegate {
    
    func setupAvPlayer(url : URL, title: String) {
        do {
            avPlayer = try AVAudioPlayer(contentsOf: url)
            avPlayer?.delegate = self
            delegate?.avPlayer( avPlayer!, updateSongTitleWith: title)
        } catch {
            print("AVPlayer didn't set up properly due to : \(error)")
        }
    }
    
    func startPlaying(){
        playerQueue.async() {
            self.avPlayer?.prepareToPlay()
            self.avPlayer?.play()
        }
    }
    
    func stopPlaying(){
        playerQueue.async() {
            self.avPlayer?.stop()
        }
    }
    
    func loop(loopIsEnabled: Bool ){
        avPlayer?.numberOfLoops = loopIsEnabled ? -1 : 0
    }
    
    func updateVolume(volume: Float){
        avPlayer?.setVolume(volume, fadeDuration: Constants.fadeDuration)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playNewTrack(next: true)
    }
    
    func start(){
        startPlaying()
        startRecording()
        timer = Timer.scheduledTimer(withTimeInterval: Constants.volumeRequestTimeInterval, repeats: true
            ,block: { _ in
                self.readVolumePower()
        })
        
        displayeLink = CADisplayLink(target: self, selector: #selector(trackAudio))
        displayeLink?.add(to: .current, forMode: .defaultRunLoopMode)
    }
    
    func stop(){
        displayeLink?.invalidate()
        stopRecording()
        stopPlaying()
        timer?.invalidate()
        timer = nil
    }
    
    func trackAudio(){
        guard let player = avPlayer else {
            return
        }
        delegate?.avPlayer(player, updateSliderWith: Float(player.currentTime) )
    }
    
    func playNewTrack(next: Bool){
        guard let currentURL = avPlayer?.url ,  let currentIndex = urls.index(of: currentURL)else {
            return
        }
        
        var newIndex = next ? currentIndex+1 : currentIndex-1
        
        newIndex = newIndex < urls.count ? newIndex : 0
        newIndex = newIndex < 0 ? urls.count-1 : newIndex
        
        var title = ""
        if let mediaItems = mediaItems, let mediaTitle = mediaItems[newIndex].title {
            title = mediaTitle
        }
        stop()
        setupAvPlayer(url: urls[newIndex], title: title)
        start()
        if let player = avPlayer {
            delegate?.avPlayerSongDidChanged(player)
        }
    }
}



