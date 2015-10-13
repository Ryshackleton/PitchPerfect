//
//  PlaySoundsViewController.swift
//  PitchPerfect
//
//  Created by Ryan Shackleton on 10/10/15.
//  Copyright © 2015 Shackleton Computing. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import CoreMotion

// -------------------------------------------------------------------------------------
// Plays sounds recorded in RecordSoundsViewController and applies various sound effects
class PlaySoundsViewController: UIViewController, AVAudioPlayerDelegate  {
    
    // -------------------------------------------------------------------------------------
    // OUTLETS (buttons & ui)
    @IBOutlet weak var playSlowButton: UIButton!
    @IBOutlet weak var playFastButton: UIButton!
    @IBOutlet weak var playChipmunkAudioButton: UIButton!
    @IBOutlet weak var playDarthAudioButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var stopAudioEngineButton: UIButton!
    @IBOutlet weak var playWithMotionRateButton: UIButton!
    @IBOutlet weak var motionLabel: UILabel!
    
    // -------------------------------------------------------------------------------------
    // MEMBER VARIABLES (AV & motion handling)
    var mAudioPlayer:AVAudioPlayer!
    var mReceivedAudio:RecordedAudio!
    var mMotionMgr = CMMotionManager()
    var mMotionStart:Vec3!
    var mAudioEngine:AVAudioEngine!
    
    // -------------------------------------------------------------------------------------
    // METHODS
    
    // -------------------------------------------------------------------------------------
    // UI SETUP AND UPDATE
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        // manage button updates
        setupPlayer()
        setupPitchPlayer()
        setupMotion()
        updateButtons()
    }
    
    override func viewWillDisappear(animated: Bool) {
        onStopButtonTouched(stopButton)
        onStopAudioEngineButtonTouched(stopAudioEngineButton)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // checks whether audio is playing or not,
    // whether motion is available/active or not,
    // and sets the appropriate state of each button
    func updateButtons(){
        
        let somethingPlaying:Bool =  mAudioPlayer.playing || mAudioEngine.running
        
        playFastButton.enabled = !somethingPlaying
        playSlowButton.enabled = !somethingPlaying
        playChipmunkAudioButton.enabled = !somethingPlaying
        playDarthAudioButton.enabled = !somethingPlaying
        playWithMotionRateButton.enabled = !somethingPlaying
        
        stopButton.hidden = !mAudioPlayer.playing
        stopAudioEngineButton.hidden = !mAudioEngine.running
        
        // hide motion buttons in emulator mode or if no accelerometer/gyro are available
        if( mMotionMgr.deviceMotionAvailable ) {
            playWithMotionRateButton.hidden = false
            motionLabel.hidden = false
            if( !mMotionMgr.deviceMotionActive ) {
                motionLabel.text = "Tap and flatten phone to slow playback"
            }
        }
        else {
            playWithMotionRateButton.hidden = true
            motionLabel.hidden = true
        }
        
    }
    
    // -------------------------------------------------------------------------------------
    // INITIALIZER METHODS TO SET UP audio players and motion
    
    // setup player, return true if we have a playable file or return false if not
    func setupPlayer() {
        // make audio go to the iPhone speaker, not the headset audio
        // help from: http://stackoverflow.com/questions/1022992/how-to-get-avaudioplayer-output-to-the-speaker
        let avSession:AVAudioSession = AVAudioSession.sharedInstance()
        do { try avSession.overrideOutputAudioPort(AVAudioSessionPortOverride.Speaker) } catch { }
        
        // play recorded audio
        do { try mAudioPlayer = AVAudioPlayer(contentsOfURL: mReceivedAudio.filePathUrl) }
        catch { print("error setting up AVAudioPlayer") }
    }
    
    // setup pitch player for chipmunk and darth effects
    func setupPitchPlayer() {
        mAudioEngine = AVAudioEngine()
    }
    
    // setup Motion to detect device orientation
    func setupMotion() -> Bool {
        if mMotionMgr.deviceMotionAvailable {
            mMotionMgr.deviceMotionUpdateInterval = 0.02
            // initialize a start vector to the z+ coordinate direction
            // we'll use the difference between this vector and the phone's
            // current orientation to change the audio rate
            mMotionStart = Vec3()
            mMotionStart.x = 0.0
            mMotionStart.y = 0.0
            mMotionStart.z = 1.0
            return true
        }
        return false
    }
    
    
    // -------------------------------------------------------------------------------------
    // AUDIO PLAYBACK that uses AVAudioEngine - for pitch with Chipmunk & Darth sounds
    
    // chipmumk player, utilizes the AVAudioEngine instead of AVAudioPlayer
    @IBAction func onPlayChipmunkButtonTouched(sender: UIButton) {
        playPitchAudio(1200, rRate:1)
        updateButtons()
    }
    
    // darth vader player, utilizes the AVAudioEngine instead of AVAudioPlayer
    @IBAction func onPlayDarthButtonTouched(sender: UIButton) {
        playPitchAudio(-1000, rRate:0.8)
        updateButtons()
    }
    
    // start audio playback and update buttons
    func playPitchAudio(rPitch:Float, rRate:Float) {
        // check for already playing
        mAudioPlayer.stop()
        mAudioEngine.stop()
        mAudioEngine.reset()
        
        // do a whole bunch of crazy setup
        // help from: http://stackoverflow.com/questions/25704923/using-apples-new-audioengine-to-change-pitch-of-audioplayer-sound
        let playerNode = AVAudioPlayerNode()// build player node
        mAudioEngine.attachNode(playerNode) // player->audio engine
        let mixer = mAudioEngine.outputNode
        let auTimePitch = AVAudioUnitTimePitch() // this one does pitch and rate...sure, why not?
        auTimePitch.pitch = rPitch
        auTimePitch.rate = rRate
        // attach and connect everything
        mAudioEngine.attachNode(auTimePitch)
        mAudioEngine.connect(playerNode, to:auTimePitch, format: mixer.outputFormatForBus(0))
        mAudioEngine.connect(auTimePitch, to: mixer, format: mixer.outputFormatForBus(0))
       
        do {
            let avFile:AVAudioFile = try AVAudioFile(forReading: mReceivedAudio.filePathUrl)
            playerNode.scheduleFile(avFile, atTime: nil, completionHandler: { self.onPitchPlayCompletion() } )
            
            } catch { print("error can't create AVAudioFile") }
        
        do { try mAudioEngine.start()
             playerNode.play()
        } catch { print("error starting AVAudioEngine") }
    }
    
    func onPitchPlayCompletion() {
        // this seems to do nothing and gets called somehow in relation to the length of the play buffer?
        // TODO: figure out how to handle this like a delegate. completionHandler: doesn't seem to call in any predictable manner
        // annoying, because the stop button ends up hanging around after playback ends when it should disappear as with AVAudioPlayer
//        mAudioPlayer.stop()
//        mAudioEngine.stop()
//        mAudioEngine.reset()
//        updateButtons()
    }
    
    // stop audio engine play and update buttons (same icon as other stop button)
    @IBAction func onStopAudioEngineButtonTouched(sender: UIButton) {
        mAudioEngine.stop()
        mAudioEngine.reset()
        updateButtons()
    }
    
    // -------------------------------------------------------------------------------------
    // AUDIO PLAYBACK that uses AVAudioPlayer
    
    // start audio playback and update buttons
    func playAudio(rAudioPlayRate: Float )
    {
        // ensure that the audio engine is not playing
        mAudioEngine.stop()
        
        mAudioPlayer.delegate = self
        mAudioPlayer.currentTime = 0.0
        mAudioPlayer.enableRate = true
        mAudioPlayer.rate = rAudioPlayRate
        mAudioPlayer.stop()
        mAudioPlayer.prepareToPlay()
        mAudioPlayer.play()
    }
    
    // start play slow and update buttons
    @IBAction func onPlaySlowButtonTouched(sender: UIButton) {
        playAudio(0.5)
        updateButtons()
    }
    
    // start play fast and update buttons
    @IBAction func onPlayFastButtonTouched(sender: UIButton) {
        
        playAudio(1.5)
        updateButtons()
    }
    
    // stop play and update buttons
    @IBAction func onStopButtonTouched(sender: UIButton) {
        mAudioPlayer.stop()
        stopMotionUpdates()
        updateButtons()
    }
    
    // use delegate to ensure that the stop button isn't enabled upon playback finish
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        stopMotionUpdates()
        updateButtons()
    }
    
    // -------------------------------------------------------------------------------------
    // AUDIO PLAYBACK linked to motion detection, uses AVAudioPlayer
    @IBAction func onPlayWithMotionButtonTouched(sender: UIButton) {
        playAudioWithMotion(1.0)
        updateButtons()
    }
    
    // start audio playback and update buttons
    func playAudioWithMotion(rAudioPlayRate: Float )
    {
        // ensure that the audio engine is not playing
        mAudioEngine.stop()
        
        mAudioPlayer.delegate = self
        mAudioPlayer.currentTime = 0.0
        mAudioPlayer.enableRate = true
        mAudioPlayer.rate = rAudioPlayRate
        startMotionUpdates()
        updateAudioRateWithMotion()
        mAudioPlayer.stop()
        mAudioPlayer.prepareToPlay()
        mAudioPlayer.play()
    }
    
    // -------------------------------------------------------------------------------------
    // MOTION DETECTION TO CONTROL PLAYBACK SPEED
    // used the following websites for help:
    // http://nshipster.com/cmdevicemotion/
    // http://forestgiant.com/blog/article/ios-device-motion-apps-with-attitude
    // stop tracking motion
    func stopMotionUpdates() -> Bool {
        if mMotionMgr.deviceMotionAvailable {
            mMotionMgr.stopDeviceMotionUpdates()
            return true
        }
        return false
    }
    
    // start tracking motion
    func startMotionUpdates() -> Bool {
        if mMotionMgr.deviceMotionAvailable {
            mMotionMgr.startDeviceMotionUpdates()
            return true
        }
        return false
    }
    
    func radiansBetweenStartAttitudeAndCurrentAttitude(deviceMotion: CMDeviceMotion) -> Double {
        // TODO: figure out how to write a constructor in swift
        let curV = Vec3()
        curV.x = deviceMotion.gravity.x
        curV.y = deviceMotion.gravity.y
        curV.z = deviceMotion.gravity.z
        return mMotionStart.radiansBetween(curV)
    }
    
    // use the difference between the z=1 direction to normalize the playback rate
    // (tilting to flat decreases playback rate,
    //  and holding upright speeds up play rate)
    func updateAudioRateWithMotion() {
        if mMotionMgr.deviceMotionAvailable {
            mMotionMgr.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue(), withHandler:{
                (deviceMotion, error) -> Void in
                if( error == nil )  {// is this the best way to check for nil values?
                
                    var at = abs( self.radiansBetweenStartAttitudeAndCurrentAttitude(deviceMotion!) )
                    at = abs( M_1_PI / (M_1_PI - at ) )
                    
                    self.mAudioPlayer.rate = Float(at)
                    if( at < M_2_PI ) {
                        self.motionLabel.text = "Slooow"
                    }
                    else if ( at < M_PI ) {
                        self.motionLabel.text = "Normal"
                    }
                    else if ( at > M_PI ) {
                        self.motionLabel.text = "Faast!!"
                    }
                    else{ self.motionLabel.text = String(at) }
                    
                }
            })
        }
    }
}

