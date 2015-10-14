//
//  RecordSoundsViewController.swift
//  PitchPerfect
//
//  Created by Ryan Shackleton on 10/5/15.
//  Copyright © 2015 Shackleton Computing. All rights reserved.
//

import UIKit
import AVFoundation

// -------------------------------------------------------------------------------------
// Records a user's voice using 2 play and record buttons, and a label to indicate recording state
class RecordSoundsViewController: UIViewController, AVAudioRecorderDelegate {
    
    // -------------------------------------------------------------------------------------
    // OUTLETS (buttons & ui)
    @IBOutlet weak var recordLabel: UILabel!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    
    // -------------------------------------------------------------------------------------
    // MEMBER VARIABLES (AV & motion handling)
    var mAudioRecorder:AVAudioRecorder!

    // -------------------------------------------------------------------------------------
    // METHODS
    
    // -------------------------------------------------------------------------------------
    // UI SETUP AND UPDATE
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func viewWillAppear(animated: Bool) {
        // TODO handle case where recording is active upon navigation
        updateButtons(false);
    }

    // enables and disables buttons based on a recording state
    func updateButtons(isRecording: Bool)
    {
        recordButton.enabled = !isRecording
        stopButton.hidden = !isRecording
        stopButton.enabled = isRecording
        if( isRecording ) {
            recordLabel.text = "Recording..."
        }
        else {
            recordLabel.text = "Tap the mic and say something!"
        }
    }

    // -------------------------------------------------------------------------------------
    // AUDIO RECORDING
    
    // #ryannotes - @IBAction = interface builder action
    // updates UI buttons/labels and starts recording
    @IBAction func recordAudio(sender: UIButton) {
        
        // enable/disable appropriate buttons/labels
        updateButtons(true)
        
        //  Start recording the user's voice
        // 1) Find a directory on the phone to write to and a file name
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        // to overwrite the same file every time
        // 2) setup and start recording
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        try! mAudioRecorder = AVAudioRecorder(URL: NSURL.fileURLWithPathComponents([dirPath,"my_audio.wav"])!, settings: [:] )
        mAudioRecorder.delegate = self
        mAudioRecorder.meteringEnabled = true
        mAudioRecorder.prepareToRecord()
        mAudioRecorder.record()
    }
    
    // preps the RecordedAudio to be passed along to PlaySoundsViewController - basically assigns the file URL & seque ID
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if( segue.identifier == "stopRecording" ) {
            let playSoundsVC:PlaySoundsViewController = segue.destinationViewController as! PlaySoundsViewController
            let data = sender as! RecordedAudio
            playSoundsVC.mReceivedAudio = data
        }
    }
    
    // on recording finished, this saves the file
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            // save the recorded audio
            self.performSegueWithIdentifier("stopRecording", sender: RecordedAudio(filePathUrl:recorder.url, title: recorder.url.lastPathComponent! ) )
        } else {
            print("Recording was not successful")
        }
        // in case recording somehow stops without the stop button
        updateButtons(false)
    }
    
    // updates UI buttons/labels and stops recording
    @IBAction func stopRecording(sender: UIButton) {
        
        // enable/disable appropriate buttons/labels
        updateButtons(false)
        
        // Stop recording the user's voice
        mAudioRecorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(false)
    }

}
