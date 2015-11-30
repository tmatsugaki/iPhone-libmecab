//
//  NodeCell.h
//  MecabSample
//
//  Created by Watanabe Toshinori on 10/12/27.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NodeCell : UITableViewCell {

	UILabel *featureLabel;
	UILabel *surfaceLabel;
	UILabel *partOfSpeechLabel;
	UILabel *partOfSpeechSubtype1Label;
	UILabel *partOfSpeechSubtype2Label;
	UILabel *partOfSpeechSubtype3Label;
	UILabel *inflectionLabel;
	UILabel *useOfTypeLabel;
	UILabel *originalFormLabel;
	UILabel *readingLabel;
	UILabel *pronunciationLabel;
}

@property (nonatomic, retain) IBOutlet UILabel *featureLabel;
@property (nonatomic, retain) IBOutlet UILabel *surfaceLabel;
@property (nonatomic, retain) IBOutlet UILabel *partOfSpeechLabel;
@property (nonatomic, retain) IBOutlet UILabel *partOfSpeechSubtype1Label;
@property (nonatomic, retain) IBOutlet UILabel *partOfSpeechSubtype2Label;
@property (nonatomic, retain) IBOutlet UILabel *partOfSpeechSubtype3Label;
@property (nonatomic, retain) IBOutlet UILabel *inflectionLabel;
@property (nonatomic, retain) IBOutlet UILabel *useOfTypeLabel;
@property (nonatomic, retain) IBOutlet UILabel *originalFormLabel;
@property (nonatomic, retain) IBOutlet UILabel *readingLabel;
@property (nonatomic, retain) IBOutlet UILabel *pronunciationLabel;

@end
