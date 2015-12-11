//
//  AppDelegate.h
//  simple-iphone-recorder
//
//  Created by Edward anderson on 5/8/14.
//  Copyright (c) 2014 Edward anderson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
- (void)removeFile:(NSString*)fileName;

@end
