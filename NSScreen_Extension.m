//
//  Screen.m
//  PDFPresenter
//
//  Created by Christophe Tournery on 16/04/2008.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <IOKit/IOKitLib.h>
#import <IOKit/graphics/IOGraphicsLib.h>
#import <ApplicationServices/ApplicationServices.h>
#import <CoreFoundation/CoreFoundation.h>
#import "NSScreen_Extension.h"


@implementation NSScreen (SSExtension)

- (NSString *)name
{
    io_service_t        displayPort;
    CFIndex             count;
    NSString            * screenName =  nil;
    CFDictionaryRef     infoDict =      NULL;
    CFDictionaryRef     nameDict =      NULL;

    displayPort =   CGDisplayIOServicePort([self displayID]);

	if (displayPort == MACH_PORT_NULL)
		return [NSString stringWithString:@"Unknown"];

	infoDict =      IODisplayCreateInfoDictionary(displayPort, kIODisplayOnlyPreferredName);
	nameDict =      CFDictionaryGetValue(infoDict, CFSTR(kDisplayProductName));
    count =         CFDictionaryGetCount(nameDict);
    
    if (count == 0)
    {
        screenName = [NSString stringWithString:@"Unknown"];
    }
    else
    {
        CFStringRef * keys =     (CFStringRef *)malloc(count * sizeof(CFStringRef *));
        CFStringRef * values =   (CFStringRef *)malloc(count * sizeof(CFStringRef *));
        
        CFDictionaryGetKeysAndValues(nameDict, (const void **)keys, (const void **)values);
        screenName = [NSString stringWithString:(NSString *)values[0]];
        
        free(keys);
        free(values);
    }

    CFRelease(infoDict);
    return screenName;
}

- (CGDirectDisplayID)displayID
{
    return [[[self deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
}

+ (NSScreen *)screenWithNumber:(int)number
{
    NSArray * screens = [NSScreen screens];
    for (id screen in screens)
		if ([[[screen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue] == number)
			return screen;
	return nil;
}

+ (void)builtin:(NSMutableArray *)builtinScreens AndExternalScreens:(NSMutableArray *)externalScreens
{
    NSArray * screens = [NSScreen screens];
    for (id screen in screens)
    {
        if (CGDisplayIsBuiltin([screen displayID]))
            if (builtinScreens != nil)
                [builtinScreens addObject:screen];
        else
            if (externalScreens != nil)
                [externalScreens addObject:screen];
    }
}

@end
