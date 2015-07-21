//
//  PDKPinsViewController.h
//  PinterestSDK
//
//  Created by Ricky Cancro on 3/11/15.
//  Copyright (c) 2015 ricky cancro. All rights reserved.
//

@import UIKit;
#import "PDKClient.h"

@class PDKBoard;

typedef void (^PDKPinsViewControllerLoadBlock)(PDKClientSuccess succes, PDKClientFailure failure);

@interface PDKPinsViewController : UIViewController
@property (nonatomic, copy) PDKPinsViewControllerLoadBlock dataLoadingBlock;
- (instancetype)initWithBoard:(PDKBoard *)board;
@end
