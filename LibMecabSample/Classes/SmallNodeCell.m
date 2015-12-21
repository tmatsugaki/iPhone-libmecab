//
//  SmallNodeCell.m
//  MecabSample
//
//  Created by Watanabe Toshinori on 10/12/27.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import "SmallNodeCell.h"


@implementation SmallNodeCell

@synthesize surfaceLabel;
@synthesize partOfSpeechLabel;
@synthesize originalFormLabel;

- (void)dealloc {

    self.surfaceLabel = nil;
    self.partOfSpeechLabel = nil;
    self.originalFormLabel = nil;

    [super dealloc];
}


@end
