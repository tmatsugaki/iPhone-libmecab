//
//  TokenCell.m
//  MecabSample
//
//  Created by Watanabe Toshinori on 10/12/22.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import "TokenCell.h"


@implementation TokenCell

- (id) initWithStyle:(UITableViewCellStyle)style
     reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self != nil) {
        [self setClearsContextBeforeDrawing:YES];
        [self setAutoresizesSubviews:YES];
        
        self.opaque = YES;
        self.contentView.opaque = YES;
        // ハイライトカラーを設定する。
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        // 【セルの背景②】iOS7 でセル自身（ビュー）の背景が白になっているので、補正する。
        self.backgroundColor = [UIColor clearColor];
        // 【セルのコンテントの背景③ 】コンテントの背景色を設定する。（セルの背景は iOS7 より前は透明だった）
        self.contentView.backgroundColor = [UIColor clearColor];
        self.textLabel.adjustsFontSizeToFitWidth = YES;
        self.textLabel.minimumScaleFactor = 0.5;
    }
    return self;
}
@end
