#import <Cephei/HBPreferences.h>
#import <AudioToolbox/AudioServices.h>
#import <UIKit/UIKit.h>
#import <HBLog.h>
#import "SparkColourPickerUtils.h"
#import "SparkColourPickerView.h"

@interface _UIScrollViewScrollIndicator : UIView
@property (nonatomic,retain) UIColor * foregroundColor;
@property (assign,nonatomic) long long style;
-(void)addScrollbarAnimation;
@end

@interface UIScrollViewKnobLongPressGestureRecognizer : UILongPressGestureRecognizer
@end

static NSMutableDictionary *colorDictionary;
static NSString *nsNotificationString = @"com.nahtedetihw.magicalscrollbarsprefs.color/changed";

HBPreferences *preferences;
BOOL enabled;
BOOL removeScrollBarGrabDelay;

%group MagicalScrollbars

%hook _UIScrollViewScrollIndicator
-(void)layoutSubviews {
    %orig;
    [self addScrollbarAnimation];
}

%new
-(void)addScrollbarAnimation {
    self.foregroundColor = [SparkColourPickerUtils colourWithString:[colorDictionary objectForKey:@"color1Key"] withFallback:@"#FF0000"];
    [UIView animateWithDuration:0.3 delay:0 options: UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat animations:^{
        self.foregroundColor = [SparkColourPickerUtils colourWithString:[colorDictionary objectForKey:@"color2Key"] withFallback:@"#FF9A00"];
    } completion:nil];
}

%end

// https://github.com/NSExceptional/NoScrollbarGrabDelay
%hook UIScrollViewKnobLongPressGestureRecognizer
- (NSTimeInterval)delay {
    if (removeScrollBarGrabDelay) {
    return 0;
    }
    return %orig;
}
- (NSTimeInterval)minimumPressDuration {
    if (removeScrollBarGrabDelay) {
    return 0;
    }
    return %orig;
}
%end

%end

static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    // Notification for colors
    colorDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.nahtedetihw.magicalscrollbarsprefs.color.plist"];
}

%ctor {
    BOOL shouldLoad = NO;
    NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
    NSUInteger count = args.count;
    if (count != 0) {
        NSString *executablePath = args[0];
        if (executablePath) {
            NSString *processName = [executablePath lastPathComponent];
            BOOL isSpringBoard = [processName isEqualToString:@"SpringBoard"];
            BOOL isPreferences = [processName isEqualToString:@"Preferences"];
            BOOL isApplication = [executablePath rangeOfString:@"/Application/"].location != NSNotFound || [executablePath rangeOfString:@"/Applications/"].location != NSNotFound;
            BOOL isFileProvider = [[processName lowercaseString] rangeOfString:@"fileprovider"].location != NSNotFound;
            BOOL skip = [processName isEqualToString:@"AdSheet"]
            || [processName isEqualToString:@"CoreAuthUI"]
            || [processName isEqualToString:@"InCallService"]
            || [processName isEqualToString:@"MessagesNotificationViewService"]
            || [executablePath rangeOfString:@".appex/"].location != NSNotFound;
            if (!isFileProvider && (isSpringBoard || isApplication || isPreferences) && !skip) {
                shouldLoad = YES;
            }
        }
    }
    if (shouldLoad) {
    notificationCallback(NULL, NULL, NULL, NULL, NULL);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback, (CFStringRef)nsNotificationString, NULL, CFNotificationSuspensionBehaviorCoalesce);
        
    preferences = [[HBPreferences alloc] initWithIdentifier:@"com.nahtedetihw.magicalscrollbarsprefs"];
    [preferences registerBool:&enabled default:NO forKey:@"enabled"];
    [preferences registerBool:&removeScrollBarGrabDelay default:NO forKey:@"removeScrollBarGrabDelay"];

    if (enabled) {
        %init(MagicalScrollbars);
        return;
    }
    return;
    }
}
