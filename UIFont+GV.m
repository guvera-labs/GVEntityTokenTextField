//
//  UIFont+GV.m
//  GuveraCore
//
//  Created by Mitchell Robertson on 17/07/2014.
//  Copyright (c) 2014 Guvera. All rights reserved.
//

#import "UIFont+GV.h"

@implementation UIFont (GV)

- (float)gv_heightForFontWithText:(NSString *)text maxWidth:(float)width
{
    if (text == nil){
        return 0.0;
    }
    return [[[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:self}] boundingRectWithSize:CGSizeMake(width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.height;
}

- (float)gv_heightForFontWithText:(NSString *)text
{
    return [self gv_heightForFontWithText:text maxWidth:MAXFLOAT];
}

- (float)gv_heightForFont
{
    return [self gv_heightForFontWithText:@"}|yaGA" maxWidth:MAXFLOAT];
}

- (float)gv_widthForFontWithText:(NSString *)text
{
    if(!text)
        return 0;
    
    return [[[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:self}] boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.width;
}

@end

@implementation UILabel (GV)

- (CGFloat)gv_widthForContent
{
    return [self.font gv_widthForFontWithText:self.text];
}

- (CGFloat)gv_heightForContent
{
    return [self.font gv_heightForFontWithText:self.text];
}

- (CGFloat)gv_heightConstrainedToWidth:(CGFloat)maxWidth
{
    return [self.font gv_heightForFontWithText:self.text maxWidth:maxWidth];
}

@end
