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
    @IBOutlet weak var playWithMotionRateButton: UIButton!
    @IBOutlet weak var motionLabel: UILabel!
    
    // -------------------------------------------------------------------------------------
    // MEMBER VARIABLES (AV & motion handling)
    var mAudioPlayer:AVAudioPlayer!
    var mReceivedAudio:RecordedAudio!
    var mMotionMgr = CMMotionManager()
    var mMotionStart:Vec3!
    var mMotionSensitivity:Double = M_PI_4 * 0.5
    var mAudioEngine:AVAudioEngine!
    var mAEnginePlaying = false
    
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // checks whether audio is playing or not,
    // whether motion is available/active or not,
    // and sets the appropriate state of each button
    func updateButtons(){
        stopButton.hidden = !mAudioPlayer.playing
        if( mAEnginePlaying ) {
            stopButton.hidden = false
        }
        
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
        mAEnginePlaying = false
    }
    
    // setup Motion to detect device orientation
    func setupMotion() -> Bool {
        if mMotionMgr.deviceMotionAvailable {
            mMotionMgr.deviceMotionUpdateInterval = 0.02
            // initialize a start vector to the z+ coordinate direction
            // we'll use the difference between this vector and the phone's
            // current orientation to change the audio rate
            mMotionStart = Vec3(x: 0.0, y: 0.0, z: -1.0)
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
        stopAllAudio()
        
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
       
        do { playerNode.scheduleFile(try AVAudioFile(forReading: mReceivedAudio.filePathUrl), atTime: nil, completionHandler: {} )
            } catch { print("error can't create AVAudioFile") }
        do { try mAudioEngine.start()
            playerNode.play()
            mAEnginePlaying = true
        } catch { print("error starting AVAudioEngine") }
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
        mAudioPlayer.enableRate = true
        mAudioPlayer.rate = rAudioPlayRate
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
        stopAllAudio()
        stopMotionUpdates()
        updateButtons()
    }
    
    // use delegate to ensure that the stop button isn't enabled upon playback finish
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        mAEnginePlaying = false
        stopMotionUpdates()
        updateButtons()
    }
    
    // stop all audio
    func stopAllAudio() {
        mAudioPlayer.stop()
        mAudioEngine.stop()
        mAudioEngine.reset()
        mAEnginePlaying = false
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
        stopAllAudio()
        
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
    
    // returns the angle between the specified vector and the mMotionStart vector
    func radiansBetweenStartAttitudeAndCurrentAttitude(deviceMotion: CMDeviceMotion) -> Double {
        // get the angle between the current vector and the "default" vector
        let curV = Vec3(x:deviceMotion.gravity.x, y: deviceMotion.gravity.y, z: deviceMotion.gravity.z)
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
                    at = abs( (self.mMotionSensitivity - at ) / self.mMotionSensitivity  )
                    
                    self.mAudioPlayer.rate = Float(at)
                    if( at < self.mMotionSensitivity * 0.5 ) {
                        self.motionLabel.text = "Slooow"
                    }
                    else if ( at < self.mMotionSensitivity * 1.5 ) {
                        self.motionLabel.text = "Normal"
                    }
                    else if ( at > self.mMotionSensitivity ) {
                        self.motionLabel.text = "Faast!!"
                    }
                    else{ self.motionLabel.text = String(at) }
                    
                }
            })
        }
    }
}

