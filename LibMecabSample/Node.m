//
//  Node.m
//
//  Created by Watanabe Toshinori on 10/12/22.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import "Node.h"


@implementation Node

@synthesize surface;
@synthesize feature;
@synthesize features;

- (void)setFeature:(NSString *)value {
	if (feature) {
		[feature release];
	}
	
	if (value) {
		feature = [value retain];
		self.features = [NSMutableArray arrayWithArray:[value componentsSeparatedByString:@","]];
	} else {
		feature = nil;
		self.features = nil;
	}
}

- (NSString *)partOfSpeech {
	if (!features || [features count] < 1) {
		return nil;
	}
	return [features objectAtIndex:0];
}

- (NSString *)partOfSpeechSubtype1 {
	if (!features || [features count] < 2) {
		return nil;
	}
	return [features objectAtIndex:1];
}

- (NSString *)partOfSpeechSubtype2 {
	if (!features || [features count] < 3) {
		return nil;
	}
	return [features objectAtIndex:2];
}

- (NSString *)partOfSpeechSubtype3 {
	if (!features || [features count] < 4) {
		return nil;
	}
	return [features objectAtIndex:3];
}

- (NSString *)inflection {
	if (!features || [features count] < 5) {
		return nil;
	}
	return [features objectAtIndex:4];
}

- (NSString *)useOfType {
	if (!features || [features count] < 6) {
		return nil;
	}
	return [features objectAtIndex:5];
}

- (NSString *)originalForm {
	if (!features || [features count] < 7) {
		return nil;
	}
	return [features objectAtIndex:6];
}

- (NSString *)reading {
	if (!features || [features count] < 8) {
		return nil;
	}
	return [features objectAtIndex:7];
}

- (NSString *)pronunciation {
	if (!features || [features count] < 9) {
		return nil;
	}
	return [features objectAtIndex:8];
}

- (void)setPartOfSpeech:(NSString *)value {
    if (!features || [features count] < 1) {
        return;
    }
    [features replaceObjectAtIndex:0 withObject:value];
}

- (void)setPartOfSpeechSubtype1:(NSString *)value {
    if (!features || [features count] < 2) {
        return;
    }
    [features replaceObjectAtIndex:1 withObject:value];
}

- (void)setPartOfSpeechSubtype2:(NSString *)value {
    if (!features || [features count] < 3) {
        return;
    }
    [features replaceObjectAtIndex:2 withObject:value];
}

- (void)setPartOfSpeechSubtype3:(NSString *)value {
    if (!features || [features count] < 4) {
        return;
    }
    [features replaceObjectAtIndex:3 withObject:value];
}

- (void)setInflection:(NSString *)value {
    if (!features || [features count] < 5) {
        return;
    }
    [features replaceObjectAtIndex:4 withObject:value];
}

- (void)setUseOfType:(NSString *)value {
    if (!features || [features count] < 6) {
        return;
    }
    [features replaceObjectAtIndex:5 withObject:value];
}

- (void)setOriginalForm:(NSString *)value {
    if (!features || [features count] < 7) {
        return;
    }
    [features replaceObjectAtIndex:6 withObject:value];
}

- (void)setReading:(NSString *)value {
    if (!features || [features count] < 8) {
        return;
    }
    [features replaceObjectAtIndex:7 withObject:value];
}

- (void)setPronunciation:(NSString *)value {
    if (!features || [features count] < 9) {
        return;
    }
    [features replaceObjectAtIndex:8 withObject:value];
}

- (void)dealloc {
	self.surface = nil;
	self.feature = nil;
    self.features = nil;
    self.attribute = nil;

	[super dealloc];
}

@end
