//
//  JBChartTooltipView.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 3/12/14.
//  Copyright (c) 2014 Jawbone. All rights reserved.
//

#import "JBChartTooltipView.h"

// Drawing
#import <QuartzCore/QuartzCore.h>

// Numerics
CGFloat static const ChartTooltipViewCornerRadius = 5.0;
CGFloat const ChartTooltipViewDefaultWidth = 50.0f;
CGFloat const ChartTooltipViewDefaultHeight = 25.0f;

@interface JBChartTooltipView ()

@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation JBChartTooltipView

#pragma mark - Alloc/Init

- (id)init
{
    self = [super initWithFrame:CGRectMake(0, 0, ChartTooltipViewDefaultWidth, ChartTooltipViewDefaultHeight)];
    if (self)
    {
        self.backgroundColor = ColorTooltipColor;
        self.layer.cornerRadius = ChartTooltipViewCornerRadius;
        
        _textLabel = [[UILabel alloc] init];
        _textLabel.font = FontTooltipText;
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.textColor = ColorTooltipTextColor;
        _textLabel.adjustsFontSizeToFitWidth = YES;
        _textLabel.numberOfLines = 1;
        _textLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_textLabel];
    }
    return self;
}

#pragma mark - Setters

- (void)setText:(NSString *)text
{
    self.textLabel.text = text;
    [self setNeedsLayout];
}

- (void)setTooltipColor:(UIColor *)tooltipColor
{
    self.backgroundColor = tooltipColor;
    [self setNeedsDisplay];
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    _textLabel.frame = self.bounds;
}

@end
