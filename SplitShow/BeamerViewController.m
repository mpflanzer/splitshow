//
//  BeamerViewController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 06/05/2015.
//
//

#import "BeamerViewController.h"

@interface BeamerViewController ()

@end

@implementation BeamerViewController

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super init];

    if(self)
    {
        self.group = -1;
        self.beamerView = [[BeamerView alloc] initWithFrame:frame];
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

        NSNumber *pageIndex = notification.userInfo[@"pageIndex"];

        if(self.beamerView.document)
        {
            PDFPage *page = [self.beamerView.document pageAtIndex:pageIndex.unsignedIntegerValue];
            [self.beamerView goToPage:page];
        }
    }
}

- (void)setDocument:(PDFDocument *)document
{
    [self.beamerView setDocument:document];
}

@end
