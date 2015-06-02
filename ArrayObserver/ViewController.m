//
//  ViewController.m
//  Test
//
//  Created by Brent Gulanowski on 2014-05-27.
//  Copyright (c) 2014 Lichen Labs. All rights reserved.
//

#import "ViewController.h"
#import "ArrayObserver.h"
#import "UIImage+BackgroundImage.h"

#import <objc/objc-runtime.h>

void * observingContext = &observingContext;

@interface NSIndexSet (IndexPathCreating)
- (NSArray *)rowPathsForSection:(NSUInteger)section;
@end

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate, ArrayObserving>
@property (nonatomic) Widget *selectedWidget;
@property (nonatomic) NSUInteger selectedIndex;
@end

@implementation ViewController {
    NSMutableArray *_widgets;
}

#pragma mark - NSObject

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"widgets.amount"];
}

#pragma mark - Accessors

- (NSArray *)widgets
{
    return [_widgets copy];
}

- (void)setWidgets:(NSArray *)widgets
{
    _widgets = [widgets mutableCopy];
}

- (void)insertObject:(Widget *)widget inWidgetsAtIndex:(NSUInteger)index
{
    [_widgets insertObject:widget atIndex:index];
    self.selectedIndex = index;
}

- (void)insertWidgets:(NSArray *)array atIndexes:(NSIndexSet *)indexes
{
    [_widgets insertObjects:array atIndexes:indexes];
    self.selectedIndex = indexes.lastIndex;
}

- (id)objectInWidgetsAtIndex:(NSUInteger)index
{
    return [_widgets objectAtIndex:index];
}

- (void)removeObjectFromWidgetsAtIndex:(NSUInteger)index
{
    [_widgets removeObjectAtIndex:index];
    self.selectedIndex = NSNotFound;
}

- (void)addWidgetsObject:(Widget *)widget
{
    [self insertObject:widget inWidgetsAtIndex:[self countOfWidgets]];
}

- (NSUInteger)countOfWidgets
{
    return [_widgets count];
}

- (void)setSelectedWidget:(Widget *)selectedWidget
{
    self.selectedIndex = [_widgets indexOfObjectIdenticalTo:selectedWidget];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    _selectedIndex = selectedIndex;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateTableSelection];
    });
}

- (Widget *)selectedWidget
{
    return [self objectInWidgetsAtIndex:self.selectedIndex];
}

- (NSIndexPath *)selectedIndexPath
{
    return [NSIndexPath indexPathForRow:_selectedIndex inSection:0];
}

- (void)updateTableSelection
{
    NSIndexPath *selectedIndexPath = [_tableView indexPathForSelectedRow];
    if (selectedIndexPath != nil && selectedIndexPath.row != _selectedIndex) {
        [_tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
    }
    else if (_selectedIndex != NSNotFound) {
        [_tableView selectRowAtIndexPath:[self selectedIndexPath] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    }
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.widgets = [NSArray arrayWithObject:[Widget widget]];
        [self addObserver:self forArrayKeyPath:@"widgets.amount" options:0 context:observingContext];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_imageView.transform = CGAffineTransformMakeScale(1.5, 1.5);
	_imageView.bounds = CGRectMake(50, 50, 200, 200);
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
	
	[_customButton setBackgroundImage:[UIImage buttonBackgroundImageWithFill:[UIColor blueColor] stroke:[UIColor darkGrayColor]] forState:UIControlStateNormal];
	[_customButton setBackgroundImage:[UIImage buttonBackgroundImageWithFill:[UIColor greenColor] stroke:[UIColor darkGrayColor]] forState:UIControlStateHighlighted];
	[_customButton setBackgroundImage:[UIImage buttonBackgroundImageWithFill:[UIColor lightGrayColor] stroke:[UIColor darkGrayColor]] forState:UIControlStateDisabled];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self updateTableSelection];
}

- (NSMutableArray *)mutableWidgets
{
    return [self mutableArrayValueForKey:NSStringFromSelector(@selector(widgets))];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedIndex = indexPath.row;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self countOfWidgets];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.textLabel.text = [NSString stringWithFormat:@"%td", [[self objectInWidgetsAtIndex:indexPath.row] amount]];
    return cell;
}

#pragma mark - ArrayObserving

- (void)observeValueForArrayProperty:(NSString *)property ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSIndexSet *indexes = change[NSKeyValueChangeIndexesKey];
    NSArray *indexPaths = [indexes rowPathsForSection:0];
 
    NSKeyValueChange changeKind = [change[NSKeyValueChangeKindKey] unsignedIntegerValue];
    switch (changeKind) {
        case NSKeyValueChangeSetting:
            [_tableView reloadData];
            break;
            
        case NSKeyValueChangeInsertion:
            [_tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
            case NSKeyValueChangeRemoval:
            [_tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSKeyValueChangeReplacement:
            [_tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        default:
            break;
    }
    [self updateTotal];
}

- (void)observeValueForArrayKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSIndexPath *rowIndexPath = [NSIndexPath indexPathForRow:[_widgets indexOfObjectIdenticalTo:object] inSection:0];
    [_tableView reloadRowsAtIndexPaths:@[rowIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [_tableView selectRowAtIndexPath:rowIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self updateTotal];
}

#pragma mark - Actions

- (IBAction)doAddWidget:(id)sender
{
    [self addWidgetsObject:[Widget widget]];
}

NS_INLINE NSInteger RandomIntegerInRange(NSRange range) {
    return (NSInteger) ((CGFloat)arc4random()/(CGFloat)UINT_MAX * (CGFloat)range.length + (CGFloat)range.location);
}

- (IBAction)doMultiAdd:(id)sender {
    NSMutableArray *widgets = [NSMutableArray array];
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSUInteger count = [self countOfWidgets];
    if (count > 4) {
        count = 4;
    }
    for (NSUInteger i=0; i<count; ++i) {
        Widget *widget = [[Widget alloc] init];
        widget.amount = RandomIntegerInRange(NSMakeRange(0, 5));
        [widgets addObject:widget];
        [indexSet addIndex:2*i];
    }
    [self insertWidgets:widgets atIndexes:indexSet];
}

- (IBAction)doIncreaseAmount:(UIButton *)sender
{
    self.selectedWidget.amount++;
}

#pragma mark - Private

- (void)updateTotal
{
    _label.text = [[_widgets valueForKeyPath:@"@sum.amount"] stringValue];
}

@end

#pragma mark -

@implementation Widget

+ (instancetype)widget {
    return [[self alloc] init];
}

@end

@implementation NSIndexSet (IndexPathCreating)

- (NSArray *)rowPathsForSection:(NSUInteger)section
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:section]];
    }];
    return indexPaths;
}

@end
