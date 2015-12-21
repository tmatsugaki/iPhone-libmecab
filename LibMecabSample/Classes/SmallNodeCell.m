//
//  SmallNodeCell.m
//  MecabSample
//
//  Created by Watanabe Toshinori on 10/12/27.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import "definitions.h"
#import "SmallNodeCell.h"

@implementation SmallNodeCell

@synthesize surfaceLabel;
@synthesize partOfSpeechLabel;
@synthesize originalFormLabel;
@synthesize delegate;

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

    switch ((int) event.type) {
        case UIEventTypeTouches:
            [UIMenuController sharedMenuController].menuItems = nil;
            break;
    }
    [super touchesBegan:touches withEvent:event];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    switch ((int) event.type) {
        case UIEventTypeTouches:
            switch ([[touches anyObject] tapCount]) {
                case 1:
                    [self performSelector:@selector(singleTapAction:)
                               withObject:touches
                               afterDelay:kDoubleTapDetectPeriod];
                    break;
                case 2:
                    [NSObject cancelPreviousPerformRequestsWithTarget:self];
                    //
                    [self doubleTapAction:nil];
                    break;
            }
            break;
    }
    [super touchesEnded:touches withEvent:event];
}

- (void) singleTapAction:(id) sender {
    
    [delegate toggleCellSize:self];
}

- (void) doubleTapAction:(id) sender {
    
//    [delegate toggleCellSize:self];
}

- (void)dealloc {

    self.surfaceLabel = nil;
    self.partOfSpeechLabel = nil;
    self.originalFormLabel = nil;
    self.delegate = nil;

    [super dealloc];
}
@end
