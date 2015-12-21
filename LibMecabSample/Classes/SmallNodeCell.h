//
//  SmallNodeCell.h
//  MecabSample
//
//  Created by Watanabe Toshinori on 10/12/27.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SmallNodeCell : UITableViewCell {

	UILabel *surfaceLabel;
	UILabel *partOfSpeechLabel;
	UILabel *originalFormLabel;
}

@property (nonatomic, retain) IBOutlet UILabel *surfaceLabel;
@property (nonatomic, retain) IBOutlet UILabel *partOfSpeechLabel;
@property (nonatomic, retain) IBOutlet UILabel *originalFormLabel;

@end
