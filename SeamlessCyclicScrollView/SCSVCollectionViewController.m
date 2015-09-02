//
//  SCSVCollectionViewController.m
//  SeamlessCyclicScrollView
//
//  Created by liuge on 1/5/15.
//  Copyright (c) 2015 iLegendSoft. All rights reserved.
//

#import "SCSVCollectionViewController.h"
#import "SCSVCollectionViewCell.h"

@interface SCSVCollectionViewController ()

@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *collectionViewFlowLayout;

@property (strong, nonatomic) NSArray *dataSource;// data source

@property (strong, nonatomic) NSIndexPath *indexPathForDeviceOrientation;// for move to the right position after orientation

@end

@implementation SCSVCollectionViewController

static NSString * const reuseIdentifier = @"SCSVReusableID";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // data source
    _dataSource = @[@1, @2, @3];
    
    // duplicate the last item and put it at first
    // duplicate the first item and put it at last
    id firstItem = [_dataSource firstObject];
    id lastItem = [_dataSource lastObject];
    NSMutableArray *workingArray = [_dataSource mutableCopy];
    [workingArray insertObject:lastItem atIndex:0];
    [workingArray addObject:firstItem];
    _dataSource = workingArray;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // scroll to the 2nd page, which is showing the first item.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // scroll to the first page, note that this call will trigger scrollViewDidScroll: once and only once
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
    });
}


#pragma mark - <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // self.view.bounds is orientation-sensitive, so don't worry about the device orientation
    return self.view.bounds.size;
}


#pragma mark - UIInterfaceOrientation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    _indexPathForDeviceOrientation = [[self.collectionView indexPathsForVisibleItems] firstObject];
    [[self.collectionView collectionViewLayout] invalidateLayout];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.collectionView scrollToItemAtIndexPath:_indexPathForDeviceOrientation atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
}


#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SCSVCollectionViewCell *cell = (SCSVCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    cell.label.text = [@"Page " stringByAppendingString:[_dataSource[indexPath.item] stringValue]];
    
    return cell;
}


#pragma mark - <UIScrollViewDelegate>

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    static CGFloat lastContentOffsetX = FLT_MIN;
    
    // We can ignore the first time scroll,
    // because it is caused by the call scrollToItemAtIndexPath: in ViewWillAppear
    if (FLT_MIN == lastContentOffsetX) {
        lastContentOffsetX = scrollView.contentOffset.x;
        return;
    }
    
    CGFloat currentOffsetX = scrollView.contentOffset.x;
    CGFloat currentOffsetY = scrollView.contentOffset.y;
    
    CGFloat pageWidth = scrollView.frame.size.width;
    CGFloat offset = pageWidth * (_dataSource.count - 2);
    
    // the first page(showing the last item) is visible and user's finger is still scrolling to the right
    if (currentOffsetX < pageWidth && lastContentOffsetX > currentOffsetX) {
        lastContentOffsetX = currentOffsetX + offset;
        scrollView.contentOffset = (CGPoint){lastContentOffsetX, currentOffsetY};
    }
    // the last page (showing the first item) is visible and the user's finger is still scrolling to the left
    else if (currentOffsetX > offset && lastContentOffsetX < currentOffsetX) {
        lastContentOffsetX = currentOffsetX - offset;
        scrollView.contentOffset = (CGPoint){lastContentOffsetX, currentOffsetY};
    } else {
        lastContentOffsetX = currentOffsetX;
    }
}

@end
