//
//  DisplayController.m
//  SplitShow
//
//  Created by Moritz Pflanzer on 27/12/2015.
//  Copyright © 2015-2016 Moritz Pflanzer. All rights reserved.
//

#import "DisplayController.h"

#import "PresentationController.h"
#import "SlideView.h"

#import <Quartz/Quartz.h>

@interface DisplayController ()

@property (readonly) PDFView *pdfView;

- (void)initView;

@end

@implementation DisplayController

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super init];

    if(self)
    {
        self.view = [[SlideView alloc] initWithFrame:frame];

        [self initView];
    }

    return self;
}

- (void)bindToPresentationController:(PresentationController *)controller
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateView:) name:kSplitShowNotificationChangeSlide object:controller];
}

- (void)unbind
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (PDFView *)pdfView
{
    return (PDFView*)self.view;
}

- (void)initView
{
    [self.pdfView setBackgroundColor:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0]];
    self.pdfView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.pdfView setDisplayMode:kPDFDisplaySinglePage];
    [self.pdfView setDisplaysPageBreaks:NO];
    [self.pdfView setAutoScales:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initView];
}

- (PDFDocument *)document
{
    return self.pdfView.document;
}

- (void)setDocument:(PDFDocument *)document
{
    self.pdfView.document = document;
}

- (void)updateView:(NSNotification *)notification
{
    if([kSplitShowNotificationChangeSlide isEqualToString:notification.name])
    {
        SplitShowChangeSlideAction action = [[notification.userInfo objectForKey:kSplitShowNotificationChangeSlideAction] unsignedIntegerValue];

        switch(action)
        {
            case SplitShowChangeSlideActionRestart:
                [self.pdfView goToFirstPage:notification.object];
                break;

            case SplitShowChangeSlideActionPrevious:
                [self.pdfView goToPreviousPage:notification.object];
                break;

            case SplitShowChangeSlideActionNext:
                [self.pdfView goToNextPage:notification.object];
                break;

            case SplitShowChangeSlideActionGoTo:
            {
                NSUInteger index = [[notification.userInfo objectForKey:kSplitShowChangeSlideActionGoToIndex] unsignedIntegerValue];
                [self.pdfView goToPageAtIndex:index];
                break;
            }
        }
    }
}

@end
