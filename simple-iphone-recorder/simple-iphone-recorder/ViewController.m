//
//  ViewController.m
//  simple-iphone-recorder
//
//  Created by Edward anderson on 5/8/14.
//  Copyright (c) 2014 Edward anderson. All rights reserved.
//

#import "ViewController.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFNetworking/AFURLSessionManager.h"
#import "Reachability.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UITextField *fromField;
@property (weak, nonatomic) IBOutlet UITextField *toField;
@property (weak, nonatomic) IBOutlet UILabel *durationField;
@property (strong, nonatomic) NSTimer *repeatingTimer;
@property int timer;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property bool isPaused;
@property UITextField *activeField;
@property NSString* fileName;
@property Reachability* reachability;
@property (weak, nonatomic) IBOutlet UIView *alertView;
@property (weak, nonatomic) IBOutlet UILabel *alertText;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *alertIndicator;


@end

@implementation ViewController

- (NSString*) getTime
{
    NSDate *  senddate=[NSDate date];
    
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    
    [dateformatter setDateFormat:@"YYYY_MM_dd_hh_mm_ss"];
    
    NSString *  time =[dateformatter stringFromDate:senddate];
    return time;
}

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onFileUploaded:)
                                                 name:@"file_uploaded" object:nil];
    
}

- (void)onUploaded:(NSString*)file
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"Uploaded file %@",file);
        
        if([self.alertView isHidden]){
            
            [uploadedText setText:[NSString stringWithFormat:@"Uploaded file %@",file]];
            [uploadedText setHidden:false];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [uploadedText setHidden:true];
            });
        }
    });
}

- (void)onFileUploaded:(NSNotification*)msg
{
    NSString* file = [[msg userInfo] objectForKey:@"file"];
    [self onUploaded:file];
    NSLog(@"Uploaded file %@",file);
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    
    if (!CGRectContainsPoint(aRect, self.activeField.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.activeField.frame animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

#pragma mark Reachability Methods
- (void)checkReachability
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    self.reachability = [Reachability reachabilityForInternetConnection];
    [self.reachability startNotifier];
    [self updateInterfaceWithReachability:self.reachability];
}

/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    [self updateInterfaceWithReachability:curReach];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    NetworkStatus status = [reachability currentReachabilityStatus];
    
    if(status == NotReachable)
    {
        //No internet
    }
    else if (status == ReachableViaWiFi)
    {
        //WiFi
        NSLog(@"Upload all files when network recovered.");
        
        [self uploadAllFiles];
    }
    else if (status == ReachableViaWWAN)
    {
        //3G
        NSLog(@"Upload all files when network recovered.");
        [self uploadAllFiles];
    }
}

-(void)uploadFile:(NSURL*)filePath withName:(NSString*)fileName
{
    if([fileName isEqualToString:self.fileName]){
        return;
    }
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST"
                                                                                              URLString:@"https://pandora.collectiveintelligence.com.au/VoiceReocorder/uploadfile.do" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>formData) {[formData appendPartWithFileURL:filePath name:@"file" fileName:fileName mimeType:@"application/octet-stream" error:nil];}error:nil];
    
    [request addValue:fileName forHTTPHeaderField:@"FileName"];
    
    AFURLSessionManager *manager;
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
        manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:fileName]];
    }else{
        manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration backgroundSessionConfiguration:fileName]];
    }
    
    NSProgress *progress = nil;
    
    NSString* name = [fileName copy];
    
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithRequest:request fromFile:filePath progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        
        NSLog(@"Complete uploading file %@.",name);
        
        if (error) {
            if(responseObject)
            {
                NSData * data = (NSData*)responseObject;
                NSString * r = [NSString stringWithUTF8String:data.bytes];
                NSLog(@"%@",r);
            }
            
            NSHTTPURLResponse *hr = (NSHTTPURLResponse*)response;
            NSInteger r = [hr statusCode];
            if(r == 200){
                NSLog(@"Uploaded file %@.",name);
                [self completeUpload:true file:name];
            }else{
                NSLog(@"Failed to uploaded file %@.",name);
                [self completeUpload:false file:name];
            }
        } else {
            NSLog(@"Uploaded file %@.",name);
            [self completeUpload:true file:name];
        }
    }];
    
    [uploadTask resume];
}
- (void)uploadAllFiles
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* path = [paths objectAtIndex:0];
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    for (int i = 0; i < (int)[directoryContent count]; i++)
    {
        NSString* filePath = [directoryContent objectAtIndex:i];
        NSString* fullPath = [path stringByAppendingPathComponent:filePath];
        NSString* fileName = [filePath lastPathComponent];
        NSString* fileType = [fileName pathExtension];
        if([fileType isEqualToString:@"m4a"])
        {
            NSURL* url = [NSURL fileURLWithPath:fullPath];
            [self uploadFile:url withName:fileName];
        }
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self checkReachability];
    
    [self.alertView setHidden:YES];
    [uploadedText setHidden:YES];
    
    NSError *setCategoryErr = nil;
    audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory: AVAudioSessionCategoryRecord error:&setCategoryErr];
    
    maxTime = 30*60;
    
    [self registerForKeyboardNotifications];
    
    self.isPaused = false;
    CGFloat cl = 0.7;
    UIColor *bc = [UIColor colorWithRed:cl green:cl blue:cl alpha:1.0];
    [self.recordButton setTitleColor:bc forState:UIControlStateDisabled];
    [self.pauseButton setTitleColor:bc forState:UIControlStateDisabled];
    [self.stopButton setTitleColor:bc forState:UIControlStateDisabled];
    [self.recordButton setEnabled:true];
    [self.pauseButton setEnabled:false];
    [self.stopButton setEnabled:false];
    self.fromField.delegate = (id<UITextFieldDelegate>)self;
    self.toField.delegate = (id<UITextFieldDelegate>)self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onBackground)
                                                 name:@"background" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification object:nil];
}

- (void)handleInterruption:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    
    if (type == AVAudioSessionInterruptionTypeBegan) {
        // Handle AVAudioSessionInterruptionTypeBegan
        [self stopRecord:nil];
    } else {
        // Handle AVAudioSessionInterruptionTypeEnded
    }  
}

- (void)onBackground
{
    [self stopRecord:nil];
}

- (void)setFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    
    NSString* time = [self getTime];
    NSString * from = self.fromField.text;
    NSString * to = self.toField.text;
    
    self.fileName = [NSString stringWithFormat:@"%@_%@_%@.m4a",from,to,time];
    
    NSString *soundFilePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:self.fileName];
    
    soundUrl= [NSURL fileURLWithPath:soundFilePath];
}

- (void) initRecorder
{
    NSError *error = nil;
    
//    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
//                              [NSNumber numberWithFloat: 44100.0],                 AVSampleRateKey,
//                              [NSNumber numberWithInt: kAudioFormatAppleIMA4], AVFormatIDKey,
//                              [NSNumber numberWithInt: 1],                         AVNumberOfChannelsKey,
//                              [NSNumber numberWithInt: AVAudioQualityMin],         AVEncoderAudioQualityKey,
//                              nil];
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithFloat: 16000.0],                 AVSampleRateKey,
                              [NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                              [NSNumber numberWithInt: 1],                         AVNumberOfChannelsKey,
                              [NSNumber numberWithInt: AVAudioQualityMin],         AVEncoderAudioQualityKey,
                              nil];

    
    
    [self setFilePath];
    
    recorder = [[AVAudioRecorder alloc] initWithURL:soundUrl settings:settings error:&error];
    recorder.delegate = self;
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
//    [self stopRecord:nil];
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder
                                   error:(NSError *)error
{
    [self stopRecord:nil];
}

- (void)uploadFile
{
    if([self.fileName isEqualToString:@""]){
        NSLog(@"No file to upload.");
        return;
    }
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST"
        URLString:@"https://pandora.collectiveintelligence.com.au/VoiceReocorder/uploadfile.do"
        //        URLString:@"http://posttestserver.com/post.php"
        parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileURL:soundUrl name:@"file" fileName:self.fileName mimeType:@"application/octet-stream" error:nil];
        } error:nil];

    [request addValue:self.fileName forHTTPHeaderField:@"FileName"];
    
    AFURLSessionManager *manager;
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
        
        manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:self.fileName]];
    }else{
        manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration backgroundSessionConfiguration:self.fileName]];
    }
    
    NSProgress *progress = nil;
    
    currentFileName = self.fileName;
    
    NSString* name = [self.fileName copy];
    
    [self showUploading];
    
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithRequest:request fromFile:soundUrl progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        
        NSLog(@"Complete uploading file %@.",name);
        
        if (error) {
            if(responseObject)
            {
                NSData * data = (NSData*)responseObject;
                NSString * r = [NSString stringWithUTF8String:data.bytes];
                NSLog(@"%@",r);
            }
            
            NSHTTPURLResponse *hr = (NSHTTPURLResponse*)response;
            NSInteger r = [hr statusCode];
            if(r == 200){
                NSLog(@"Uploaded file %@.",name);
                [self completeUpload:true file:name];
            }else{
                NSLog(@"Failed to uploaded file %@.",name);
                [self completeUpload:false file:name];
            }
        } else {
            NSLog(@"Uploaded file %@.",name);
            [self completeUpload:true file:name];
        }
    }];
    
    [uploadTask resume];
    
    soundUrl = [NSURL fileURLWithPath:@""];
    self.fileName = @"";
}

- (void)showUploading
{
    [self.alertView setHidden:NO];
    [self.view bringSubviewToFront:self.alertView];
    [self.alertText setText:@"Uploading..."];
    [self.alertIndicator startAnimating];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if(![self.alertView isHidden]){
            [self.alertText setText:@"Uploading needs more time to finish, it will run in the background, you can continue recording now."];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self.alertView setHidden:YES];
            });
        }
    });
}

- (void)completeUpload:(Boolean)succeed file:(NSString*)fileName
{
    NSLog(@"Current file: %@, completed file: %@", currentFileName, fileName);
    
    if([self.alertView isHidden] && succeed){
        
        [self onUploaded:fileName];
        
        return;
    }
    
    if(![currentFileName isEqualToString:fileName]){
        return;
    }

    [self.alertIndicator stopAnimating];
    if(succeed){
        [self.alertText setText:@"Record uploaded."];
    }else{
        [self.alertText setText:@"Failed to upload the record, we will try again later."];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.alertView setHidden:YES];
    });
}
- (IBAction)onContinueButton:(UIButton *)sender {
    [self.alertView setHidden:YES];
}

- (IBAction)stopRecord:(UIButton *)sender {
    
//    if(recorder.recording || self.isPaused)
//    {
        [recorder stop];
    
        NSError *activationErr  = nil;
        [audioSession setActive:NO error:&activationErr];
    
        [self stopTimer];
        
        [self.recordButton setTitle:@"Start" forState:UIControlStateNormal];
        [self.recordButton setEnabled:true];
        [self.pauseButton setEnabled:false];
        [self.stopButton setEnabled:false];
        self.isPaused = false;
        
        [self uploadFile];
//    }
}

- (IBAction)pauseRecord:(UIButton *)sender {
    if(recorder.recording)
    {
        if(self.timer >= maxTime)
        {
            NSLog(@"Automatically stop timer,duration:%d,maxtime:%d",self.timer, maxTime);
            [self stopRecord:nil];
            return;
        }
        
        [recorder pause];
        [self stopTimer];
        
        [self.recordButton setTitle:@"Resume" forState:UIControlStateNormal];
        [self.recordButton setEnabled:true];
        [self.pauseButton setEnabled:false];
        
        self.isPaused = true;
    }
}

- (IBAction)startRecord:(id)sender {
    
    if(!recorder.recording){
        
        NSString * from = self.fromField.text;
        NSString * to = self.toField.text;
        if([from isEqualToString:@""])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry !" message:@"Please enter the 'Contact Email' field first." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil,nil];
            [alert show];
            return;
        }
        if([to isEqualToString:@""])
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry !" message:@"Please enter the 'Subject Name' field first." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil,nil];
            [alert show];
            return;
        }
        
        if(self.isPaused)
        {
            if(self.timer >= maxTime)
            {
                NSLog(@"Automatically stop timer,duration:%d,maxtime:%d",self.timer, maxTime);
                [self stopRecord:nil];
                return;
            }
            
            [recorder record];
            
            [self startTimer];
            
            [self.pauseButton setEnabled:true];
            [self.recordButton setEnabled:false];
            self.isPaused = false;
        }
        else
        {
            [self initRecorder];
            
            NSError *activationErr  = nil;
            [audioSession setActive:YES error:&activationErr];
            
            [recorder prepareToRecord];
            [recorder record];
            
            self.timer = 0;
            [self startTimer];
            
            [self.recordButton setEnabled:false];
            [self.pauseButton setEnabled:true];
            [self.stopButton setEnabled:true];
        }

    }
    else
    {
        return;
    }
}
- (IBAction)screenTap:(id)sender {
    if(![self.alertView isHidden]){
        [self.alertView setHidden:YES];
        return;
    }
    
    [currentResponder resignFirstResponder];
    [self.fromField resignFirstResponder];
    [self.toField resignFirstResponder];
}
- (IBAction)fromEditBegin:(id)sender {
    currentResponder = (UIInputView *)sender;
}
- (IBAction)toEditBegin:(id)sender {
    currentResponder = (UIInputView *)sender;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeField = nil;
}

-(void)startTimer
{
    if(self.repeatingTimer)
    {
         [self.repeatingTimer invalidate];
    }
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self selector:@selector(updateTime:)
                                                    userInfo:nil repeats:YES];
    self.repeatingTimer = timer;
}
-(void)stopTimer
{
    if(self.repeatingTimer)
    {
        [self.repeatingTimer invalidate];
    }
}

-(void)setDuration
{
    self.timer++;
    
    int h = self.timer/3600;
    int m = (self.timer%3600)/60;
    int s = (self.timer%60);
    NSString * ts = [NSString stringWithFormat:@"%02d:%02d:%02d",h,m,s];
    
    [self.durationField setText:ts];
    
    if(self.timer >= maxTime)
    {
        NSLog(@"Automatically stop timer,duration:%d,maxtime:%d",self.timer, maxTime);
        [self stopRecord:nil];
        return;
    }
}

-(void)updateTime:(NSTimer*)timer
{
    [self performSelectorOnMainThread:@selector(setDuration) withObject:self waitUntilDone:NO];
}



@end
