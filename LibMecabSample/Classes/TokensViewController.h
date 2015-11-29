//
//  TokensViewController.h
//  LibMecabSample
//
//  Created by tmatsugaki on 2015/11/24.
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

