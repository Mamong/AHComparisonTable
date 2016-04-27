//
//  ViewController.m
//  AHComparisonTableDemo
//
//  Created by marco on 4/26/16.
//  Copyright © 2016 marco. All rights reserved.
//

#import "ViewController.h"
#import "ComparisonTableViewCell.h"

#import "Constants.h"

CGFloat const gestureMinimumTranslation = 0.0;// not used

// gesture displacement ratio
static float factor = 0.5;


typedef enum :NSInteger {
    kScrollDirectionNone,
    kScrollDirectionUp,
    kScrollDirectionDown,
    kScrollDirectionRight,
    kScrollDirectionLeft
} AHScrollDirection;


@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate>

// to perform scroll animation
@property(nonatomic,weak)IBOutlet UIView *headerShipView;

// hold header data
@property(nonatomic,strong)NSMutableArray *headerNames;

// hold original data
@property(nonatomic,strong)NSArray *originParameters;

// the data tableview dispaly
@property(nonatomic,strong)NSArray *parameters;

// Indicate current tableview display mode, show all parameters or filtered data.
@property(nonatomic,assign)BOOL filter;

// trace current offset pan gesture performs. Multiply it by factor, you will get the true
// table view cell offset.
@property(nonatomic,assign)CGFloat currentOffset;

// just record current pan gesture direction
@property(nonatomic,assign) AHScrollDirection direction;

// record the indexes of those cars deleted, deal with data directly is not a good idea.
// keepping those indexes to delete in mind will make more sense.
@property(nonatomic,strong) NSMutableArray *hiddenIndexes;
@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    /*
     There is a dirty work, steps as below:
     1.read json file directly
     2.get car name from paramitems
     3.delete car name from paramitems
     4.join paramitems and configitems
     5.finally, store original data
     
     ***data source:http://223.99.255.20/cars.app.autohome.com.cn/cfg_v5.6.0/cars/speccompare.ashx?pl=1&type=1&specids=23451,22029&cityid=110100***
     */
    
    NSString *jsonPath = [[NSBundle mainBundle]pathForResource:@"ahCarsData" ofType:@"json"];
    NSData *jsonData = [[NSData alloc]initWithContentsOfFile:jsonPath options:0 error:nil];
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    NSDictionary *result = dictionary[@"result"];
    NSArray *parameters = result[@"paramitems"];
    NSArray *configitems = result[@"configitems"];
    NSMutableArray *allParameters = [NSMutableArray arrayWithArray:parameters];
    NSMutableArray *firstParameter = [NSMutableArray arrayWithArray:[[allParameters firstObject]objectForKey:@"items"]];
    NSDictionary *nameDict = [firstParameter firstObject];
    _headerNames = [NSMutableArray array];
    for (NSDictionary *modelexcessid in nameDict[@"modelexcessids"]) {
        [_headerNames addObject:modelexcessid[@"value"]];
    }

    [firstParameter removeObjectAtIndex:0];
    NSMutableDictionary *firstParameterFiltered = [NSMutableDictionary dictionaryWithDictionary:[allParameters firstObject]];
    [firstParameterFiltered setObject:firstParameter forKey:@"items"];
    [allParameters replaceObjectAtIndex:0 withObject:firstParameterFiltered];
    [allParameters addObjectsFromArray:configitems];
    self.originParameters = allParameters;
    self.parameters = allParameters;
    
    [self.carsTableView registerClass:[ComparisonTableViewCell class] forCellReuseIdentifier:@"cell"];
    self.carsTableView.bounces = NO;
    
    _filter = NO;
    _hiddenIndexes = [NSMutableArray arrayWithCapacity:0];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc]initWithTitle:@"隐藏相同项" style:UIBarButtonItemStylePlain target:self action:@selector(filterBarbuttonTapped:)];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    //手势共存，上下滚动tableview和左右滑动
    UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(handlePanGesture:)];
    gestureRecognizer.delegate = self;
    [self.carsTableView addGestureRecognizer:gestureRecognizer];
    
    [self.carsTableView reloadData];
    [self setupTopHeaderView];
    self.title = @"车型对比";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -Views
- (void)setupTopHeaderView
{
    // at least 4 column in a cell and header view
    int column = [_headerNames count]+1>4?:4;

    for (int i = 0; i<column; i++) {
        UILabel *label = [[UILabel alloc]initWithFrame:
                          CGRectMake(i*kCarItemWidth, 0, kCarItemWidth, kCarNameHeight)];
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:12];
        label.lineBreakMode = NSLineBreakByCharWrapping;
        label.userInteractionEnabled = YES;
        if (i<[_headerNames count]) {
            // car column
            label.text = [_headerNames objectAtIndex:i];
            [_headerShipView addSubview:label];
            
            // it seems not a good idea put button directly on label, for buttons will disappear when label's
            // text is overlayed. So just add it directly on ship view.
            CGRect frame = [label convertRect:CGRectMake(kCarItemWidth-22, 0, 22, 22) toView:_headerShipView];
            UIButton *button = [[UIButton alloc]initWithFrame:frame];
            [button setTitle:@"X" forState:UIControlStateNormal];
            button.backgroundColor = [UIColor redColor];
            button.tag = i;
            [button addTarget:self action:@selector(carItemDeleteButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [_headerShipView addSubview:button];

        }else if (i == [_headerNames count])
        {
            // add column
            label.text = @"+";
            [_headerShipView addSubview:label];
        }
        else{
            //blank column
            label.text = @"NAN";
            [_headerShipView addSubview:label];
        }
        label.backgroundColor = [UIColor whiteColor];
    }
}

- (void)updateTopHeaderView
{
    for (UIView *v in _headerShipView.subviews) {
        [v removeFromSuperview];
    }
    [self setupTopHeaderView];
}


#pragma mark -Button methods
- (void)filterBarbuttonTapped:(id)sender
{
    _filter = !_filter;
    if (_filter) {
        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc]
                                      initWithTitle:@"显示全部"
                                      style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(filterBarbuttonTapped:)];
        self.navigationItem.rightBarButtonItem = rightItem;
        self.parameters = [self filteredParameters];
    }else{
        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc]
                                      initWithTitle:@"隐藏相同项"
                                      style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(filterBarbuttonTapped:)];
        self.navigationItem.rightBarButtonItem = rightItem;
        self.parameters = self.originParameters;
    }
    [self.carsTableView reloadData];
}

- (void)carItemDeleteButtonTapped:(id)sender
{
    UIButton *button = (UIButton*)sender;
    NSInteger index = button.tag;
    [self.hiddenIndexes addObject:[NSString stringWithFormat:@"%ld",(long)index]];
    
    // update header name data
    [self.headerNames removeObjectAtIndex:index];
    
    // update header view
    [self updateTopHeaderView];
    
    // update filter button, when only one car or less, hide the filter button
    if ([self.headerNames count]<2) {
        self.navigationItem.rightBarButtonItem = nil;
        if (_filter) {
            _filter = NO;
            self.parameters = self.originParameters;
        }
    }
    
    // update cars table view
    [self.carsTableView reloadData];
}

- (IBAction)leftIndicatorButtonTapped:(id)sender
{
    _currentOffset = 0;
    [self updateTableViewCellLayout];
}

- (IBAction)rightIndicatorButtonTapped:(id)sender
{
    int column = [_headerNames count]+1>4?:4;
    CGFloat maxOffsetX = (-self.carsTableView.frame.size.width
                          + column*kCarItemWidth + kParameterHeaderWidth)/factor;
    _currentOffset = maxOffsetX;
    [self updateTableViewCellLayout];
}


#pragma mark -help methods
- (NSArray*)filteredParameters
{
    NSMutableArray *filtedArray = [NSMutableArray array];
    for (NSDictionary *sectionParaItem in _originParameters) {
        NSArray *items = [sectionParaItem objectForKey:@"items"];
        NSMutableArray *filtedItems = [NSMutableArray array];
        for (NSDictionary *paraItem in items) {
            NSArray *modelexcessids = paraItem[@"modelexcessids"];
            NSMutableArray *values = [NSMutableArray array];
            for (NSDictionary *item in modelexcessids) {
                [values addObject:[item objectForKey:@"value"]];
            }
            //判断值是否相等
            NSSet *set = [NSSet setWithArray:values];
            BOOL equal = [set count]==1;
            if (!equal) {
                [filtedItems addObject:paraItem];
            }
        }
        NSMutableDictionary *filtedSectionParaItem = [NSMutableDictionary dictionaryWithDictionary:sectionParaItem];
        [filtedSectionParaItem setObject:filtedItems forKey:@"items"];
        if ([filtedItems count]>0) {
            [filtedArray addObject:filtedSectionParaItem];
        }
    }
    return filtedArray;
}

- (AHScrollDirection)determineScrollDirectionIfNeeded:(CGPoint)translation
{
    if (_direction != kScrollDirectionNone)
        return _direction;
    // determine if horizontal swipe only if you meet some minimum velocity
    if (fabs(translation.x) > gestureMinimumTranslation)
    {
        BOOL gestureHorizontal = NO;
        if (translation.y ==0.0)
            gestureHorizontal = YES;
        else
            gestureHorizontal = (fabs(translation.x / translation.y) >5.0);
        if (gestureHorizontal)
        {
            if (translation.x >0.0)
                return kScrollDirectionRight;
            else
                return kScrollDirectionLeft;
        }
    }
    // determine if vertical swipe only if you meet some minimum velocity
    else if (fabs(translation.y) > gestureMinimumTranslation)
    {
        BOOL gestureVertical = NO;
        if (translation.x == 0.0)
            gestureVertical = YES;
        else
            gestureVertical = (fabs(translation.y / translation.x) >5.0);
        if (gestureVertical)
        {
            if (translation.y >0.0)
                return kScrollDirectionDown;
            else
                return kScrollDirectionUp;
        }
    }
    return _direction;
}


#pragma mark -UITableView Delegate and DataSource methods
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count =  [_parameters count];
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = [[[_parameters objectAtIndex:section]objectForKey:@"items"]count];
    return count;
}

//- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    NSString *title =  [[_parameters objectAtIndex:section]objectForKey:@"itemtype"];
//    return title;
//}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *backgroundView = [[UIView alloc]initWithFrame:
                              CGRectMake(0, 0, tableView.bounds.size.width, 20)];
    backgroundView.backgroundColor = [UIColor lightGrayColor];
    
    UILabel *leftLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, 100, 20)];
    leftLabel.font = [UIFont systemFontOfSize:12];
    NSString *title =  [[_parameters objectAtIndex:section]objectForKey:@"itemtype"];
    leftLabel.text = title;
    [backgroundView addSubview:leftLabel];
    
    UILabel *rightLabel = [[UILabel alloc]initWithFrame:
                           CGRectMake(tableView.bounds.size.width-120, 0, 100, 20)];
    rightLabel.font = [UIFont systemFontOfSize:12];
    rightLabel.text = @"◉标配 ◎选配 -无";
    [backgroundView addSubview:rightLabel];

    return backgroundView;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ComparisonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"
                                                                    forIndexPath:indexPath];
    NSDictionary *model = [[[_parameters objectAtIndex:indexPath.section]objectForKey:@"items"]objectAtIndex:indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.data = model;
    cell.hiddenIndexes = [self.hiddenIndexes copy];
    [cell updateData];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(nonnull ComparisonTableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    // re-layout cell when display
    CGRect boundsT = cell.shipView.bounds;
    boundsT.origin.x = _currentOffset*0.5;
    cell.shipView.bounds = boundsT;
}

#pragma mark -UIPangestureRecognizer
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer.view isKindOfClass:[UITableView class]]) {
        return YES;
    }
    return NO;
}

- (void)handlePanGesture:(UIPanGestureRecognizer*)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            _direction = kScrollDirectionNone;
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [gesture translationInView:gesture.view];
            CGFloat translationX = translation.x;
            [gesture setTranslation:CGPointZero
                             inView: gesture.view];
             _direction = [self determineScrollDirectionIfNeeded:translation];
            if (_direction == kScrollDirectionLeft||
                _direction == kScrollDirectionRight) {
                // it's important to update currentoffset only when scroll direction is horizontal.
                _currentOffset -= translationX;
                [self updateTableViewCellLayout];
            }
        }
            break;
        default:
            //_currentOffset = 0;
            break;
    }
}

/*
 Here is just a tricky to use bounds to animate the column on the cell.
 
 */
- (void) updateTableViewCellLayout {
    for (UICollectionViewCell *cell in self.carsTableView.visibleCells) {
        ComparisonTableViewCell *tableViewCell =  (ComparisonTableViewCell*)cell;
        
        int column = [_headerNames count]+1>4?:4;
        CGFloat maxOffsetX = (-self.carsTableView.frame.size.width
                              + column*kCarItemWidth + kParameterHeaderWidth)/factor;
        _currentOffset = fmax(_currentOffset, 0.f);
        _currentOffset = fminf(_currentOffset, maxOffsetX);
        
        CGRect boundsT = tableViewCell.shipView.bounds;
        boundsT.origin.x = _currentOffset*factor;
        tableViewCell.shipView.bounds = boundsT;
        
        CGRect boundsH = self.headerShipView.bounds;
        boundsH.origin.x = _currentOffset*factor;
        self.headerShipView.bounds = boundsH;
        
        if (_currentOffset == 0.f) {
            self.leftScrollIndicatorButton.hidden = YES;
            self.rightScrollIndicatorButton.hidden = NO;
        }else if (_currentOffset == maxOffsetX){
            self.rightScrollIndicatorButton.hidden = YES;
            self.leftScrollIndicatorButton.hidden = NO;
        }else{
            self.leftScrollIndicatorButton.hidden = NO;
            self.rightScrollIndicatorButton.hidden = NO;
        }
    }
}
@end
