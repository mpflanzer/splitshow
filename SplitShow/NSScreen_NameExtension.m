//
//  NSScreen_NameExtension.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 06/05/2015.
//
//

#import <IOKit/IOKitLib.h>
#import <IOKit/graphics/IOGraphicsLib.h>
#import <ApplicationServices/ApplicationServices.h>
#import <CoreFoundation/CoreFoundation.h>
#import "NSScreen_NameExtension.h"

@implementation NSScreen (NameExtension)

- (CGDirectDisplayID)displayID
{
    return [[[self deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
}

- (NSString*)name
{
    io_service_t        displayPort;
    CFIndex             count;
    NSString            *screenName =  nil;
    CFDictionaryRef     infoDict =      NULL;
    CFDictionaryRef     nameDict =      NULL;

    //TODO:Replace with https://github.com/glfw/glfw/blob/2d1a98136ef876ba6548cf9acb3fea3aae695718/src/cocoa_monitor.m
    displayPort =   CGDisplayIOServicePort([self displayID]);

    if (displayPort == MACH_PORT_NULL)
    {
        return @"Unknown";
    }

    infoDict =      IODisplayCreateInfoDictionary(displayPort, kIODisplayOnlyPreferredName);
    nameDict =      CFDictionaryGetValue(infoDict, CFSTR(kDisplayProductName));
    count =         CFDictionaryGetCount(nameDict);

    if (count == 0)
    {
        screenName = @"Unknown";
    }
    else
    {
        CFStringRef * keys =     (CFStringRef *)malloc(count * sizeof(CFStringRef *));
        CFStringRef * values =   (CFStringRef *)malloc(count * sizeof(CFStringRef *));

        CFDictionaryGetKeysAndValues(nameDict, (const void **)keys, (const void **)values);
        screenName = [NSString stringWithString:(__bridge NSString *)values[0]];

        free(keys);
        free(values);
    }

    CFRelease(infoDict);
    return screenName;
}

@end
