//
//  PreviewWindowController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import <Cocoa/Cocoa.h>
#import "PreviewController.h"
#import "BeamerDocument.h"

@interface PreviewWindowController : NSWindowController

@property BeamerDocument *presentation;

- (BOOL)readFromURL:(NSURL*)file error:(NSError*__autoreleasing *)error;

@end
