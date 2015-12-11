//
//  ViewController.h
//  simple-iphone-recorder
//
//  Created by Edward anderson on 5/8/14.
//  Copyright (c) 2014 Edward anderson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface ViewController : UIViewController <AVAudioRecorderDelegate, UITextViewDelegate>{
    AVAudioRecorder *recorder;
    float averagePower;
    float peakPower;
    NSURL *soundUrl;
    UIInputView *currentResponder;
    
    AVAudioSession* audioSession;
    int maxTime;
    
    NSString* currentFileName;
    __weak IBOutlet UILabel *uploadedText;
}


@end
