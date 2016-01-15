//
//  EntitySearchTextView.h
//  Guvera
//
//  Created by Mitchell Robertson on 5/01/2016.
//  Copyright © 2016 Guvera Australia Pty Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GVEntityTokenView : UIView

@property (nonatomic,strong) UIButton *button;
@property (nonatomic,strong) UILabel *label;

@end
@class GVEntityTokenTextField;
@protocol EntitySearchTextViewDelegate <NSObject>

@optional

- (void)entitySearchTextView:(GVEntityTokenTextField *)textView searchAsYouTypeTriggeredWithQuery:(NSString *)query;

- (void)entitySearchTextView:(GVEntityTokenTextField *)textView didDeleteEntityView:(GVEntityTokenView *)entityView entityObj:(id)entity internalDelete:(BOOL)internalDelete;
- (void)entitySearchTextView:(GVEntityTokenTextField *)textView didAddEntityView:(GVEntityTokenView *)entityView entityObj:(id)entity;

- (void)entitySearchTextView:(GVEntityTokenTextField *)textView didSelectEntityView:(GVEntityTokenView *)entityView withEntityObj:(id)entity;
- (void)entitySearchTextView:(GVEntityTokenTextField *)textView didUnselectEntityView:(GVEntityTokenView *)entityView withEntityObj:(id)entity;

- (void)entitySearchTextView:(GVEntityTokenTextField *)textView didChangeContentHeight:(CGFloat)newHeight;

- (NSString *)entitySearchTextView:(GVEntityTokenTextField *)textView titleForEntity:(id)entity;

@end
@interface GVEntityTokenTextField : UIView

@property (nonatomic,assign) CGFloat pillHeight;
@property (nonatomic,assign) CGFloat pillRowSpacing;
@property (nonatomic,assign) CGFloat pillSpacing;
@property (nonatomic,assign) CGFloat pillLeftRightPad;
@property (nonatomic,assign) CGFloat verticalFramePad;
@property (nonatomic,assign) CGFloat minimumTextEntryWidth;
@property (nonatomic,strong) NSString *placeholderText;
@property (nonatomic,strong) UIFont *textFieldFont;
@property (nonatomic,strong) UIFont *entityFont;
@property (nonatomic,strong) UIColor *textFieldTextColor;
@property (nonatomic,strong) UIColor *entityBackgroundColor;
@property (nonatomic,strong) UIColor *entitySelectedBackgroundColor;
@property (nonatomic,strong) UIColor *entityTextColor;
@property (nonatomic,strong) UIColor *entitySelectedTextColor;
@property (nonatomic,assign) NSTimeInterval searchAsYouTypeDelaySeconds;

@property (readonly) CGFloat startingFrameHeight;

- (instancetype)initWithDelegate:(id<EntitySearchTextViewDelegate>)delegate;

- (void)addEntity:(id)entityObj;
- (void)removeEntity:(id)entityObj;

@end
