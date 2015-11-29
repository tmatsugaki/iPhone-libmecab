//
//  LibMecabSampleViewController.h
//  LibMecabSample
//
//  Created by Watanabe Toshinori on 10/12/27.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NodeCell.h"

@class Mecab;

@interface LibMecabSampleViewController : UIViewController<UITextFieldDelegate> {
	
	UITextField *textField;
	UITableView *tableView_;
	NodeCell *nodeCell;
    UIButton *explore;
    UISwitch *patch;
	
	Mecab *mecab;
    NSMutableArray *nodes;
    NSMutableArray *tokens;
}

@property (nonatomic, retain) IBOutlet UITextField *textField;
@property (nonatomic, retain) IBOutlet UITableView *tableView_;
@property (nonatomic, retain) IBOutlet NodeCell *nodeCell;
@property (nonatomic, retain) IBOutlet UIButton *explore;
@property (nonatomic, retain) IBOutlet UISwitch *patch;
@property (nonatomic, retain) Mecab *mecab;
@property (nonatomic, retain) NSMutableArray *nodes;
@property (nonatomic, retain) NSMutableArray *tokens;

- (IBAction)parse:(id)sender;

@end

