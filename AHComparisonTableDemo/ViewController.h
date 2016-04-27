//
//  ViewController.h
//  AHComparisonTableDemo
//
//  Created by marco on 4/26/16.
//  Copyright © 2016 marco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property(nonatomic,weak) IBOutlet UITableView *carsTableView;
@property(nonatomic,weak) IBOutlet UIButton *rightScrollIndicatorButton;
@property(nonatomic,weak) IBOutlet UIButton *leftScrollIndicatorButton;


- (IBAction)leftIndicatorButtonTapped:(id)sender;
- (IBAction)rightIndicatorButtonTapped:(id)sender;

@end

