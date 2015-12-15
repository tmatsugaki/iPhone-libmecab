//
//  Utility.h
//  LibMecabSample
//
//  Created by matsu on 2015/12/15.
//
//

#import <Foundation/Foundation.h>

@interface Utility : NSObject

+ (BOOL) keyboardShowAnimation:(UIView *)view keyboardRect:(CGRect)keyboardRect duration:(NSTimeInterval)duration;
+ (void) keyboardHideAnimation:(UIView *)view keyboardRect:(CGRect)keyboardRect duration:(NSTimeInterval)duration;
@end
