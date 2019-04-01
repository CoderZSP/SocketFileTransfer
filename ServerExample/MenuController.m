//
//  MenuController.m
//  ServerExample
//
//  Created by zhangsp on 2019/3/7.
//  Copyright © 2019 zsp. All rights reserved.
//

#import "MenuController.h"
#import "ServerController.h"
@interface MenuController ()

@end

@implementation MenuController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"socket Demo";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuIdentifier" forIndexPath:indexPath];
    if (indexPath.row == 0) {
        cell.textLabel.text = @"sever";
    }
    else{
        cell.textLabel.text = @"client";
    }
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row ==0) { // server
        ServerController *serverVc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ServerController"];
        [self.navigationController pushViewController:serverVc animated:YES];
    }
    else{ // client
        UIViewController *clientVc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ClientController"];
        [self.navigationController pushViewController:clientVc animated:YES];
    }
    
}


@end
