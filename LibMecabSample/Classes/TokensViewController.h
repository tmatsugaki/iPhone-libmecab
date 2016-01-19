//
//  TokensViewController.h
//  LibMecabSample
//
//  Created by tmatsugaki on 2015/11/24.
//

#import <UIKit/UIKit.h>
#import "definitions.h"
#import "TokenCell.h"

@interface TokensViewController : UIViewController <UITableViewDataSource, UITabBarDelegate, UISearchBarDelegate> {
	
    UINavigationBar *_myNavigationBar;
    UINavigationItem *_myNavigationItem;
    UISearchBar *_searchBar;
    TokenCell *_tokenCell;
    NSMutableArray *_listItems;
    NSMutableArray *_rawSentences;
    NSMutableArray *_filteredSentences;
    BOOL _smudged;
}

@property (nonatomic, retain) IBOutlet UINavigationBar *myNavigationBar;
@property (nonatomic, retain) IBOutlet UINavigationItem *myNavigationItem;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet TokenCell *tokenCell;
@property (nonatomic, retain) NSMutableArray *listItems;
@property (nonatomic, retain) NSMutableArray *rawSentences;
@property (nonatomic, retain) NSMutableArray *filteredSentences;
@property (nonatomic, assign) BOOL smudged;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil sentencesArray:(NSMutableArray *)sentencesArray;

@end

