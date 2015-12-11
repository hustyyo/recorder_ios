//
//  AppDelegate.m
//  simple-iphone-recorder
//
//  Created by Edward anderson on 5/8/14.
//  Copyright (c) 2014 Edward anderson. All rights reserved.
//

#import "AppDelegate.h"

#import "AFHTTPRequestOperationManager.h"
#import "AFNetworking/AFURLSessionManager.h"


@implementation AppDelegate 


-(void)uploadFile:(NSURL*)filePath withName:(NSString*)fileName
{
    
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
    
    NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithRequest:request fromFile:filePath progress:&progress completionHandler:nil];
    
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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:1.0];
    
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"applicationWillResignActive");
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"background" object:nil];
    
    NSLog(@"applicationDidEnterBackground, time left %f",[[UIApplication sharedApplication] backgroundTimeRemaining]);
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"applicationWillEnterForeground");
    
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self uploadAllFiles];
    
    NSLog(@"applicationDidBecomeActive");
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSLog(@"applicationWillTerminate");
}

- (void)removeFile:(NSString*)fileName
{
    NSLog(@"delete file %@", fileName);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
    
    NSError *error;
    BOOL success = [fileManager removeItemAtPath:filePath error:&error];
    if (!success) {
        NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
    }
}
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)())completionHandler
{
    NSLog(@"Finish background uploading file %@", identifier);
    
    [self removeFile:identifier];
    
    if(completionHandler)
    {
        completionHandler();
    }
}

@end
