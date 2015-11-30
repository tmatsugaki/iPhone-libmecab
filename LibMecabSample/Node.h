//
//  Node.h
//
//  Created by Watanabe Toshinori on 10/12/22.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface Node : NSObject {
	
	NSString *surface;
	NSString *feature;

	NSMutableArray *features;
	NSString *attribute;
	BOOL visible;
}

@property (nonatomic, retain) NSString *surface;
@property (nonatomic, retain) NSString *feature;
@property (nonatomic, retain) NSMutableArray *features;

@property (nonatomic, retain) NSString *attribute;      // 将来のバージョンで対話によってパースの補助させる際に使う文字列（今のところ、Reserved）
@property (nonatomic, assign) BOOL visible;             // パッチの結果で非表示にするセルを示すフラグ

// 品詞
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
	
- (void)setPartOfSpeech:(NSString *)value;
- (void)setPartOfSpeechSubtype1:(NSString *)value;
- (void)setPartOfSpeechSubtype2:(NSString *)value;
- (void)setPartOfSpeechSubtype3:(NSString *)value;
- (void)setInflection:(NSString *)value;
- (void)setUseOfType:(NSString *)value;
- (void)setOriginalForm:(NSString *)value;
- (void)setReading:(NSString *)value;
- (void)setPronunciation:(NSString *)value;
@end
