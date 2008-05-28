/*
 * Copyright (c) 2008 Christophe Tournery, Gunnar Schaefer
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

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
