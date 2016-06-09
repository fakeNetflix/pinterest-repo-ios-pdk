//
//  PDKBoardCell.h
//  PinterestSDK
//
//  Created by Ricky Cancro on 3/14/15.
//  Copyright (c) 2015 ricky cancro. All rights reserved.
//

@import UIKit;
@class PDKBoard;

typedef void (^PDKBoardCellActionBlock)();

@interface PDKBoardCell : UITableViewCell
@property (nonatomic, strong) IBOutlet UIImageView *boardImageView;
@property (nonatomic, strong) IBOutlet UILabel *percentageLabel;
@property (nonatomic, strong) IBOutlet UILabel *boardNameLabel;
@property (nonatomic, strong) IBOutlet UILabel *boardDescriptionLabel;
@property (nonatomic, strong) IBOutlet UIImageView *lockImageView;

@property (nonatomic, copy) PDKBoardCellActionBlock addPinFromURLBlock;
@property (nonatomic, copy) PDKBoardCellActionBlock addPinFromImageBlock;

- (IBAction)addPinFromURL:(id)sender;
- (IBAction)addPinFromImage:(id)sender;

- (void)updateWithBoard:(PDKBoard *)board;

- (void)showSpinner:(BOOL)show withPercentage:(CGFloat)percentage;
- (void)enableButtons:(BOOL)doEnable;
@end
