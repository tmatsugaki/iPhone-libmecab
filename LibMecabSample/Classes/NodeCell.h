//
//  NodeCell.h
//  MecabSample
//
//  Created by tmatsugaki on 2015/11/24.
//

#import <UIKit/UIKit.h>


@interface NodeCell : UITableViewCell {

    /*
     - (NSString *)partOfSpeech;
     // 品詞細分類1
     - (NSString *)partOfSpeechSubtype1;
     // 品詞細分類2
     - (NSString *)partOfSpeechSubtype2;
     // 品詞細分類3
     - (NSString *)partOfSpeechSubtype3;
     // 活用形
     - (NSString *)inflection;
     // 活用型
     - (NSString *)useOfType;
     // 原形
     - (NSString *)originalForm;
     // 読み
     - (NSString *)reading;
     // 発音
     - (NSString *)pronunciation;
     */
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
