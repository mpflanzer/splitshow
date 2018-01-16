//
//  NSScreen+Name.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 06/05/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import <IOKit/IOKitLib.h>
#import <IOKit/graphics/IOGraphicsLib.h>
#import <ApplicationServices/ApplicationServices.h>
#import <CoreFoundation/CoreFoundation.h>
#import "NSScreen+Name.h"

@implementation NSScreen (Name)

- (CGDirectDisplayID)displayID
{
    return [[self.deviceDescription objectForKey:@"NSScreenNumber"] unsignedIntValue];
}

- (NSString*)name
{
    NSString *displayName = NSLocalizedString(@"Unknown", @"Unknown");

    io_service_t servicePort = IOServicePortFromCGDisplayID(self.displayID);

    if(!servicePort)
    {
        return displayName;
    }

    NSDictionary *displayInfo = CFBridgingRelease(IODisplayCreateInfoDictionary(servicePort, kIODisplayOnlyPreferredName));
    NSDictionary *displayNames = [displayInfo valueForKey:@kDisplayProductName];

    IOObjectRelease(servicePort);

    if(displayNames && displayNames.count > 0)
    {
        NSLocale *userLocale = [NSLocale currentLocale];
        NSLocale *systemLocale = [NSLocale systemLocale];

        NSString *userLocaleIdentifier = userLocale.localeIdentifier;
        NSString *userLocaleLanguage = [userLocale objectForKey:NSLocaleLanguageCode];
        NSString *systemLocaleIdentifier = systemLocale.localeIdentifier;
        NSString *systemLocaleLanguage = [systemLocale objectForKey:NSLocaleLanguageCode];

        // Try display name for user locale
        if(userLocaleIdentifier)
        {
            displayName = [displayNames valueForKey:userLocaleIdentifier];
        }

        // Try display name for system locale
        if(!displayName && systemLocaleIdentifier)
        {
            displayName = [displayNames valueForKey:systemLocaleIdentifier];
        }

        // Try display name for user language
        if(!displayName && userLocaleLanguage)
        {
            for(NSString *key in displayNames)
            {
                if([key containsString:userLocaleLanguage])
                {
                    displayName = [displayNames valueForKey:key];
                    break;
                }
            }
        }

        // Try display name for system language
        if(!displayName && systemLocaleLanguage)
        {
            for(NSString *key in displayNames)
            {
                if([key containsString:systemLocaleLanguage])
                {
                    displayName = [displayNames valueForKey:key];
                    break;
                }
            }
        }

        // Giving up: use first display name that is available
        if(!displayName)
        {
            displayName = [[displayNames allValues] firstObject];
        }
    }

    return displayName;
}

// Returns the io_service_t corresponding to a CG display ID, or 0 on failure.
// The io_service_t should be released with IOObjectRelease when not needed.
static io_service_t IOServicePortFromCGDisplayID(CGDirectDisplayID displayID)
{
    io_iterator_t iter;
    io_service_t serv, servicePort = 0;

    CFMutableDictionaryRef matching = IOServiceMatching(kIODisplayConnect);

    kern_return_t err = IOServiceGetMatchingServices(kIOMasterPortDefault, matching, &iter);

    if(err)
    {
        return 0;
    }

    while((serv = IOIteratorNext(iter)) != 0)
    {
        CFDictionaryRef displayInfo;

        CFNumberRef vendorIDRef;
        CFNumberRef productIDRef;
        CFNumberRef serialNumberRef;

        NSNumber *vendorID;
        NSNumber *productID;
        NSNumber *serialNumber;

        Boolean success;

        displayInfo = IODisplayCreateInfoDictionary(serv, kIODisplayOnlyPreferredName);

        success = CFDictionaryGetValueIfPresent(displayInfo, CFSTR(kDisplayVendorID), (const void**)&vendorIDRef);
        success &= CFDictionaryGetValueIfPresent(displayInfo, CFSTR(kDisplayProductID), (const void**)&productIDRef);

        if(!success)
        {
            CFRelease(displayInfo);
            continue;
        }

        vendorID = (__bridge NSNumber*)vendorIDRef;
        productID = (__bridge NSNumber*)productIDRef;

        if(CFDictionaryGetValueIfPresent(displayInfo, CFSTR(kDisplaySerialNumber), (const void**)&serialNumberRef))
        {
            serialNumber = (__bridge NSNumber*)serialNumberRef;
        }

        if(CGDisplayVendorNumber(displayID) != vendorID.unsignedIntValue ||
           CGDisplayModelNumber(displayID) != productID.unsignedIntValue ||
           CGDisplaySerialNumber(displayID) != serialNumber.unsignedIntValue)
        {
            CFRelease(displayInfo);
            continue;
        }

        servicePort = serv;
        CFRelease(displayInfo);
        break;
    }

    IOObjectRelease(iter);
    return servicePort;
}

+ (NSScreen*)screenWithDisplayID:(CGDirectDisplayID)displayID
{
    for(NSScreen *screen in [NSScreen screens])
    {
        if(screen.displayID == displayID)
        {
            return screen;
        }
    }

    return nil;
}

@end
