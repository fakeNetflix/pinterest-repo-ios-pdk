//
//  PDKBoardCell.m
//  PinterestSDK
//
//  Created by Ricky Cancro on 3/14/15.
//  Copyright (c) 2015 ricky cancro. All rights reserved.
//

#import "PDKBoardCell.h"

#import "PDKBoard.h"
#import "PDKImageInfo.h"

#import <AFNetworking/UIImageView+AFNetworking.h>

@interface PDKBoardCell()
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) IBOutlet UIButton *addPinFromURLButton;
@property (nonatomic, strong) IBOutlet UIButton *addPinFromImageButton;
@end

@implementation PDKBoardCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self showSpinner:NO withPercentage:0];
    self.boardImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.boardImageView.clipsToBounds = YES;
    self.boardImageView.layer.cornerRadius = 10.0;
}

- (void)showSpinner:(BOOL)show withPercentage:(CGFloat)percentage
{
    if (show == NO) {
        [self.spinner stopAnimating];
        self.percentageLabel.hidden = YES;
        self.percentageLabel.text = @"0%%";
    } else {
        [self.spinner startAnimating];
        self.percentageLabel.hidden = percentage >= 0 ? NO : YES;
        self.percentageLabel.text = [NSString stringWithFormat:@"%ld%%", (NSUInteger)(percentage * 100)];
    }
}

- (void)enableButtons:(BOOL)doEnable
{
    self.addPinFromImageButton.enabled = self.addPinFromURLButton.enabled = doEnable;
}

- (IBAction)addPinFromURL:(id)sender
{
    if (self.addPinFromURLBlock) {
        self.addPinFromURLBlock();
    }
}

- (IBAction)addPinFromImage:(id)sender
{
    if (self.addPinFromImageBlock) {
        self.addPinFromImageBlock();
    }
}

- (void)updateWithBoard:(PDKBoard *)board
{
    self.boardDescriptionLabel.text = board.descriptionText;
    self.boardNameLabel.text = board.name;
    [self.boardImageView setImageWithURL:[board smallestImage].url];

    if ([board.privacy isEqualToString:@"private"]) {
        self.lockImageView.image = [UIImage imageNamed:@"Lock"];
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.boardImageView.image = nil;
    self.lockImageView.image = nil;
    [self showSpinner:NO withPercentage:0];
}

@end
