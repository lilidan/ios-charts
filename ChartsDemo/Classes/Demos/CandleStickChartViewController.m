//
//  CandleStickChartViewController.m
//  ChartsDemo
//
//  Created by Daniel Cohen Gindi on 17/3/15.
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/ios-charts
//

#import "CandleStickChartViewController.h"
#import <Charts/Charts.h>
#import "ChartsDemo-Swift.h"

@interface CandleStickChartViewController () <ChartViewDelegate>

@property (nonatomic, strong) IBOutlet CombinedChartView *chartView;
@property (nonatomic, strong) IBOutlet UISlider *sliderX;
@property (nonatomic, strong) IBOutlet UISlider *sliderY;
@property (nonatomic, strong) IBOutlet UITextField *sliderTextX;
@property (nonatomic, strong) IBOutlet UITextField *sliderTextY;
@property (weak, nonatomic) IBOutlet BarChartView *barChartView;

@end

@implementation CandleStickChartViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Candle Stick Chart";
    
    
    
    
    
    self.options = @[
                     @{@"key": @"toggleValues", @"label": @"Toggle Values"},
                     @{@"key": @"toggleHighlight", @"label": @"Toggle Highlight"},
                     @{@"key": @"toggleStartZero", @"label": @"Toggle StartZero"},
                     @{@"key": @"animateX", @"label": @"Animate X"},
                     @{@"key": @"animateY", @"label": @"Animate Y"},
                     @{@"key": @"animateXY", @"label": @"Animate XY"},
                     @{@"key": @"saveToGallery", @"label": @"Save to Camera Roll"},
                     @{@"key": @"togglePinchZoom", @"label": @"Toggle PinchZoom"},
                     @{@"key": @"toggleAutoScaleMinMax", @"label": @"Toggle auto scale min/max"},
                     @{@"key": @"toggleShadowColorSameAsCandle", @"label": @"Toggle shadow same color"},
                     ];
    
    _chartView.delegate = self;
    _chartView.descriptionText = @"";
    _chartView.noDataTextDescription = @"";

    _chartView.maxVisibleValueCount = 60;
    _chartView.pinchZoomEnabled = NO;
    _chartView.drawGridBackgroundEnabled = NO;
    _chartView.dragEnabled = NO;
    _chartView.doubleTapToZoomEnabled = NO;
    
    ChartXAxis *xAxis = _chartView.xAxis;
    xAxis.labelPosition = XAxisLabelPositionBottom;
    xAxis.spaceBetweenLabels = 2.0;
    xAxis.drawGridLinesEnabled = NO;
    xAxis.enabled = NO;
    
    ChartYAxis *leftAxis = _chartView.leftAxis;
    leftAxis.labelCount = 7;
    leftAxis.drawGridLinesEnabled = NO;
    leftAxis.drawAxisLineEnabled = NO;
    leftAxis.startAtZeroEnabled = NO;
    leftAxis.enabled = NO;
    ChartYAxis *rightAxis = _chartView.rightAxis;
    rightAxis.enabled = NO;
    _chartView.legend.enabled = NO;
    
    _barChartView.legend.enabled = NO;
    _barChartView.delegate = self;
    _barChartView.leftAxis.enabled = NO;
    _barChartView.rightAxis.enabled = NO;
    _barChartView.xAxis.enabled = NO;
    _barChartView.descriptionText = @"";
    _barChartView.noDataTextDescription = @"";
    _barChartView.maxVisibleValueCount = 60;
    _barChartView.pinchZoomEnabled = NO;
    _barChartView.drawGridBackgroundEnabled = NO;
    _barChartView.dragEnabled = NO;
    _barChartView.doubleTapToZoomEnabled = NO;
    
    _sliderX.value = 39.0;
    _sliderY.value = 100.0;
    
    [self slidersValueChanged:nil];
    [_chartView animateWithXAxisDuration:0.7 yAxisDuration:0 easingOption:ChartEasingOptionEaseOutCubic];
    [_barChartView animateWithXAxisDuration:0 yAxisDuration:0.7 easingOption:ChartEasingOptionEaseOutCubic];
}

-(LineChartDataSet *)generateLineDataSet:(NSMutableArray *)yVals withColor:(UIColor *)color
{
        LineChartDataSet *set = [[LineChartDataSet alloc] initWithYVals:yVals label:@"DataSet"];
        set.drawCubicEnabled = YES;
        set.cubicIntensity = 0.2;
        set.drawCirclesEnabled = NO;
        set.lineWidth = 1.0;
        set.highlightColor = [UIColor colorWithRed:244/255.f green:117/255.f blue:117/255.f alpha:1.f];
        [set setColor:[UIColor colorWithRed:104/255.f green:241/255.f blue:175/255.f alpha:1.f]];
        [set setColor:color];
        set.fillColor = [UIColor colorWithRed:51/255.f green:181/255.f blue:229/255.f alpha:1.f];
    return set;
}


- (void)setDataCount:(int)count range:(double)range
{
    NSError *error;
    NSData *jsonData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle]
                                                       pathForResource: @"kLine" ofType: @"txt"]];
    NSDictionary *json = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    NSArray *kLineArray = (NSArray *)[json objectForKey:@"hq.kx2"];
    
    NSMutableArray *xVals = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < count; i++)
    {
        NSDictionary * candleData = (NSDictionary *)kLineArray[i];
        [xVals addObject:candleData[@"da"]];
    }
    
    NSMutableArray *yVals1 = [[NSMutableArray alloc] init];
    
    NSMutableArray *yVals2 = [[NSMutableArray alloc] init];
    NSMutableArray *yVals3 = [[NSMutableArray alloc] init];
    NSMutableArray *yVals4 = [[NSMutableArray alloc] init];
    
    NSMutableArray *yVals5 = [[NSMutableArray alloc] init];
    for (int i = 0; i < count; i++)
    {
        NSDictionary * candleData = (NSDictionary *)kLineArray[i];
        NSDictionary * tomorrowData = (NSDictionary *)kLineArray[i+1];
        
        double high = [(NSString *)candleData[@"zgcj"] doubleValue];
        double low = [(NSString *)candleData[@"zdcj"] doubleValue];
        double open = [(NSString *)candleData[@"jrkp"] doubleValue];
        double close = [(NSString *)tomorrowData[@"zrsp"] doubleValue];

        [yVals1 addObject:[[CandleChartDataEntry alloc] initWithXIndex:i shadowH:high shadowL:low open:open close:close]];
        
        double val2 = [(NSString *)candleData[@"MA1"] doubleValue];
        double val3 = [(NSString *)candleData[@"MA2"] doubleValue];
        double val4 = [(NSString *)candleData[@"MA3"] doubleValue];
        [yVals2 addObject:[[ChartDataEntry alloc] initWithValue:val2 xIndex:i]];
        [yVals3 addObject:[[ChartDataEntry alloc] initWithValue:val3 xIndex:i]];
        [yVals4 addObject:[[ChartDataEntry alloc] initWithValue:val4 xIndex:i]];
        
        
        double val5 = [(NSString *)candleData[@"avol"] doubleValue];
        [yVals5 addObject:[[BarChartDataEntry alloc] initWithValue:val5 xIndex:i]];
    }
    
    CombinedChartData *data =  [[CombinedChartData alloc] initWithXVals:xVals];
    
    NSMutableArray *datasets = [[NSMutableArray alloc]init];
    [datasets addObject:[self generateLineDataSet:yVals2 withColor:[UIColor blueColor]]];
    [datasets addObject:[self generateLineDataSet:yVals3 withColor:[UIColor yellowColor]]];
    [datasets addObject:[self generateLineDataSet:yVals4 withColor:[UIColor grayColor]]];
    LineChartData *lineData = [[LineChartData alloc] initWithXVals:xVals dataSets:datasets];
    [lineData setDrawValues:NO];
    data.lineData = lineData;
    
    
    CandleChartDataSet *set1 = [[CandleChartDataSet alloc] initWithYVals:yVals1 label:@"Data Set"];
    set1.axisDependency = AxisDependencyLeft;
    [set1 setColor:[UIColor colorWithWhite:80/255.f alpha:1.f]];
    
    set1.shadowWidth = 1.5;
    set1.decreasingColor = [UIColor colorWithRed:122/255.f green:242/255.f blue:84/255.f alpha:1.f];
    set1.decreasingFilled = YES;
    set1.increasingColor = UIColor.redColor;
    set1.increasingFilled = YES;
    set1.drawValuesEnabled = NO;
    set1.shadowColorSameAsCandle = YES;
    
    CandleChartData *candleData = [[CandleChartData alloc] initWithXVals:xVals dataSet:set1];
    data.candleData = candleData;
    _chartView.data = data;
    
    
    SCBarChartDataSet *barChartDataSet = [[SCBarChartDataSet alloc] initWithYVals:yVals5 label:@"Data Set"];
    barChartDataSet.candleStickChartDataSet = set1;
    barChartDataSet.drawValuesEnabled = NO;
    barChartDataSet.barSpace = 0.2;
    BarChartData *barData = [[BarChartData alloc]initWithXVals:xVals dataSet:barChartDataSet];
    _barChartView.data = barData;
    
}

- (void)setViewDataCount:(int)count range:(double)range
{
    for (UIView *view in self.chartView.subviews) {
        [view removeFromSuperview];
    }
    
    
    NSMutableArray *xVals = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < count; i++)
    {
        CGFloat originX = i*(self.view.frame.size.width/count);
        [xVals addObject:@(originX)];
    
        CGFloat originY = arc4random() % @(self.view.frame.size.height - 200).integerValue;
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(originX, originY, self.view.frame.size.width/(count*2),50)];
        view.backgroundColor = [UIColor redColor];
        [self.chartView addSubview:view];
        
        UITapGestureRecognizer *tapGr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        [view addGestureRecognizer:tapGr];
    }
    
    
}

- (void)tap:(UITapGestureRecognizer *)tapGr{
    [UIView animateWithDuration:0.3 animations:^{
        UIView *view = tapGr.view;
        CGSize newSize = CGSizeMake(view.frame.size.width*3, view.frame.size.height*3);
        view.frame = CGRectMake(view.center.x - newSize.width/2, view.center.y - newSize.height/2, newSize.width, newSize.height);
    }];
}

- (void)optionTapped:(NSString *)key
{
    if ([key isEqualToString:@"toggleValues"])
    {
        for (ChartDataSet *set in _chartView.data.dataSets)
        {
            set.drawValuesEnabled = !set.isDrawValuesEnabled;
        }
        
        [_chartView setNeedsDisplay];
    }
    
    if ([key isEqualToString:@"toggleFilled"])
    {
        for (LineChartDataSet *set in _chartView.data.dataSets)
        {
            set.drawFilledEnabled = !set.isDrawFilledEnabled;
        }
        
        [_chartView setNeedsDisplay];
    }
    
    if ([key isEqualToString:@"toggleCircles"])
    {
        for (LineChartDataSet *set in _chartView.data.dataSets)
        {
            set.drawCirclesEnabled = !set.isDrawCirclesEnabled;
        }
        
        [_chartView setNeedsDisplay];
    }
    
    if ([key isEqualToString:@"toggleCubic"])
    {
        for (LineChartDataSet *set in _chartView.data.dataSets)
        {
            set.drawCubicEnabled = !set.isDrawCubicEnabled;
        }
        
        [_chartView setNeedsDisplay];
    }
    
    if ([key isEqualToString:@"toggleHighlight"])
    {
        _chartView.highlightEnabled = !_chartView.isHighlightEnabled;
        
        [_chartView setNeedsDisplay];
    }
    
    if ([key isEqualToString:@"toggleStartZero"])
    {
        _chartView.leftAxis.startAtZeroEnabled = !_chartView.leftAxis.isStartAtZeroEnabled;
        _chartView.rightAxis.startAtZeroEnabled = !_chartView.rightAxis.isStartAtZeroEnabled;
        
        [_chartView notifyDataSetChanged];
    }
    
    if ([key isEqualToString:@"animateX"])
    {
        [_chartView animateWithXAxisDuration:3.0];
    }
    
    if ([key isEqualToString:@"animateY"])
    {
        [_chartView animateWithYAxisDuration:3.0];
    }
    
    if ([key isEqualToString:@"animateXY"])
    {
        [_chartView animateWithXAxisDuration:3.0 yAxisDuration:3.0];
    }
    
    if ([key isEqualToString:@"saveToGallery"])
    {
        [_chartView saveToCameraRoll];
    }
    
    if ([key isEqualToString:@"togglePinchZoom"])
    {
        _chartView.pinchZoomEnabled = !_chartView.isPinchZoomEnabled;
        
        [_chartView setNeedsDisplay];
    }
    
    if ([key isEqualToString:@"toggleAutoScaleMinMax"])
    {
       // _chartView.autoScaleMinMaxEnabled = !_chartView.isAutoScaleMinMaxEnabled;
        [_chartView notifyDataSetChanged];
    }
    
    if ([key isEqualToString:@"toggleShadowColorSameAsCandle"])
    {
        for (CandleChartDataSet *set in _chartView.data.dataSets)
        {
          //  set.shadowColorSameAsCandle = !set.shadowColorSameAsCandle;
        }
        
        [_chartView notifyDataSetChanged];
    }
}

#pragma mark - Actions

- (IBAction)slidersValueChanged:(id)sender
{
    _sliderTextX.text = [@((int)_sliderX.value + 1) stringValue];
    _sliderTextY.text = [@((int)_sliderY.value) stringValue];
    
    NSDate *date1 = [NSDate date];
    
 //   [self setViewDataCount:(_sliderX.value + 1) range:_sliderY.value];
    
    [self setDataCount:(_sliderX.value + 1) range:_sliderY.value];
    NSDate *date2 = [NSDate date];
    NSTimeInterval interval = [date2 timeIntervalSinceDate:date1];
    NSLog(@"%f",interval);
}

#pragma mark - ChartViewDelegate

- (void)chartValueSelected:(ChartViewBase * __nonnull)chartView entry:(ChartDataEntry * __nonnull)entry dataSetIndex:(NSInteger)dataSetIndex highlight:(ChartHighlight * __nonnull)highlight
{
    NSLog(@"chartValueSelected");
//    
//    CandleChartDataEntry *dataEntry = (CandleChartDataEntry *)entry;
//    UIView *view = [[UIView alloc] initWithFrame:dataEntry.candleFrame];
//    
//  //  var color = dataSet.decreasingColor ?? dataSet.colorAt(j);
//
//    view.backgroundColor = [UIColor colorWithRed:122/255.f green:242/255.f blue:84/255.f alpha:1.f];
//    [self.chartView addSubview:view];
//    [UIView animateWithDuration:0.5 animations:^{
//        CGSize newSize = CGSizeMake(view.frame.size.width*3, view.frame.size.height*3);
//        view.frame = CGRectMake(view.center.x - newSize.width/2, view.center.y - newSize.height/2, newSize.width, newSize.height);
//    }];
}

- (void)chartValueNothingSelected:(ChartViewBase * __nonnull)chartView
{
    NSLog(@"chartValueNothingSelected");
}

@end
