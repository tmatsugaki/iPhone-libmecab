//
//  NodeCell.m
//  MecabSample
//
//  Created by Watanabe Toshinori on 10/12/27.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

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
