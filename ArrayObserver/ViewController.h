//
//  ViewController.h
//  Test
//
//  Created by Brent Gulanowski on 2014-05-27.
//  Copyright (c) 2014 Lichen Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Widget : NSObject
@property (nonatomic) NSInteger amount;
+ (instancetype)widget;
@end

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *systemButton;
@property (weak, nonatomic) IBOutlet UIButton *customButton;
@property (nonatomic) NSArray *widgets;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, readonly) NSMutableArray *mutableWidgets;
@property (weak, nonatomic) IBOutlet UILabel *label;

- (IBAction)doIncreaseAmount:(id)sender;
- (IBAction)doAddWidget:(id)sender;
- (IBAction)doMultiAdd:(id)sender;

@end
