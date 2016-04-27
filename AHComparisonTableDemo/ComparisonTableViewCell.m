//
//  ComparisonTableViewCell.m
//  AHComparisonTableDemo
//
//  Created by marco on 4/26/16.
//  Copyright © 2016 marco. All rights reserved.
//

#import "ComparisonTableViewCell.h"

#import "Constants.h"

@interface ComparisonTableViewCell()
@property (nonatomic,strong)UILabel *nameLabel;

@property (nonatomic,assign,getter=isEqual)BOOL equal;
@property (nonatomic,copy)NSString *name;
@property (nonatomic,strong)NSMutableArray *values;

@end;

@implementation ComparisonTableViewCell

// for register via class
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self initial];
    }
    return self;
}

// for register via nib
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self initial];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

//- (void)prepareForReuse
//{
//    [super prepareForReuse];
//    CGRect bounds = _shipView.bounds;
//    bounds.origin.x = 0;
//    _shipView.bounds = bounds;
//}

- (void)initial
{
    _equal = YES;
    _values = [NSMutableArray arrayWithCapacity:4];
    
    _shipView = [[UIView alloc]initWithFrame:CGRectMake(kParameterHeaderWidth, 0, 400, kParameterHeaderHeight)];
    _shipView.backgroundColor = [UIColor clearColor];
    [self addSubview:_shipView];

    _nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, kParameterHeaderWidth, kParameterHeaderHeight)];
    _nameLabel.numberOfLines = 0;
    _nameLabel.lineBreakMode = NSLineBreakByCharWrapping;
    _nameLabel.textAlignment = NSTextAlignmentCenter;
    _nameLabel.font = [UIFont systemFontOfSize:12];
    _nameLabel.backgroundColor = [UIColor whiteColor];
    [self addSubview:_nameLabel];
}

- (void)updateData
{
    [_values removeAllObjects];
    if (self.data) {
        _name = self.data[@"name"];
        
        NSArray *modelexcessids = self.data[@"modelexcessids"];
        for (NSDictionary *item in modelexcessids) {
            [_values addObject:[item objectForKey:@"value"]];
        }
        if ([self.hiddenIndexes count]>0) {
            for (NSString *index in self.hiddenIndexes) {
                [_values removeObjectAtIndex:[index integerValue]];
            }
        }
        //判断值是否相等
        NSSet *set = [NSSet setWithArray:_values];
        _equal = [set count]==1;
    }
    [self updateUI];
}

- (void)updateUI
{
    [self removeAllValueLabels];
    int column = [_values count]+1>4?:4;
    for (int i = 0; i<column; i++) {
        UILabel *label = [[UILabel alloc]initWithFrame:
                          CGRectMake(i*kCarItemWidth, 0, kCarItemWidth, kParameterHeaderHeight)];
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:12];
        label.lineBreakMode = NSLineBreakByCharWrapping;
        if (i<[_values count]) {
            //car column
            label.text = [_values objectAtIndex:i];
            label.backgroundColor = _equal?[UIColor whiteColor]:[UIColor blueColor];
        }else{
            //blank column
            label.text = @"NAN";
            label.backgroundColor = [UIColor whiteColor];
        }
        [_shipView addSubview:label];
    }
    self.nameLabel.text = self.name;
}

- (void)removeAllValueLabels
{
    for (UILabel *label in _shipView.subviews) {
        [label removeFromSuperview];
    }
}

@end
