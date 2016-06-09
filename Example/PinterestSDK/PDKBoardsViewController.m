//
//  PDKBoardsViewController.m
//  PinterestSDK
//
//  Created by Ricky Cancro on 3/11/15.
//  Copyright (c) 2015 ricky cancro. All rights reserved.
//

#import "PDKBoardsViewController.h"

#import "PDKBoard.h"
#import "PDKBoardCell.h"
#import "PDKPinsViewController.h"
#import "PDKResponseObject.h"

@interface PDKBoardsViewController () <UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *boards;
@property (nonatomic, strong) NSIndexPath *boardIndexPath;

@property (nonatomic, strong) PDKResponseObject *currentResponseObject;
@end

@implementation PDKBoardsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    NSDictionary *views = @{@"tableView":self.tableView};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:0 metrics:nil views:views]];
    [self.tableView registerNib:[UINib nibWithNibName:@"PDKBoardCell" bundle:nil] forCellReuseIdentifier:@"BoardCell"];
    self.tableView.rowHeight = 100.0;
    
    self.navigationItem.title = NSLocalizedString(@"Boards", nil);
    
    __weak PDKBoardsViewController *weakSelf = self;
    [[PDKClient sharedInstance] getAuthenticatedUserBoardsWithFields:[NSSet setWithArray:@[@"id", @"image", @"description", @"name", @"privacy"]]
                                                             success:^(PDKResponseObject *responseObject) {
                                                                 weakSelf.currentResponseObject = responseObject;
                                                                 weakSelf.boards = [responseObject boards];
                                                                 [weakSelf.tableView reloadData];
                                                             } andFailure:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)showTemporaryAlertWithTitle:(NSString *)title message:(NSString *)message
{
    __weak PDKBoardsViewController *weakSelf = self;
    UIAlertController *successController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:successController animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

- (void)createPinOnBoard:(PDKBoard *)board
{
    // If creating a pin from a URL, show a alert with a text field for the url and one for the pin description
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Create Pin" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"Pin Image URL", nil);
    }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"Pin Source URL", nil);
    }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"Pin Description", nil);
    }];
    
    __weak PDKBoardsViewController *weakSelf = self;
    PDKBoardCell *cell = (PDKBoardCell *)[self.tableView cellForRowAtIndexPath:self.boardIndexPath];
    
    [cell enableButtons:NO];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *imageURLString = [alertController.textFields[0] text];
        NSString *linkURLString = [alertController.textFields[1] text];
        NSString *description = [alertController.textFields[2] text];
        
        if ([imageURLString length] && [description length]) {
            [cell showSpinner:YES withPercentage:-1];
            [[PDKClient sharedInstance] createPinWithImageURL:[NSURL URLWithString:imageURLString]
                                                         link:[NSURL URLWithString:linkURLString]
                                                      onBoard:board.identifier
                                                  description:description
                                                  withSuccess:^(PDKResponseObject *responseObject) {
                                                      [cell enableButtons:YES];
                                                      [cell showSpinner:NO withPercentage:0];
                                                      
                                                      if ([responseObject isValid]) {
                                                          [weakSelf showTemporaryAlertWithTitle:NSLocalizedString(@"Pin Created!", nil) message:nil];
                                                      }
                                                  } andFailure:^(NSError *error){
                                                      [weakSelf showTemporaryAlertWithTitle:NSLocalizedString(@"Error!", nil) message:[error description]];
                                                      [cell enableButtons:YES];
                                                      [cell showSpinner:NO withPercentage:0];
                                                  }];
        }
        
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
    [alertController addAction:ok];
    [alertController addAction:cancel];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)createPinWithImage:(UIImage *)image onBoard:(PDKBoard *)board
{
    // create a description for the choosen image and pin it.
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Add Description" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"Pin Description", nil);
    }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"Pin Source URL", nil);
    }];

    __weak PDKBoardsViewController *weakSelf = self;
    PDKBoardCell *cell = (PDKBoardCell *)[self.tableView cellForRowAtIndexPath:self.boardIndexPath];
    [cell enableButtons:NO];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *description = [alertController.textFields[0] text];
        NSString *linkURLString = [alertController.textFields[1] text];
        
        if ([description length]) {
            [[PDKClient sharedInstance] createPinWithImage:image
                                                      link:[NSURL URLWithString:linkURLString]
                                                   onBoard:board.identifier
                                               description:description
                                                  progress:^(CGFloat percentComplete) {
                                                      [cell showSpinner:YES withPercentage:percentComplete];
                                                  }
                                               withSuccess:^(PDKResponseObject *responseObject) {
                                                   
                                                   [cell enableButtons:YES];
                                                   [cell showSpinner:NO withPercentage:0];
                                                   
                                                   if ([responseObject isValid]) {
                                                       [weakSelf showTemporaryAlertWithTitle:NSLocalizedString(@"Pin Created!", nil) message:nil];
                                                   }
                                               } andFailure:^(NSError *error) {
                                                   [weakSelf showTemporaryAlertWithTitle:NSLocalizedString(@"Error!", nil) message:[error description]];
                                                   [cell enableButtons:YES];
                                                   [cell showSpinner:NO withPercentage:0];
                                               }];
        }
        
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
    [alertController addAction:ok];
    [alertController addAction:cancel];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    __weak PDKBoardsViewController *weakSelf = self;
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        PDKBoard *board = weakSelf.boards[weakSelf.boardIndexPath.row];
        [weakSelf createPinWithImage:chosenImage onBoard:board];
        weakSelf.boardIndexPath = nil;
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    self.boardIndexPath = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return [self.boards count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    PDKBoardCell *cell = (PDKBoardCell *)[tableView dequeueReusableCellWithIdentifier:@"BoardCell"];
    PDKBoard *board = self.boards[indexPath.row];
    [cell updateWithBoard:board];
    
    __weak PDKBoardsViewController *weakSelf = self;
    cell.addPinFromImageBlock = ^{
        weakSelf.boardIndexPath = indexPath;
        
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        
        [weakSelf presentViewController:picker animated:YES completion:nil];
    };
    
    cell.addPinFromURLBlock = ^{
        weakSelf.boardIndexPath = indexPath;
        [weakSelf createPinOnBoard:board];
    };
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PDKBoard *board = self.boards[indexPath.row];
    PDKPinsViewController *pinsVC = [[PDKPinsViewController alloc] initWithBoard:board];
    pinsVC.dataLoadingBlock = ^(PDKClientSuccess succes, PDKClientFailure failure) {
        [[PDKClient sharedInstance] getBoardPins:board.identifier fields:[NSSet setWithArray:@[@"id", @"image", @"note"]] withSuccess:succes andFailure:failure];
    };
    pinsVC.navigationItem.title = board.name;
    
    [self.navigationController pushViewController:pinsVC animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        __weak PDKBoardsViewController *weakSelf = self;
        PDKBoard *board = self.boards[indexPath.row];
        [[PDKClient sharedInstance] deleteBoard:board.identifier
                                    withSuccess:^(PDKResponseObject *responseObject) {
                                        NSMutableArray *mutableBoards = [weakSelf.boards mutableCopy];
                                        [mutableBoards removeObjectAtIndex:indexPath.row];
                                        weakSelf.boards = mutableBoards;
                                        
                                        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                                    } andFailure:nil];
    }
}

@end
