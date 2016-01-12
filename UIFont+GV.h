//
//  UIFont+GV.h
//  GuveraCore
//
//  Created by Mitchell Robertson on 17/07/2014.
//  Copyright (c) 2014 Guvera. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIFont (GV)

- (float)gv_heightForFontWithText:(NSString *)text maxWidth:(float)width;
- (float)gv_heightForFontWithText:(NSString *)text;
- (float)gv_heightForFont;
- (float)gv_widthForFontWithText:(NSString *)text;

@end

@interface UILabel (GV)

- (CGFloat)gv_heightConstrainedToWidth:(CGFloat)maxWidth;
- (CGFloat)gv_widthForContent;
- (CGFloat)gv_heightForContent;

@end
