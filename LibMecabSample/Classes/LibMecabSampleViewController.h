//
//  LibMecabSampleViewController.h
//  LibMecabSample
//
//  Created by Watanabe Toshinori on 10/12/27.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NodeCell.h"
#import "SmallNodeCell.h"
#import "TokensViewController.h"

@class Mecab;

@interface LibMecabSampleViewController : UIViewController <UITextFieldDelegate, NodeCellDelegate, SmallNodeCellDelegate> {
	
	UITextField *_textField;
	UITableView *_tableView;
    NodeCell *_nodeCell;
    SmallNodeCell *_smallNodeCell;
    UIButton *_examples;
	UIButton *_explore;
	UISwitch *_patch;
	
	Mecab *_mecab;
	NSMutableArray *_nodes;
    NSMutableArray *_listItems;
    BOOL _shortFormat;

    BOOL _patchedResult;
    TokensViewController *_tokensViewController;
}

@property (nonatomic, retain) IBOutlet UITextField *textField;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet NodeCell *nodeCell;
@property (nonatomic, retain) IBOutlet SmallNodeCell *smallNodeCell;
@property (nonatomic, retain) IBOutlet UIButton *examples;
@property (nonatomic, retain) IBOutlet UIButton *explore;
@property (nonatomic, retain) IBOutlet UISwitch *patch;
@property (nonatomic, retain) Mecab *mecab;
@property (nonatomic, retain) NSMutableArray *nodes;
@property (nonatomic, retain) NSMutableArray *listItems;
@property (nonatomic, assign) BOOL shortFormat;
@property (nonatomic, assign) BOOL patchedResult;
@property (nonatomic, retain) TokensViewController *tokensViewController;

- (IBAction)parse:(id)sender;

@end

