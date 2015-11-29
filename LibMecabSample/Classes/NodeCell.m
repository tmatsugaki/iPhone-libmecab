//
//  NodeCell.m
//  MecabSample
//
//  Created by Watanabe Toshinori on 10/12/22.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import "NodeCell.h"


@implementation NodeCell

@synthesize featureLabel;
@synthesize surfaceLabel;
@synthesize partOfSpeechLabel;


- (void)dealloc {
	self.featureLabel = nil;
    self.surfaceLabel = nil;
    self.partOfSpeechLabel = nil;
    [super dealloc];
}


@end
