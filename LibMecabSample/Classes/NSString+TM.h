//
//  NSString+TM.h
//  Houyouban
//
//  Created by matsu on 2014/01/19.
//  Copyright (c) 2014年 Rikki Systems Inc. All rights reserved.
//

@interface NSString (TM)

+ (NSString *) commaString:(NSNumber *)number;

- (BOOL) writeToFile:(NSString *)path;
- (BOOL) safeWriteToFile:(NSString *)path atomically:(BOOL)flag;
- (NSString *) replaceString:(NSString *)keyword withString:(NSString *)replacement;
- (NSString *) replacedString:(NSString *)whichString withString:(NSString *)withString;
- (BOOL) isCellPhoneNumber;
- (BOOL) isPhoneNumber;
- (BOOL) isMailAddress;
- (NSString *) normalizePhoneNumber;
- (BOOL) isHankakuString;
- (BOOL) isZenkakuString;

// 半角→全角
- (NSString *) stringToFullwidth;
// 全角→半角
- (NSString *) stringToHalfwidth;
// カタカナ→ひらがな
- (NSString *) stringKatakanaToHiragana;
// ひらがな→カタカナ
- (NSString *) stringHiraganaToKatakana;
// ひらがな→ローマ字
- (NSString *) stringHiraganaToLatin;
// ローマ字→ひらがな
- (NSString *) stringLatinToHiragana;
// カタカナ→ローマ字
- (NSString *) stringKatakanaToLatin;
// ローマ字→カタカナ
- (NSString *) stringLatinToKatakana;
@end
