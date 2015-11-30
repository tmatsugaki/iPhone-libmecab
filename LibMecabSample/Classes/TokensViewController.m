//
//  TokensViewController.m
//  LibMecabSample
//
//  Created by tmatsugaki on 2015/11/24.
//

#import "TokensViewController.h"

@implementation TokensViewController

@synthesize myNavigationBar;
@synthesize myNavigationItem;
@synthesize editButton;
@synthesize tableView_;
@synthesize tokenCell;
@synthesize tokens;

#pragma mark - IBAction

- (IBAction) cancel:(id)sender {
    [self dismissMe];
}

- (IBAction) toggleEdit:(id)sender {
    
//    UIBarButtonItem *editButton = myNavigationItem.rightBarButtonItems[0];

    [tableView_ setEditing:tableView_.editing == NO animated:YES];

    if (tableView_.editing)
    {// ブラウズモード >> 編集モード
        editButton.style = UIBarButtonItemStyleDone;
        editButton.title = @"完了";
    } else
    {// 編集モード >> ブラウズモード
        editButton.style = UIBarButtonItemStylePlain;
        editButton.title = @"編集";

        [tableView_ reloadData];
    }
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil tokensArray:(NSMutableArray *)tokensArray {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        self.tokens = tokensArray;
    }
    return self;
}

#pragma mark - UIResponder

- (BOOL) canBecomeFirstResponder {
    return YES;
}

- (BOOL) canResignFirstResponder {
    return YES;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
    
//    [self createGestureRecognizers];
    [tableView_ becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSString *str = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsSentence];
    
    if ([str length]) {
        NSUInteger index = [tokens indexOfObject:str];
        
        if (index != NSNotFound) {
            @try {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                
                [tableView_ selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:UITableViewScrollPositionTop];
            }
            @catch (NSException *exception) {
            }
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (tokens) {
		return [tokens count];
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"TokenCell";
    
    TokenCell *cell = (TokenCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
#if 0
		[[NSBundle mainBundle] loadNibNamed:@"TokenCell" owner:self options:nil];
#else
        // リソースは使わない。
        self.tokenCell = [[TokenCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
#endif
		cell = tokenCell;
		self.tokenCell = nil;
    }
    
	NSString *str = [tokens objectAtIndex:indexPath.row];
    cell.textLabel.text = str;
    return cell;
}

- (void) dismissMe {
    // 画面を閉じる
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString *str = [tokens objectAtIndex:indexPath.row];
    [[NSUserDefaults standardUserDefaults] setObject:str forKey:kDefaultsSentence];
    // 画面を閉じる
    [self performSelector:@selector(dismissMe) withObject:nil afterDelay:0.5];
}

- (NSString *) tableView:(UITableView *)tableView
titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return @"削除";
}

// 【注意】キャンセルされた場合に、layoutSubviews が呼ばれる。
- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

//    DEBUG_LOG(@"%s", __func__);

    @try {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            [tokens removeObject:[tokens objectAtIndex:indexPath.row]];
            [tokens writeToFile:kLibXMLPath atomically:YES];
            
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            [UIView beginAnimations:nil context:context];
            [UIView setAnimationDuration:0.5];
            [UIView setAnimationTransition:UIViewAnimationTransitionNone
                                   forView:self.view
                                     cache:NO];
            [tableView reloadData];
            [UIView commitAnimations];
        }
    }
    @catch (NSException *exception) {
    }
}

- (BOOL) tableView:(UITableView *)tableView
canEditRowAtIndexPath:(NSIndexPath *)indexPath {

    // 最後のトークン消すと画面を終われなくなる。
    return [tokens count] > 1;
}

// Override to support conditional editing of the table view.
- (BOOL) tableView:(UITableView *)tableView
canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    DEBUG_LOG(@"%s", __func__);
    return tableView.editing && [tokens count] > 1;
}

// Override to support conditional editing of the table view.
- (void) tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)indexPath
       toIndexPath:(NSIndexPath *)toIndexPath {
    
//    DEBUG_LOG(@"%s [%ld]->[%ld]", __func__, (long)indexPath.row, (long)toIndexPath.row);
    @try {
        if (indexPath.row != toIndexPath.row) {
            NSUInteger numRows = [self tableView:tableView numberOfRowsInSection:0];
            NSString *token = [tokens[indexPath.row] retain];

            [tokens removeObject:token];
            if (toIndexPath.row == numRows - 1)
            {// 末端
                [tokens addObject:token];
            } else
            {
                [tokens insertObject:token atIndex:toIndexPath.row];
            }
            [[NSUserDefaults standardUserDefaults] setObject:token forKey:kDefaultsSentence];

            [token release];
        }
    }
    @catch (NSException *exception) {
    }
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView
            editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {

//    DEBUG_LOG(@"%s", __func__);
    return self.editing ? UITableViewCellEditingStyleNone : UITableViewCellEditingStyleDelete;
}

- (void)dealloc {
    self.tokenCell = nil;
	self.tokens = nil;

    [super dealloc];
}

#pragma mark - Gesture Recognizers

// テーブルビューにジェスチャーレコグナイザーを追加する。
- (void) createGestureRecognizers {
    /*
     * 長押しレコグナイザーを追加する。
     */
    UILongPressGestureRecognizer *longPressRecognizer =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(handleLongPress:)];
    [tableView_ addGestureRecognizer:longPressRecognizer];
    
    [longPressRecognizer release];
}

// 長押しで 編集メニュー表示
- (IBAction) handleLongPress:(UILongPressGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateBegan) {
//        CGPoint location = [sender locationInView:self.view];
//        self.selectedIndexPath = [tableView_ indexPathForRowAtPoint:location];
//        TokenCell *cell = (TokenCell *) [tableView_ cellForRowAtIndexPath:_selectedIndexPath];
        [tableView_ setEditing:tableView_.editing == NO animated:YES];
        
        if (tableView_.editing == NO) {
//            [tableView_ reloadData];
        }
//        DEBUG_LOG(@"%s", __func__);
    }
}

@end
