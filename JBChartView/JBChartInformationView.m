//
//  JBChartInformationView.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 11/11/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBChartInformationView.h"

// Numerics
CGFloat const ChartValueViewPadding = 10.0f;
CGFloat const ChartValueViewSeparatorSize = 0.5f;
CGFloat const ChartValueViewTitleHeight = 50.0f;
CGFloat const ChartValueViewTitleWidth = 75.0f;
CGFloat const ChartValueViewDefaultAnimationDuration = 0.25f;

// Colors (JBChartInformationView)
static UIColor *ChartViewSeparatorColor = nil;
static UIColor *ChartViewTitleColor = nil;
static UIColor *ChartViewShadowColor = nil;

// Colors (JBChartInformationView)
static UIColor *ChartInformationViewValueColor = nil;
static UIColor *ChartInformationViewUnitColor = nil;
static UIColor *ChartInformationViewShadowColor = nil;

@interface JBChartValueView : UIView

@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UILabel *unitLabel;

@end

@interface JBChartInformationView ()

@property (nonatomic, strong) JBChartValueView *valueView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *separatorView;

// Position
- (CGRect)valueViewRect;
- (CGRect)titleViewRectForHidden:(BOOL)hidden;
- (CGRect)separatorViewRectForHidden:(BOOL)hidden;

@end

@implementation JBChartInformationView

#pragma mark - Alloc/Init

+ (void)initialize
{
	if (self == [JBChartInformationView class])
	{
		ChartViewSeparatorColor = [UIColor whiteColor];
        ChartViewTitleColor = [UIColor whiteColor];
        ChartViewShadowColor = [UIColor blackColor];
	}
}

- (void)setupWithFrame:(CGRect)frame
{
    self.clipsToBounds = YES;
    
    self.backgroundColor = [UIColor clearColor];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = FontInformationTitle;
    _titleLabel.numberOfLines = 1;
    _titleLabel.adjustsFontSizeToFitWidth = YES;
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textColor = ChartViewTitleColor;
    _titleLabel.shadowColor = ChartViewShadowColor;
    _titleLabel.shadowOffset = CGSizeMake(0, 1);
    _titleLabel.textAlignment = NSTextAlignmentLeft;
    [self addSubview:_titleLabel];
    
    _separatorView = [[UIView alloc] init];
    _separatorView.backgroundColor = ChartViewSeparatorColor;
    [self addSubview:_separatorView];
    
    _valueView = [[JBChartValueView alloc] initWithFrame:[self valueViewRect]];
    [self addSubview:_valueView];
    
    [self setHidden:YES animated:NO];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setupWithFrame:frame];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setupWithFrame:self.frame];
}

#pragma mark - Position

- (CGRect)valueViewRect
{
    CGRect valueRect = CGRectZero;
    valueRect.origin.x = ChartValueViewPadding;
    valueRect.origin.y = ChartValueViewPadding + ChartValueViewTitleHeight;
    valueRect.size.width = self.bounds.size.width - (ChartValueViewPadding * 2);
    valueRect.size.height = self.bounds.size.height - valueRect.origin.y - ChartValueViewPadding;
    return valueRect;
}

- (CGRect)titleViewRectForHidden:(BOOL)hidden
{
    CGRect titleRect = CGRectZero;
    titleRect.origin.x = ChartValueViewPadding;
    titleRect.origin.y = hidden ? -ChartValueViewTitleHeight : ChartValueViewPadding;
    titleRect.size.width = self.bounds.size.width - (ChartValueViewPadding * 2);
    titleRect.size.height = ChartValueViewTitleHeight;
    return titleRect;
}

- (CGRect)separatorViewRectForHidden:(BOOL)hidden
{
    CGRect separatorRect = CGRectZero;
    separatorRect.origin.x = ChartValueViewPadding;
    separatorRect.origin.y = ChartValueViewTitleHeight;
    separatorRect.size.width = self.bounds.size.width - (ChartValueViewPadding * 2);
    separatorRect.size.height = ChartValueViewSeparatorSize;
    if (hidden)
    {
        separatorRect.origin.x -= self.bounds.size.width;
    }
    return separatorRect;
}

#pragma mark - Setters

- (void)setTitleText:(NSString *)titleText
{
    self.titleLabel.text = titleText;
    self.separatorView.hidden = !(titleText != nil);
}

- (void)setValueText:(NSString *)valueText unitText:(NSString *)unitText
{
    self.valueView.valueLabel.text = valueText;
    self.valueView.unitLabel.text = unitText;
    [self.valueView setNeedsLayout];
}

- (void)setTitleTextColor:(UIColor *)titleTextColor
{
    self.titleLabel.textColor = titleTextColor;
    [self.valueView setNeedsDisplay];
}

- (void)setValueAndUnitTextColor:(UIColor *)valueAndUnitColor
{
    self.valueView.valueLabel.textColor = valueAndUnitColor;
    self.valueView.unitLabel.textColor = valueAndUnitColor;
    [self.valueView setNeedsDisplay];
}

- (void)setTextShadowColor:(UIColor *)shadowColor
{
    self.valueView.valueLabel.shadowColor = shadowColor;
    self.valueView.unitLabel.shadowColor = shadowColor;
    self.titleLabel.shadowColor = shadowColor;
    [self.valueView setNeedsDisplay];
}

- (void)setSeparatorColor:(UIColor *)separatorColor
{
    self.separatorView.backgroundColor = separatorColor;
    [self setNeedsDisplay];
}

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (animated)
    {
        if (hidden)
        {
            [UIView animateWithDuration:ChartValueViewDefaultAnimationDuration * 0.5 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                self.titleLabel.alpha = 0.0;
                self.separatorView.alpha = 0.0;
                self.valueView.valueLabel.alpha = 0.0;
                self.valueView.unitLabel.alpha = 0.0;
            } completion:^(BOOL finished) {
                self.titleLabel.frame = [self titleViewRectForHidden:YES];
                self.separatorView.frame = [self separatorViewRectForHidden:YES];
            }];
        }
        else
        {
            [UIView animateWithDuration:ChartValueViewDefaultAnimationDuration delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                self.titleLabel.frame = [self titleViewRectForHidden:NO];
                self.titleLabel.alpha = 1.0;
                self.valueView.valueLabel.alpha = 1.0;
                self.valueView.unitLabel.alpha = 1.0;
                self.separatorView.frame = [self separatorViewRectForHidden:NO];
                self.separatorView.alpha = 1.0;
            } completion:nil];
        }
    }
    else
    {
        self.titleLabel.frame = [self titleViewRectForHidden:hidden];
        self.titleLabel.alpha = hidden ? 0.0 : 1.0;
        self.separatorView.frame = [self separatorViewRectForHidden:hidden];
        self.separatorView.alpha = hidden ? 0.0 : 1.0;
        self.valueView.valueLabel.alpha = hidden ? 0.0 : 1.0;
        self.valueView.unitLabel.alpha = hidden ? 0.0 : 1.0;
    }
}

- (void)setHidden:(BOOL)hidden
{
    [self setHidden:hidden animated:NO];
}

@end

@implementation JBChartValueView

#pragma mark - Alloc/Init

+ (void)initialize
{
	if (self == [JBChartValueView class])
	{
		ChartInformationViewValueColor = [UIColor whiteColor];
        ChartInformationViewUnitColor = [UIColor whiteColor];
        ChartInformationViewShadowColor = [UIColor blackColor];
	}
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _valueLabel = [[UILabel alloc] init];
        _valueLabel.font = FontInformationValue;
        _valueLabel.textColor = ChartInformationViewValueColor;
        _valueLabel.shadowColor = ChartInformationViewShadowColor;
        _valueLabel.shadowOffset = CGSizeMake(0, 1);
        _valueLabel.backgroundColor = [UIColor clearColor];
        _valueLabel.textAlignment = NSTextAlignmentRight;
        _valueLabel.adjustsFontSizeToFitWidth = YES;
        _valueLabel.numberOfLines = 1;
        [self addSubview:_valueLabel];
        
        _unitLabel = [[UILabel alloc] init];
        _unitLabel.font = FontInformationUnit;
        _unitLabel.textColor = ChartInformationViewUnitColor;
        _unitLabel.shadowColor = ChartInformationViewShadowColor;
        _unitLabel.shadowOffset = CGSizeMake(0, 1);
        _unitLabel.backgroundColor = [UIColor clearColor];
        _unitLabel.textAlignment = NSTextAlignmentLeft;
        _unitLabel.adjustsFontSizeToFitWidth = YES;
        _unitLabel.numberOfLines = 1;
        [self addSubview:_unitLabel];
    }
    return self;
}

#pragma mark - Layout

- (void)layoutSubviews
{
    CGSize valueLabelSize = CGSizeZero;
    valueLabelSize = [self.valueLabel.text sizeWithAttributes:@{NSFontAttributeName:self.valueLabel.font}];

    CGSize unitLabelSize = CGSizeZero;
    unitLabelSize = [self.unitLabel.text sizeWithAttributes:@{NSFontAttributeName:self.unitLabel.font}];
    
    CGFloat xOffset = ceil((self.bounds.size.width - (valueLabelSize.width + unitLabelSize.width)) * 0.5);

    self.valueLabel.frame = CGRectMake(xOffset, ceil(self.bounds.size.height * 0.5) - ceil(valueLabelSize.height * 0.5), valueLabelSize.width, valueLabelSize.height);
    self.unitLabel.frame = CGRectMake(CGRectGetMaxX(self.valueLabel.frame), ceil(self.bounds.size.height * 0.5) - ceil(unitLabelSize.height * 0.5) + ChartValueViewPadding + 3, unitLabelSize.width, unitLabelSize.height);
}

@end
