//
//  PDKPinsViewController.m
//  PinterestSDK
//
//  Created by Ricky Cancro on 3/11/15.
//  Copyright (c) 2015 ricky cancro. All rights reserved.
//

#import "PDKPinsViewController.h"

#import "PDKBoard.h"
#import "PDKImageInfo.h"
#import "PDKPin.h"
#import "PDKPinCell.h"
#import "PDKResponseObject.h"

#import <AFNetworking/UIImageView+AFNetworking.h>

@interface PDKPinsViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *pins;

@property (nonatomic, strong) PDKResponseObject *currentResponseObject;
@property (nonatomic, strong) PDKBoard *board;
@property (nonatomic, assign) BOOL fetchingMore;
@end

@implementation PDKPinsViewController

- (instancetype)initWithBoard:(PDKBoard *)board
{
    self = [super init];
    if (self) {
        _board = board;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(150, 180);
    flowLayout.minimumLineSpacing = 10.0;
    flowLayout.minimumInteritemSpacing = 5.0;
    flowLayout.sectionInset = UIEdgeInsetsMake(10.0, 5.0, 10.0, 5.0);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor colorWithWhite:.9 alpha:1.0];
    [self.view addSubview:self.collectionView];
    
    NSDictionary *views = @{@"collectionView":self.collectionView};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[collectionView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView]|" options:0 metrics:nil views:views]];
    [self.collectionView registerClass:[PDKPinCell class] forCellWithReuseIdentifier:@"PinCell"];
    
    __weak PDKPinsViewController *weakSelf = self;
    PDKClientSuccess completionBlock = ^(PDKResponseObject *responseObject) {
        weakSelf.currentResponseObject = responseObject;
        weakSelf.pins = [responseObject pins];
        [weakSelf.collectionView reloadData];
    };
    
    if (self.dataLoadingBlock) {
        self.dataLoadingBlock(completionBlock, nil);
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.pins count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PDKPin *pin = self.pins[indexPath.row];
    PDKPinCell *cell = (PDKPinCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PinCell" forIndexPath:indexPath];
    cell.descriptionLabel.text = pin.descriptionText;
    
    [cell.imageView setImageWithURL:pin.largestImage.url];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PDKPin *pin = self.pins[indexPath.row];
    [[UIApplication sharedApplication] openURL:pin.url];
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.fetchingMore == NO && [self.currentResponseObject hasNext] && self.pins.count - indexPath.row < 5) {
        self.fetchingMore = YES;
        
        __weak PDKPinsViewController *weakSelf = self;
        [self.currentResponseObject loadNextWithSuccess:^(PDKResponseObject *responseObject) {
            weakSelf.fetchingMore = NO;
            weakSelf.currentResponseObject = responseObject;
            weakSelf.pins = [weakSelf.pins arrayByAddingObjectsFromArray:[responseObject pins]];
            [weakSelf.collectionView reloadData];
        } andFailure:nil];
    }
}

@end
