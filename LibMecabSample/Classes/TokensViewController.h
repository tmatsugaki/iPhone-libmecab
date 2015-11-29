//
//  TokensViewController.h
//  LibMecabSample
//
//  Created by Watanabe Toshinori on 10/12/27.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "definitions.h"
#import "TokenCell.h"

@interface TokensViewController : UIViewController <UITableViewDataSource, UITabBarDelegate> {
	
    UINavigationBar *myNavigationBar;
    UINavigationItem *myNavigationItem;
    UIBarButtonItem *editButton;
    TokenCell *tokenCell;
    NSMutableArray *tokens;
}

@property (nonatomic, retain) IBOutlet UINavigationBar *myNavigationBar;
@property (nonatomic, retain) IBOutlet UINavigationItem *myNavigationItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic, retain) IBOutlet UITableView *tableView_;
@property (nonatomic, retain) IBOutlet TokenCell *tokenCell;
@property (nonatomic, retain) NSMutableArray *tokens;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil tokensArray:(NSMutableArray *)tokensArray;

@end

