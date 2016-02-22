//
//  EntitySearchTextView.m
//  Guvera
//
//  Created by Mitchell Robertson on 5/01/2016.
//  Copyright © 2016 Guvera Australia Pty Ltd. All rights reserved.
//

#import "GVEntityTokenTextField.h"
#import "UIFont+GV.h"

@class BackspaceDetectTextField;

@protocol BackspaceDetectTextFieldDeleate <NSObject>

- (void)textFieldDidBackspaceOnEmpty:(BackspaceDetectTextField*)textField;
@end
@interface BackspaceDetectTextField : UITextField<UIKeyInput>

@property (nonatomic,assign) id<BackspaceDetectTextFieldDeleate> backspaceDelegate;
@property (nonatomic,assign) BOOL hideCursor;

@end

@implementation BackspaceDetectTextField

- (void)deleteBackward
{
    [super deleteBackward];
    
    if ([self.text length] == 0)
        [self.backspaceDelegate textFieldDidBackspaceOnEmpty:self];
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    if (self.hideCursor) {
        return CGRectZero;
    }
    return [super caretRectForPosition:position];;
}

- (void)setHideCursor:(BOOL)hideCursor
{
    _hideCursor = hideCursor;
    
    [self layoutIfNeeded];
}

@end
@protocol GVEntityTokenViewProtocol <NSObject>

- (NSString *)titleForEntity:(id)entityObj entityTokenTextView:(GVEntityTokenView *)tokenView;
- (void)resolvedEntityViewWasTapped:(GVEntityTokenView *)entityView;

@end
@interface GVEntityTokenView ()

@property (nonatomic,strong) id obj;
@property (nonatomic,weak) id<GVEntityTokenViewProtocol> delegate;

- (instancetype)initWithObj:(id)entityObj delegate:(id<GVEntityTokenViewProtocol>)delegate itemNumber:(NSInteger)itemNumber;

@end
@implementation GVEntityTokenView

- (instancetype)initWithObj:(id)entityObj delegate:(id<GVEntityTokenViewProtocol>)delegate itemNumber:(NSInteger)itemNumber
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        
        self.tag = itemNumber;
        
        self.obj = entityObj;
        self.delegate = delegate;
        
        self.label = [[UILabel alloc] init];
        [self addSubview:self.label];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.text = [self.delegate titleForEntity:entityObj entityTokenTextView:self];
    
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        [self addSubview:self.button];
        [self.button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        self.clipsToBounds = YES;
        self.layer.cornerRadius = 3.;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.label.frame = self.bounds;
    self.button.frame = self.bounds;
}

- (CGSize)intrinsicContentSize
{
    CGFloat widthForContent = [self.label gv_widthForContent];
    return CGSizeMake(widthForContent,[self.label.font gv_heightForFont]);
}

- (void)buttonTapped:(id)sender
{
    [self.delegate resolvedEntityViewWasTapped:self];
}

@end


@interface GVEntityTokenTextField()<UITextFieldDelegate,GVEntityTokenViewProtocol,BackspaceDetectTextFieldDeleate>

@property (nonatomic,strong) id<EntitySearchTextViewDelegate> delegate;

@property (nonatomic,strong) UIButton *showKeyboardButton;
@property (nonatomic,strong) BackspaceDetectTextField *textField;
@property (nonatomic,strong) NSTimer *searchTimer;
@property (nonatomic,strong) NSString *currentQuery;

@property (nonatomic,strong) UIScrollView *resolvedEntitiesScroll;
@property (nonatomic,strong) NSMutableArray *resolvedEntityViews;
@property (nonatomic,strong) NSMutableArray *resolvedEntities;

@property (nonatomic,strong) GVEntityTokenView *selectedEntity;

@end
@implementation GVEntityTokenTextField

@synthesize textFieldFont=_textFieldFont;
@synthesize textFieldCursorColor=_textFieldCursorColor;
@synthesize textFieldTextColor=_textFieldTextColor;

- (instancetype)initWithDelegate:(id<EntitySearchTextViewDelegate>)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        
        self.resolvedEntitiesScroll = [[UIScrollView alloc] init];
        [self addSubview:self.resolvedEntitiesScroll];
        self.resolvedEntitiesScroll.showsHorizontalScrollIndicator = YES;
        
        self.showKeyboardButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.resolvedEntitiesScroll addSubview:self.showKeyboardButton];
        [self.showKeyboardButton addTarget:self action:@selector(showKeyboardButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
        self.textField = [[BackspaceDetectTextField alloc] init];
        [self.resolvedEntitiesScroll addSubview:self.textField];
        self.textField.backspaceDelegate = self;
        self.textField.font = self.textFieldFont;
        self.textField.tintColor = self.textFieldCursorColor;
        self.textField.textColor = self.textFieldTextColor;
        self.textField.clearButtonMode = UITextFieldViewModeNever;
        self.textField.delegate = self;
        self.textField.returnKeyType = UIReturnKeyDone;
        
        self.resolvedEntities = [[NSMutableArray alloc] init];
        self.resolvedEntityViews = [[NSMutableArray alloc] init];
        
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.showKeyboardButton.frame = self.bounds;
    self.resolvedEntitiesScroll.frame = self.bounds;
    
    [self layoutResolvedEntitiesAndTextField];
}

- (void)timerDidFire
{
    [self.searchTimer invalidate];
    
    if ([self.currentQuery length] > 0)
        if ([self.delegate respondsToSelector:@selector(entitySearchTextView:searchAsYouTypeTriggeredWithQuery:)])
            [self.delegate entitySearchTextView:self searchAsYouTypeTriggeredWithQuery:self.currentQuery];
}

- (void)addEntity:(id)entityObj
{
    [self.resolvedEntities addObject:entityObj];
    
    GVEntityTokenView *newView = [[GVEntityTokenView alloc] initWithObj:entityObj delegate:self itemNumber:[self.resolvedEntities count]-1];
    newView.label.font = self.entityFont;
    newView.label.textColor = self.entityTextColor;
    newView.backgroundColor = self.entityBackgroundColor;
    
    [self.resolvedEntityViews addObject:newView];
    
    [self layoutResolvedEntitiesAndTextFieldAnimated:YES];
    
    if ([self.delegate respondsToSelector:@selector(entitySearchTextView:didAddEntityView:entityObj:)])
        [self.delegate entitySearchTextView:self didAddEntityView:newView entityObj:entityObj];
}

- (void)removeEntity:(id)entityObj
{
    NSInteger removeIndex = [self.resolvedEntities indexOfObject:entityObj];
    if (removeIndex != NSNotFound){
        [self.resolvedEntities removeObjectAtIndex:removeIndex];
        GVEntityTokenView *removedEntityView = [self.resolvedEntityViews objectAtIndex:removeIndex];
        [removedEntityView removeFromSuperview];
        [self.resolvedEntityViews removeObjectAtIndex:removeIndex];
        
        if (entityObj == self.selectedEntity)
            self.selectedEntity = nil;
        
        if ([self.delegate respondsToSelector:@selector(entitySearchTextView:didDeleteEntityView:entityObj:internalDelete:)])
            [self.delegate entitySearchTextView:self didDeleteEntityView:removedEntityView entityObj:entityObj internalDelete:NO];
        
        [self layoutResolvedEntitiesAndTextFieldAnimated:NO];
    }
}

- (void)removeAllEntities
{
    [self.resolvedEntities removeAllObjects];
    
    for (GVEntityTokenView *tokenView in self.resolvedEntityViews){
        [tokenView removeFromSuperview];
    }
    [self.resolvedEntityViews removeAllObjects];
    [self layoutResolvedEntitiesAndTextFieldAnimated:YES];
    
    self.selectedEntity = nil;
}

- (void)deselectSelectedEntity
{
    if (self.selectedEntity) {
        [self resolvedEntityViewWasTapped:self.selectedEntity];
    }
}

- (void)showKeyboardButtonPressed:(id)sender
{
    [self bringSubviewToFront:self.textField];
    self.textField.hidden = NO;
    self.textField.alpha = 1;
    
    [self.textField becomeFirstResponder];
    
    [self deselectSelectedEntity];
    
    [self scrollToBottomAnimated:YES];
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
    CGFloat yOffset = self.resolvedEntitiesScroll.contentSize.height - self.resolvedEntitiesScroll.bounds.size.height;
    if (yOffset < 0)
        yOffset = 0;
    
    CGPoint bottomOffset = CGPointMake(0, yOffset);
    [self.resolvedEntitiesScroll setContentOffset:bottomOffset animated:animated];
}

#pragma mark - frame layout code

- (void)layoutResolvedEntitiesAndTextField
{
    NSString *queryTextBefore = self.textField.text;
    self.textField.text = @"";
    
    if ([queryTextBefore length] > 0 && [self.delegate respondsToSelector:@selector(entitySearchTextViewDidClearSearchText:)]) {
        [self.delegate entitySearchTextViewDidClearSearchText:self];
    }
    
    __block UIView *lastView = nil;
    
    [self iterateThroughViewsWithFrameInfo:^(GVEntityTokenView *view, CGFloat viewX, CGFloat viewY, CGFloat viewWidth) {
        if (view.superview == nil){
            [self.resolvedEntitiesScroll addSubview:view];
        }
        
        view.frame = CGRectMake(viewX, viewY, viewWidth, self.pillHeight);
        lastView = view;
    }];
    
    CGFloat yExtent = 0;
    if (lastView){
        
        CGFloat textX = CGRectGetMaxX(lastView.frame)+2;
        CGFloat textY = CGRectGetMinY(lastView.frame);
        CGFloat textWidth = CGRectGetWidth(self.frame)-textX;
        if (textWidth < self.minimumTextEntryWidth){
            textX = 0;
            textY = CGRectGetMaxY(lastView.frame)+self.pillRowSpacing;
            textWidth = CGRectGetWidth(self.frame)-textX;
        }
        self.textField.frame = CGRectMake(textX, textY, textWidth, self.pillHeight);
        self.textField.placeholder = @"";
        yExtent = CGRectGetMaxY(self.textField.frame)+self.verticalFramePad;
        
    } else {
        self.textField.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), self.verticalFramePad+self.pillHeight+self.verticalFramePad);
        self.textField.placeholder = self.placeholderText;
        yExtent = CGRectGetMaxY(self.textField.frame);
    }
    
    self.resolvedEntitiesScroll.contentSize = CGSizeMake(CGRectGetWidth(self.frame),yExtent);
}

- (void)layoutResolvedEntitiesAndTextFieldAnimated:(BOOL)animated
{
    CGFloat oldContentSize = self.resolvedEntitiesScroll.contentSize.height;
    [self layoutResolvedEntitiesAndTextField];
    
    if (oldContentSize != self.resolvedEntitiesScroll.contentSize.height)
        if ([self.delegate respondsToSelector:@selector(entitySearchTextView:didChangeContentHeight:)])
            [self.delegate entitySearchTextView:self didChangeContentHeight:self.resolvedEntitiesScroll.contentSize.height];
    
    if (animated)
        [self scrollToBottomAnimated:NO];
}

- (CGSize)intrinsicContentSize
{
    __block UIView *lastView = nil;
    [self iterateThroughViewsWithFrameInfo:^(GVEntityTokenView *view, CGFloat viewX, CGFloat viewY, CGFloat viewWidth) {
        lastView = view;
    }];
    
    CGFloat textX = CGRectGetMaxX(lastView.frame)+2;
    CGFloat textY = CGRectGetMinY(lastView.frame);
    CGFloat textWidth = CGRectGetWidth(self.frame)-textX;
    if (textWidth < self.minimumTextEntryWidth){
        textX = 0;
        textY = CGRectGetMaxY(lastView.frame)+self.pillRowSpacing;
        textWidth = CGRectGetWidth(self.frame)-textX;
    }
    
    return CGSizeMake(CGRectGetWidth(self.frame), textY+self.pillSpacing);
}

- (void)iterateThroughViewsWithFrameInfo:(void (^)(GVEntityTokenView *view, CGFloat viewX, CGFloat viewY, CGFloat viewWidth))frameBlock
{
    CGFloat lastPillX = 0;
    CGFloat lastPillY = 0;
    CGSize lastPillIntrinisic;
    BOOL first = YES;
    
    int index = 0;
    for (GVEntityTokenView *entityView in self.resolvedEntityViews){
        CGFloat xForPill = !first ? lastPillX+lastPillIntrinisic.width+self.pillSpacing : 0;
        CGFloat yForPill = !first ? lastPillY : self.verticalFramePad;
        CGSize pillSize = [entityView intrinsicContentSize];
        
        first = NO;
        
        if (xForPill+pillSize.width > CGRectGetWidth(self.frame)){
            // wrap to another line
            xForPill = 0;
            yForPill += self.pillHeight+self.pillRowSpacing;
        }
        
        pillSize.width += (self.pillLeftRightPad * 2);
        
        NSLog(@"index = %@, width = %@",@(index),@(pillSize.width));
        
        frameBlock(entityView,xForPill,yForPill,pillSize.width);
        
        lastPillX = xForPill;
        lastPillY = yForPill;
        lastPillIntrinisic = pillSize;
        
        index++;
    }
}

- (NSString *)currentSearchQuery
{
    return self.textField.text;
}

#pragma mark - layout and other settings

- (CGFloat)startingFrameHeight
{
    return self.pillHeight+(self.verticalFramePad*2);
}

- (CGFloat)pillHeight
{
    if (_pillHeight <= 0)
        return 30;
    return _pillHeight;
}

- (CGFloat)pillRowSpacing
{
    if (_pillRowSpacing <= 0)
        return 5;
    return _pillRowSpacing;
}

- (CGFloat)minimumTextEntryWidth
{
    if (_minimumTextEntryWidth <= 0)
        return 44;
    return _minimumTextEntryWidth;
}

- (CGFloat)pillSpacing
{
    if (_pillSpacing <= 0)
        return 4;
    return _pillSpacing;
}

- (CGFloat)pillLeftRightPad
{
    if (_pillLeftRightPad <= 0)
        return 7;
    return _pillLeftRightPad;
}

- (CGFloat)verticalFramePad
{
    if (_verticalFramePad <= 0)
        return 10;
    return _verticalFramePad;
}

- (NSTimeInterval)searchAsYouTypeDelaySeconds
{
    if (_searchAsYouTypeDelaySeconds <= 0)
        return .3;
    return _searchAsYouTypeDelaySeconds;
}

- (void)setPlaceholderText:(NSString *)placeholderText
{
    _placeholderText = placeholderText;
    
    if ([self.resolvedEntities count] > 0)
        self.textField.placeholder = _placeholderText;
}

- (void)setTextFieldFont:(UIFont *)textFieldFont
{
    _textFieldFont = textFieldFont;
    self.textField.font = textFieldFont;
    
    [self layoutResolvedEntitiesAndTextField];
}

- (void)setTextFieldCursorColor:(UIColor *)textFieldCursorColor
{
    _textFieldCursorColor = textFieldCursorColor;
    self.textField.tintColor = textFieldCursorColor;
}

- (void)setTextFieldTextColor:(UIColor *)textFieldTextColor
{
    _textFieldTextColor = textFieldTextColor;
    self.textField.textColor = textFieldTextColor;
}

- (UIFont *)textFieldFont
{
    if (_textFieldFont == nil)
        return [UIFont systemFontOfSize:13];
    return _textFieldFont;
}

- (UIFont *)entityFont
{
    if (_entityFont == nil)
        return [UIFont systemFontOfSize:13];
    return _entityFont;
}

- (UIColor *)textFieldTextColor
{
    if (_textFieldTextColor == nil)
        return [UIColor blackColor];
    return _textFieldTextColor;
}

- (UIColor *)textFieldCursorColor
{
    if (_textFieldCursorColor == nil)
        return [UIColor grayColor];
    return _textFieldCursorColor;
}

- (UIColor *)entityBackgroundColor
{
    if (_entityBackgroundColor == nil)
        return [UIColor grayColor];
    return _entityBackgroundColor;
}

- (UIColor *)entitySelectedBackgroundColor
{
    if (_entitySelectedBackgroundColor == nil)
        return [UIColor redColor];
    return _entitySelectedBackgroundColor;
}

- (UIColor *)entityTextColor
{
    if (_entityTextColor == nil)
        return [UIColor whiteColor];
    return _entityTextColor;
}

- (UIColor *)entitySelectedTextColor
{
    if (_entitySelectedTextColor == nil)
        return [UIColor whiteColor];
    return _entitySelectedTextColor;
}

- (void)setSelectedState:(BOOL)selected onEntityView:(GVEntityTokenView *)entityView
{
    if (selected){
        entityView.backgroundColor = self.entitySelectedBackgroundColor;
        entityView.label.textColor = self.entitySelectedTextColor;
    } else {
        entityView.backgroundColor = self.entityBackgroundColor;
        entityView.label.textColor = self.entityTextColor;
    }
}

#pragma mark - ResolvedEntityViewProtocol

- (NSString *)titleForEntity:(id)entityObj entityTokenTextView:(GVEntityTokenView *)tokenView
{
    if ([self.delegate respondsToSelector:@selector(entitySearchTextView:titleForEntity:itemNumber:)])
        return [self.delegate entitySearchTextView:self titleForEntity:entityObj itemNumber:tokenView.tag];
    return [entityObj stringValue];
}

- (void)resolvedEntityViewWasTapped:(GVEntityTokenView *)entityView
{
    if (self.selectedEntity == nil || self.selectedEntity != entityView){
        [self setSelectedState:YES onEntityView:entityView];
        
        if ([self.delegate respondsToSelector:@selector(entitySearchTextView:didSelectEntityView:withEntityObj:)])
            [self.delegate entitySearchTextView:self didSelectEntityView:entityView withEntityObj:entityView.obj];
        
        if (self.selectedEntity){
            [self setSelectedState:NO onEntityView:self.selectedEntity];
            
            if ([self.delegate respondsToSelector:@selector(entitySearchTextView:didUnselectEntityView:withEntityObj:)])
                [self.delegate entitySearchTextView:self didUnselectEntityView:self.selectedEntity withEntityObj:self.selectedEntity.obj];
        }
        
        self.selectedEntity = entityView;
    } else if (self.selectedEntity == entityView){
        [self setSelectedState:NO onEntityView:entityView];

        if ([self.delegate respondsToSelector:@selector(entitySearchTextView:didUnselectEntityView:withEntityObj:)])
            [self.delegate entitySearchTextView:self didUnselectEntityView:self.selectedEntity withEntityObj:self.selectedEntity.obj];
        
        self.selectedEntity = nil;
    }
}

- (void)setSelectedEntity:(GVEntityTokenView *)selectedEntity
{
    _selectedEntity = selectedEntity;
    
    if (_selectedEntity) {
        // hide text field
        self.textField.alpha = 0;
        [self bringSubviewToFront:self.showKeyboardButton];
    } else {
        // show text field
        self.textField.alpha = 1;
        [self bringSubviewToFront:self.textField];
    }
}

#pragma mark - BackspaceDetectTextFieldDeleate

- (void)textFieldDidBackspaceOnEmpty:(BackspaceDetectTextField *)textField
{
    [self scrollToBottomAnimated:YES];
    
    if (self.selectedEntity){
        NSInteger index = [self.resolvedEntities indexOfObject:self.selectedEntity.obj];
        if (index != NSNotFound){
            [self.resolvedEntities removeObjectAtIndex:index];
            GVEntityTokenView *viewToRemove = [self.resolvedEntityViews objectAtIndex:index];
            [self.resolvedEntityViews removeObjectAtIndex:index];
            [viewToRemove removeFromSuperview];
            
            if ([self.delegate respondsToSelector:@selector(entitySearchTextView:didDeleteEntityView:entityObj:internalDelete:)])
                [self.delegate entitySearchTextView:self didDeleteEntityView:viewToRemove entityObj:viewToRemove.obj internalDelete:YES];
            
            self.selectedEntity = nil;
            
            [self layoutResolvedEntitiesAndTextFieldAnimated:YES];
        } else {
            self.selectedEntity = nil;
        }
    } else {
        // if none selected, select the last
        if ([self.resolvedEntityViews count] > 0){
            self.selectedEntity = [self.resolvedEntityViews lastObject];
            
            [self setSelectedState:YES onEntityView:self.selectedEntity];
            
            if ([self.delegate respondsToSelector:@selector(entitySearchTextView:didSelectEntityView:withEntityObj:)])
                [self.delegate entitySearchTextView:self didSelectEntityView:self.selectedEntity withEntityObj:self.selectedEntity.obj];
        }
    }
}

- (void)resignFirstResponder {
    
    [self.textField resignFirstResponder];
}

#pragma mark - UITextFieldDelegates

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    if ([self.delegate respondsToSelector:@selector(entitySearchTextViewDidBeginEditing:)]) {
        
        [self.delegate entitySearchTextViewDidBeginEditing:self];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if ([self.delegate respondsToSelector:@selector(entitySearchTextViewDidEndEditing:)]) {
        
        [self.delegate entitySearchTextViewDidEndEditing:self];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (self.selectedEntity != nil)
        return NO;
    
    NSString * currentValue = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    [self.searchTimer invalidate];
    self.currentQuery = currentValue;
    
    if ([currentValue length] == 0 && [self.delegate respondsToSelector:@selector(entitySearchTextViewDidClearSearchText:)]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.delegate entitySearchTextViewDidClearSearchText:self];
        });
    } else if ([self.delegate respondsToSelector:@selector(entitySearchTextView:searchAsYouTypeTriggeredWithQuery:)]){
        self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:self.searchAsYouTypeDelaySeconds target:self selector:@selector(timerDidFire) userInfo:nil repeats:NO];
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (self.selectedEntity) {
        [self resolvedEntityViewWasTapped:self.selectedEntity];
    }
    
    [textField resignFirstResponder];
    return YES;
}

@end
