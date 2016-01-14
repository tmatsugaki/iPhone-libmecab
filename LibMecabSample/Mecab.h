//
//  Mecab.h
//
//  Created by Watanabe Toshinori on 10/12/22.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

// static library などを含むアプリのシッピング用アーカイブ作成手順
// *****************************************************************************
// 1.Release タグで Skip Install=YES
// 2.Copy Headers で mecab のヘッダーを従来の public から project にする。
// 3.上に付帯してラッパーがオリジナルのパスを見失うのでワールドサーチにして相対パスでアサインする。
// *****************************************************************************
#include <mecab.h>
//#include "../mecab/mecab.h"
#import <UIKit/UIKit.h>


@interface Mecab : NSObject {
	mecab_t *mecab;
}

- (NSArray *)parseToNodeWithString:(NSString *)string;

@end
