//
//  Tweak.xm
//  Hack SpringBoard to fill Appstore password automatically
//
//  Created by twotrees on 2018/11/09.
//  Copyright © 2018 twotrees. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/ALAsset.h>
#import <UserNotifications/UserNotifications.h>

//--------------------------------------------------------------------------------------------------------------------------------------------------------------

void _debugMsg(NSString* msg) {
	NSLog(@"NoBackgroundPhotoAccess from %@-%d : %@", [NSProcessInfo processInfo].processName, [NSProcessInfo processInfo].processIdentifier, msg);
}

NSDictionary* _configDic() {
	return [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.twotrees.nobackgroundphotoaccessprefer.plist"];
}

BOOL _enabled() {
    NSDictionary *prefs = _configDic();
    BOOL enabled = [prefs[@"Enabled"] boolValue];
    NSLog(@"tweak enabled: %d", enabled);
    return enabled;
}

BOOL _shouldBlockAccess() {
    if (_enabled()) {  
        if ([NSProcessInfo processInfo].arguments.count) {
            NSString* exePath = [NSProcessInfo processInfo].arguments[0];
            if ([exePath hasPrefix:@"/var/containers/Bundle/Application"]) {
                _debugMsg(@"is user app");
                if (UIApplicationStateBackground == [UIApplication sharedApplication].applicationState) {
                    return YES;
                }                
            }
        }                    
    }


    return NO;
}

BOOL _sendAlertNotification() {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.badge = [NSNumber numberWithInt:1];
    content.title = @"NoBackgroundPhotoAccess";
    content.body = @"Found background photo fetch behavior, blocked!";
    content.sound = [UNNotificationSound defaultSound];
    UNTimeIntervalNotificationTrigger *trigger =  [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0 repeats:NO];
    UNNotificationRequest *notificationRequest = [UNNotificationRequest requestWithIdentifier:@"NoBackgroundPhotoAccess" content:content trigger:trigger];
    [center addNotificationRequest:notificationRequest withCompletionHandler:nil];
}

//--------------------------------------------------------------------------------------------------------------------------------------------------------------

%ctor {
	_debugMsg(@"launched");
}

%hook PHImageManager

- (instancetype)init {
    _debugMsg(@"request PHImageManager");

    
    if (_shouldBlockAccess()) {
        _debugMsg(@"block access PHImageManager");
        _sendAlertNotification();
        return nil;
    } else {
        _debugMsg(@"enable access PHImageManager");
        return %orig;
    }
}

%end

//--------------------------------------------------------------------------------------------------------------------------------------------------------------


%hook ALAsset

- (ALAssetRepresentation *)defaultRepresentation {
    _debugMsg(@"request ALAssetRepresentation");

    
    if (_shouldBlockAccess()) {
        _debugMsg(@"block access ALAssetRepresentation");
        _sendAlertNotification();
        return nil;
    } else {
        _debugMsg(@"enable access ALAssetRepresentation");
        return %orig;
    }
}


- (ALAssetRepresentation *)representationForUTI:(NSString *)representationUTI {
    _debugMsg(@"request representationForUTI");

    
    if (_shouldBlockAccess()) {
        _debugMsg(@"block access representationForUTI");
        _sendAlertNotification();
        return nil;
    } else {
        _debugMsg(@"enable access representationForUTI");
        return %orig(representationUTI);
    }
}

%end