//
//  NodeCell.m
//  MecabSample
//
//  Created by Watanabe Toshinori on 10/12/27.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import "definitions.h"
#import "NodeCell.h"


@implementation NodeCell

@synthesize featureLabel;
@synthesize surfaceLabel;
@synthesize partOfSpeechLabel;
@synthesize partOfSpeechSubtype1Label;
@synthesize partOfSpeechSubtype2Label;
@synthesize partOfSpeechSubtype3Label;
@synthesize inflectionLabel;
@synthesize useOfTypeLabel;
@synthesize originalFormLabel;
@synthesize readingLabel;
@synthesize pronunciationLabel;
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
    
    [delegate showWikiPage:self];
}

- (void)dealloc {
    self.featureLabel = nil;
    self.surfaceLabel = nil;
    self.partOfSpeechLabel = nil;
    self.partOfSpeechSubtype1Label = nil;
    self.partOfSpeechSubtype2Label = nil;
    self.partOfSpeechSubtype3Label = nil;
    self.inflectionLabel = nil;
    self.surfaceLabel = nil;
    self.useOfTypeLabel = nil;
    self.originalFormLabel = nil;
    self.readingLabel = nil;
    self.pronunciationLabel = nil;
    [super dealloc];
}


@end
