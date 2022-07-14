//
//  MHSViewController.m
//  MHSAnalytics
//
//  Created by Visual on 07/08/2022.
//  Copyright (c) 2022 Visual. All rights reserved.
//

#import "MHSViewController.h"
#import "MHSExposureController.h"
#import "MHSAnalytics.h"
@interface MHSViewController ()

@end

@implementation MHSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return 3;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if (indexPath.row == 0) {
        cell.textLabel.text = @"点击埋点";
    }
    if (indexPath.row == 1) {
        cell.textLabel.text = @"带page的点击埋点";
    }
    if (indexPath.row == 2) {
        cell.textLabel.text = @"曝光";
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        [[MHSAnalytics sharedInstance] trackWithEvent:@"click_test"];
    }
    if (indexPath.row == 1) {
        [[MHSAnalytics sharedInstance] trackWithEvent:@"click_test" content:nil page:self.class];
    }
    if (indexPath.row == 2) {
        MHSExposureController *exposureVC = [[MHSExposureController alloc] init];
        [self presentViewController:exposureVC animated:YES completion:nil];
    }
}

@end
