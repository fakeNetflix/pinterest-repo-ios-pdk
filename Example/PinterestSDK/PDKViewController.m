//
//  PDKViewController.m
//  PinterestSDK
//
//  Created by ricky cancro on 01/28/2015.
//  Copyright (c) 2014 ricky cancro. All rights reserved.
//

#import "PDKViewController.h"
#import "PDKBoard.h"
#import "PDKBoardsViewController.h"
#import "PDKClient.h"
#import "PDKPin.h"
#import "PDKPinsViewController.h"
#import "PDKResponseObject.h"
#import "PDKUser.h"

@interface PDKViewController ()
@property (nonatomic, strong) PDKUser *user;
@property (nonatomic, strong) UILabel *resultLabel;

@property (nonatomic, strong) UIButton *pinsButton;
@property (nonatomic, strong) UIButton *boardsButton;
@property (nonatomic, strong) UIButton *createBoardButton;
@property (nonatomic, strong) UIButton *likesButton;

@end

@implementation PDKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = NSLocalizedString(@"Pinterest SDK", nil);
    
    UIButton *authenticateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    authenticateButton.translatesAutoresizingMaskIntoConstraints = NO;
    [authenticateButton setTitle:NSLocalizedString(@"Authenticate", nil) forState:UIControlStateNormal];
    [authenticateButton addTarget:self action:@selector(authenticateButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:authenticateButton];
    
    UIButton *pinItButton = [UIButton buttonWithType:UIButtonTypeSystem];
    pinItButton.translatesAutoresizingMaskIntoConstraints = NO;
    [pinItButton setTitle:NSLocalizedString(@"PinIt", nil) forState:UIControlStateNormal];
    [pinItButton addTarget:self action:@selector(pinItButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pinItButton];
    
    self.pinsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.pinsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.pinsButton setTitle:NSLocalizedString(@"View Pins", nil) forState:UIControlStateNormal];
    [self.pinsButton addTarget:self action:@selector(pinsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.pinsButton];
    
    self.likesButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.likesButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.likesButton setTitle:NSLocalizedString(@"View Likes", nil) forState:UIControlStateNormal];
    [self.likesButton addTarget:self action:@selector(likesButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.likesButton];
    
    self.boardsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.boardsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.boardsButton setTitle:NSLocalizedString(@"View Boards", nil) forState:UIControlStateNormal];
    [self.boardsButton addTarget:self action:@selector(boardsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.boardsButton];
    
    self.resultLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.resultLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.resultLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.resultLabel];
    
    self.createBoardButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.createBoardButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.createBoardButton setTitle:NSLocalizedString(@"Create Board", nil) forState:UIControlStateNormal];
    [self.createBoardButton addTarget:self action:@selector(createBoardButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.createBoardButton];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(authenticateButton, pinItButton, _pinsButton, _likesButton, _boardsButton, _createBoardButton, _resultLabel);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[authenticateButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[pinItButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[pinItButton]-|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(100)-[authenticateButton]-[pinItButton]-[_pinsButton]-[_likesButton]-[_boardsButton]-[_createBoardButton]-[_resultLabel]" options:NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllRight metrics:nil views:views]];
    [self updateButtonEnabledState];
    
    __weak PDKViewController *weakSelf = self;
    [[PDKClient sharedInstance] silentlyAuthenticateWithSuccess:^(PDKResponseObject *responseObject) {
        [weakSelf updateButtonEnabledState];
    } andFailure:nil];
}

- (void)updateButtonEnabledState
{
    self.pinsButton.enabled = self.boardsButton.enabled = self.createBoardButton.enabled = self.likesButton.enabled = [PDKClient sharedInstance].authorized;
}

- (void)authenticateButtonTapped:(UIButton *)button
{
    __weak PDKViewController *weakSelf = self;
    [[PDKClient sharedInstance] authenticateWithPermissions:@[PDKClientReadPublicPermissions,
                                                              PDKClientWritePublicPermissions,
                                                              PDKClientReadPrivatePermissions,
                                                              PDKClientWritePrivatePermissions,
                                                              PDKClientReadRelationshipsPermissions,
                                                              PDKClientWriteRelationshipsPermissions]
                                                withSuccess:^(PDKResponseObject *responseObject)
    {
        weakSelf.user = [responseObject user];
        weakSelf.resultLabel.text = [NSString stringWithFormat:@"%@ authenticated!", weakSelf.user.firstName];
        [weakSelf updateButtonEnabledState];
    } andFailure:^(NSError *error) {
        weakSelf.resultLabel.text = @"authentication failed";
    }];
}

- (void)pinItButtonTapped:(UIButton *)button
{
    __weak PDKViewController *weakSelf = self;
    [PDKPin pinWithImageURL:[NSURL URLWithString:@"https://about.pinterest.com/sites/about/files/logo.jpg"]
                       link:[NSURL URLWithString:@"https://www.pinterest.com"]
         suggestedBoardName:@"Tooty McFruity"
                       note:@"The Pinterest Logo"
                withSuccess:^
    {
        weakSelf.resultLabel.text = [NSString stringWithFormat:@"successfully pinned pin"];
    }
                 andFailure:^(NSError *error)
    {
        weakSelf.resultLabel.text = @"pin it failed";
    }];
}

- (void)createBoardButtonTapped:(UIButton *)button
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Create Board"
                                                                   message:@"Enter the new board name:"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    __weak PDKViewController *weakSelf = self;
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *boardName = [alert.textFields[0] text];
        [[PDKClient sharedInstance] createBoard:boardName
                               boardDescription:nil
                          withSuccess:^(PDKResponseObject *responseObject) {
                              
                              if ([responseObject isValid]) {
                                  PDKBoard *createdBoard = responseObject.board;
                                  weakSelf.resultLabel.text = [NSString stringWithFormat:@"%@ created!", createdBoard.name];
                                  
                                  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                      weakSelf.resultLabel.text = @"";
                                  });
                              }
                              
                          } andFailure:nil];
        
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
    
    [alert addTextFieldWithConfigurationHandler:nil];
    [alert addAction:ok];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (void)likesButtonTapped:(UIButton *)button
{
    PDKPinsViewController *pinsVC = [[PDKPinsViewController alloc] init];
    pinsVC.dataLoadingBlock = ^(PDKClientSuccess succes, PDKClientFailure failure) {
        [[PDKClient sharedInstance] getAuthenticatedUserLikesWithFields:[NSSet setWithArray:@[@"id", @"image", @"note"]] success:succes andFailure:failure];
    };
    [self.navigationController pushViewController:pinsVC animated:YES];
}

- (void)pinsButtonTapped:(UIButton *)button
{
    PDKPinsViewController *pinsVC = [[PDKPinsViewController alloc] init];
    pinsVC.dataLoadingBlock = ^(PDKClientSuccess succes, PDKClientFailure failure) {
        [[PDKClient sharedInstance] getAuthenticatedUserPinsWithFields:[NSSet setWithArray:@[@"id", @"image", @"note"]] success:succes andFailure:failure];
    };
    pinsVC.navigationItem.title = NSLocalizedString(@"Pins", nil);
    [self.navigationController pushViewController:pinsVC animated:YES];
}

- (void)boardsButtonTapped:(UIButton *)button
{
    PDKBoardsViewController *boardsVC = [[PDKBoardsViewController alloc] init];
    [self.navigationController pushViewController:boardsVC animated:YES];
}

@end
