//
//  BeamerViewController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 06/05/2015.
//
//

#import "BeamerViewController.h"

@interface BeamerViewController ()

@property PDFDocument *document;

@end

@implementation BeamerViewController

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super init];

    if(self)
    {
        self.group = -1;
        self.document = [[PDFDocument alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"empty" withExtension:@"pdf"]];
        self.beamerView = [[BeamerView alloc] initWithFrame:frame];
        [self.beamerView setDocument:self.document];
    }

    return self;
}

- (void)registerController:(SplitShowController *)controller
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeView:) name:nil object:controller];
}

- (void)unregisterController:(SplitShowController *)controller
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:controller];
}

- (void)changeView:(NSNotification *)notification
{
    if([BeamerViewControllerNotificationChangeSlide isEqualToString:notification.name])
    {
        NSNumber *group = notification.userInfo[@"group"];

        // Do not handle if not same group or for all
        if(group.integerValue != BeamerViewControllerNotificationGroupAll && group.integerValue != self.group)
        {
            return;
        }

        PDFPage *slide = notification.userInfo[@"slide"];

        if(slide != nil)
        {
            [self.document removePageAtIndex:0];
            [self.document insertPage:[slide copy] atIndex:0];
            [self.beamerView layoutDocumentView];
        }
    }
}

@end
