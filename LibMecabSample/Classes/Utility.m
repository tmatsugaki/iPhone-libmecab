//
//  Utility.m
//  LibMecabSample
//
//  Created by matsu on 2015/12/15.
//
//

#import "Utility.h"

@implementation Utility

#pragma mark - UIKeyboard用ツール

// 【注意】ローテーションで width/height を入れ替えること！！
+ (CGFloat) keyboardHeight:(CGRect)keyboardRect {
    
    CGFloat height;
    
    //    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    switch ((int) orientation) {
        case UIDeviceOrientationLandscapeRight:     // 90度
        case UIDeviceOrientationLandscapeLeft:      // 270度
            height = keyboardRect.size.width;
            break;
        case UIDeviceOrientationPortrait:           // 0度
        case UIDeviceOrientationPortraitUpsideDown: // 180度
        default:
            height = keyboardRect.size.height;
            break;
    }
    return height;
}

+ (void) ViewHeightChangeAnimation:(UIView *)view
                             delta:(CGFloat)delta
                          duration:(NSTimeInterval)duration {
    
    CGRect frame = view.frame;
    
    frame.size.height += delta;
    [UIView animateWithDuration:duration
                     animations:^{
                         [view setFrame:frame];
                     }
                     completion:^(BOOL finished) {
                     }];
}

/*******************************************************************************
 * 基本的にキーボードは遠くから来て、遠くに去って行く！！
 * ビューの管理はキーボードレクタングルに頼るのではなく、ビューのバウンダリを自前できちんと管理すること。
 *******************************************************************************/
// キーボードを表示する余地がない場合は、キーボードを表示しない。
// キーボード表示の可否は、ビューにキーボードを表示後も44ピクセルの余地の有無で決める。
+ (BOOL) keyboardShowAnimation:(UIView *)view
                  keyboardRect:(CGRect)keyboardRect
                      duration:(NSTimeInterval)duration {
    
    CGFloat viewHeight = view.bounds.size.height;
    CGFloat keyboardHeight = [Utility keyboardHeight:keyboardRect];
    BOOL result = NO;
    
    if (viewHeight > keyboardHeight)
    {
        [Utility ViewHeightChangeAnimation:view
                                     delta:-keyboardHeight
                                  duration:duration];
        result = YES;
    } else {
#ifdef DEBUG
        NSAssert(viewHeight > keyboardHeight, @"キーボード出せない！！");
#endif
    }
    return result;
}

+ (void) keyboardHideAnimation:(UIView *)view
                  keyboardRect:(CGRect)keyboardRect
                      duration:(NSTimeInterval)duration {
    
    [Utility ViewHeightChangeAnimation:view
                                 delta:[Utility keyboardHeight:keyboardRect]
                              duration:duration];
}

@end
