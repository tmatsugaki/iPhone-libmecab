//
//  NodeCell.m
//  MecabSample
//
//  Created by tmatsugaki on 2015/11/24.
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
