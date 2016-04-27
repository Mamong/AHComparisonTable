//
//  ComparisonTableViewCell.h
//  AHComparisonTableDemo
//
//  Created by marco on 4/26/16.
//  Copyright © 2016 marco. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CustomScrollView;

@interface ComparisonTableViewCell : UITableViewCell

@property (nonatomic,strong)NSDictionary *data;
@property (nonatomic,assign,readonly,getter=isEqual)BOOL equal;
@property (nonatomic,strong,readonly)UIView *shipView;
@property(nonatomic,strong) NSArray *hiddenIndexes;

- (void)updateData;
@end
