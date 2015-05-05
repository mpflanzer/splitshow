//
//  ViewController.h
//  SplitShow
//
//  Created by Moritz Pflanzer on 05/05/2015.
//
//

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger
{
    BeamerPresentationLayoutInterleaved,
    BeamerPresentationLayoutMirror,
    BeamerPresentationLayoutSplit,
} BeamerPresentationLayout;

@interface PreviewController : NSViewController

@end

