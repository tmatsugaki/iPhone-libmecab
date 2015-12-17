//
//  TokensViewController.m
//  LibMecabSample
//
//  Created by tmatsugaki on 2015/11/24.
//

#import "TokensViewController.h"
#import "Utility.h"

@implementation TokensViewController

@synthesize myNavigationBar=_myNavigationBar;
@synthesize myNavigationItem=_myNavigationItem;
@synthesize searchBar=_searchBar;
@synthesize tableView=_tableView;
@synthesize tokenCell=_tokenCell;
@synthesize listItems=_listItems;
@synthesize rawSentences=_rawSentences;
@synthesize filteredSentences=_filteredSentences;

#pragma mark - Life Cycle

- (void)dealloc {
    
    self.myNavigationBar = nil;
    self.myNavigationItem = nil;
    self.searchBar = nil;
    self.tokenCell = nil;
    self.listItems = nil;
    self.rawSentences = nil;
    self.filteredSentences = nil;
    
    [super dealloc];
}

#pragma mark - IBAction

- (void) cancel:(id)sender {
    [self dismissMe];
}

- (void) toggleEdit:(id)sender {
    
//    UIBarButtonItem *editButton = _myNavigationItem.rightBarButtonItem;
    UIBarButtonItem *editButton = sender;

    [_tableView setEditing:_tableView.editing == NO animated:YES];

    if (_tableView.editing)
    {// ブラウズモード >> 編集モード
        [editButton setStyle:UIBarButtonItemStyleDone];
        [editButton setTitle:@"完了"];
//        editButton.tintColor = [UIColor colorWithRed:0.0/256.0 green:122.0/256.0 blue:255.0/256.0 alpha:1.0];
    } else
    {// 編集モード >> ブラウズモード
        [editButton setStyle:UIBarButtonItemStylePlain];
        [editButton setTitle:@"編集"];
//        editButton.tintColor = [UIColor grayColor];

#if RELOAD_WHEN_TOGGLE_EDIT
        [_tableView reloadData];
#else
        [self.view setNeedsLayout];
        [self.view setNeedsDisplay];
#endif
    }
    [_myNavigationItem setRightBarButtonItem:editButton];
}

- (id) initWithNibName:(NSString *)nibNameOrNil
                bundle:(NSBundle *)nibBundleOrNil
        sentencesArray:(NSMutableArray *)sentencesArray
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        self.rawSentences = sentencesArray;
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

//    DEBUG_LOG(@"%s", __func__);

    [super viewDidLoad];

    self.listItems = _rawSentences;
    self.filteredSentences = [[[NSMutableArray alloc] init] autorelease];

    _searchBar.delegate = self;
    
//    [self createGestureRecognizers];
    [_tableView becomeFirstResponder];

    // ナビゲーションアイテムの初期化（閉じるボタン）
    _myNavigationItem.leftBarButtonItem
    = [[[UIBarButtonItem alloc] initWithTitle:@"閉じる"
                                        style:UIBarButtonItemStylePlain
                                       target:self
                                       action:@selector(cancel:)] autorelease];
    _myNavigationItem.leftBarButtonItem.possibleTitles = [NSSet setWithObjects:@"閉じる", nil];
    _myNavigationItem.leftBarButtonItem.tintColor = [UIColor colorWithRed:0.0/256.0 green:122.0/256.0 blue:255.0/256.0 alpha:1.0];
    // ナビゲーションアイテムの初期化（編集ボタン）
    _myNavigationItem.rightBarButtonItem
    = [[[UIBarButtonItem alloc] initWithTitle:@"編集"
                                        style:UIBarButtonItemStylePlain
                                       target:self
                                       action:@selector(toggleEdit:)] autorelease];
    _myNavigationItem.rightBarButtonItem.possibleTitles = [NSSet setWithObjects:@"編集", @"完了", nil];
    _myNavigationItem.rightBarButtonItem.tintColor = [UIColor colorWithRed:0.0/256.0 green:122.0/256.0 blue:255.0/256.0 alpha:1.0];

    //
    NSString *searchingToken = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsSearchingToken];

    if ([searchingToken length])
    {// 検索中の文字列がある場合は、サーチバーに設定し、フィルタリングする。
        _searchBar.text = searchingToken;
        [self filterContentForSearchText:searchingToken];
    }
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    NSString *sentence = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsSentence];

    if ([sentence length]) {
        NSUInteger index = [_listItems indexOfObject:sentence];
        
        if (index != NSNotFound) {
            @try {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                
                [_tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:UITableViewScrollPositionTop];
            }
            @catch (NSException *exception) {
            }
        }
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    // キーボードフォーカスを破棄する。
    [_searchBar resignFirstResponder];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

//    DEBUG_LOG(@"%s", __func__);

    if (_listItems) {
		return [_listItems count];
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    DEBUG_LOG(@"%s Count:%lu Row:%ld", __func__, (unsigned long)[_listItems count], (long)indexPath.row);

    static NSString *CellIdentifier = @"TokenCell";
    
    TokenCell *cell = (TokenCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
#if 0
		[[NSBundle mainBundle] loadNibNamed:@"TokenCell" owner:self options:nil];
#else
        // リソースは使わない。
        self.tokenCell = [[TokenCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
#endif
		cell = _tokenCell;
		self.tokenCell = nil;
    }
    
	NSString *str = [_listItems objectAtIndex:indexPath.row];
    NSArray *items = [str componentsSeparatedByString:@","];

    if ([items count] > 1 && [items[1] isEqualToString:@"™"]) {
        cell.textLabel.textColor = [UIColor redColor];
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
    }
    cell.textLabel.text = items[0];
    return cell;
}

- (void) dismissMe {
    // 画面を閉じる
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    DEBUG_LOG(@"%s", __func__);

    // 検索フィールドを非アクティブにする。
    [_searchBar resignFirstResponder];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString *str = [_listItems objectAtIndex:indexPath.row];
    [[NSUserDefaults standardUserDefaults] setObject:str forKey:kDefaultsSentence];
    // 画面を閉じる
    [self performSelector:@selector(dismissMe) withObject:nil afterDelay:0.5];
}

- (NSString *) tableView:(UITableView *)tableView
titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return @"削除";
}

// 【注意】キャンセルされた場合に、layoutSubviews が呼ばれる。
- (void) tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
 forRowAtIndexPath:(NSIndexPath *)indexPath {

//    DEBUG_LOG(@"%s", __func__);

    @try {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            [_listItems removeObject:[_listItems objectAtIndex:indexPath.row]];
            // 文章を削除したので、XML ファイルに反映する。
            [_listItems writeToFile:kLibXMLPath atomically:YES];

#if DELETE_ANIMATION
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            [UIView beginAnimations:nil context:context];
            [UIView setAnimationDuration:0.5];
            [UIView setAnimationTransition:UIViewAnimationTransitionNone
                                   forView:self.view
                                     cache:NO];
            [tableView reloadData];
            [UIView commitAnimations];
#else
            [tableView reloadData];
#endif
        }
    }
    @catch (NSException *exception) {
    }
}

- (BOOL) tableView:(UITableView *)tableView
canEditRowAtIndexPath:(NSIndexPath *)indexPath {

//    DEBUG_LOG(@"%s", __func__);

    // 削除できるのは、検索中でなく複数セルがある場合
    // 【注意】最後のトークン消すと画面を終われなくなる。
    return (_listItems == _rawSentences) && [_listItems count] > 1;
}

// Override to support conditional editing of the table view.
- (BOOL) tableView:(UITableView *)tableView
canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    DEBUG_LOG(@"%s", __func__);

    // 移動できるのは、検索中でなくテーブルビューが編集中で複数セルがある場合
    return tableView.editing && (_listItems == _rawSentences) && [_listItems count] > 1;
}

// Override to support conditional editing of the table view.
- (void) tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)indexPath
       toIndexPath:(NSIndexPath *)toIndexPath {
    
//    DEBUG_LOG(@"%s", __func__);

    @try {
        if (indexPath.row != toIndexPath.row) {
            NSUInteger numRows = [self tableView:tableView numberOfRowsInSection:0];
            NSString *token = [_listItems[indexPath.row] retain];

            [_listItems removeObject:token];
            if (toIndexPath.row == numRows - 1)
            {// 末端
                [_listItems addObject:token];
            } else
            {
                [_listItems insertObject:token atIndex:toIndexPath.row];
            }
            // 文章を移動したので、XML ファイルに反映する。
            [_listItems writeToFile:kLibXMLPath atomically:YES];

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

#pragma mark - UISearchBarDelegate

- (BOOL) searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    
    if (searchBar == _searchBar) {
        [_searchBar setShowsCancelButton:YES animated:YES];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) searchBarShouldEndEditing:(UISearchBar *)searchBar {
    
    if (searchBar == _searchBar) {
        [_searchBar setShowsCancelButton:NO animated:YES];
        return YES;
    } else {
        return NO;
    }
}

// インクリメンタルサーチ
- (void) searchBar:(UISearchBar *)searchBar
     textDidChange:(NSString *)searchText
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kIncrementalSearchKey]) {
        [self filterContentForSearchText:searchBar.text];
        [_tableView reloadData];
    }
}

// called when keyboard search button pressed
- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
//    DEBUG_LOG(@"%s", __func__);

    // 検索中の文字列をユーザーデフォルトに保持する。
    [[NSUserDefaults standardUserDefaults] setObject:searchBar.text forKey:kDefaultsSearchingToken];
    [self filterContentForSearchText:searchBar.text];
    [_tableView reloadData];

    // キーボードを閉じる（FirstResponder をキャンセルする）
    [_searchBar resignFirstResponder];
}

// called when cancel button pressed
- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    DEBUG_LOG(@"%s", __func__);

    NSString *sentence = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsSentence];

    if ([searchBar.text length] == 0) {
        // 空の文字列をユーザーデフォルトに保持する。
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:kDefaultsSearchingToken];
        [self filterContentForSearchText:_searchBar.text];
    }
    [_tableView reloadData];
    
    if ([sentence length]) {
        NSUInteger index = [_listItems indexOfObject:sentence];
        
        if (index != NSNotFound) {
            @try {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                
                [_tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:UITableViewScrollPositionTop];
            }
            @catch (NSException *exception) {
            }
        }
    }
    // キーボードを閉じる（FirstResponder をキャンセルする）
    [_searchBar resignFirstResponder];
}

- (void) filterContentForSearchText:(NSString *)searchText
{
//    DEBUG_LOG(@"%s", __func__);

    if ([searchText length]) {
        [_filteredSentences removeAllObjects]; // First clear the filtered array.
        
        // オプションは、「ウムラウト関連を無視」、「シフトケースを無視」
        NSStringCompareOptions opt = (NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch);
        NSRange range;
        
        /*
         Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
         */
        for (NSString *sentence in _rawSentences)
        {
            BOOL match = NO;
            
            NSArray *tokens = [searchText componentsSeparatedByString:@" "];
            
            for (NSString *token in tokens) {
                range = [sentence length] ? [sentence rangeOfString:token options:opt] : NSMakeRange(NSNotFound, 0);
                if (range.length)
                {
                    [_filteredSentences addObject:sentence];
                    match = YES;
                    break;
                }
            }
        }
        self.listItems = _filteredSentences;
        _myNavigationItem.rightBarButtonItem.enabled = NO;
    } else {
        self.listItems = _rawSentences;
        _myNavigationItem.rightBarButtonItem.enabled = YES;
    }
}

#pragma mark - UIKeyboard

// キーボードの大きさ分、ビューを縮小する。
// 【注意】UIKeyboardWillShowNotification　はビューがインスタンス化されていないと発生しない。
// 【注意】キーボード切り換えでも、UIKeyboardWillShowNotification が発生することに注意する。
- (void) keyboardWillShow:(NSNotification *)aNotification
{
    CGRect endFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [[[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    // 【注意】keyboardWillShow では、リサイズ対象のビューはキーボード無しの状態のビューにしておく必要がある。
    CGRect tableFrame = _tableView.frame;
    CGFloat maxHeight = self.view.frame.size.height - tableFrame.origin.y;
    tableFrame.size.height = maxHeight;
    _tableView.frame = tableFrame;
    
    (void) [Utility keyboardShowAnimation:_tableView
                             keyboardRect:endFrame
                                 duration:duration];
}

// キーボードの大きさ分、ビューを伸長する。
- (void) keyboardWillHide:(NSNotification *)aNotification
{
    CGRect endFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [[[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [Utility keyboardHideAnimation:_tableView
                      keyboardRect:endFrame
                          duration:duration];
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
    [_tableView addGestureRecognizer:longPressRecognizer];
    
    [longPressRecognizer release];
}

// 長押しで 編集メニュー表示
- (IBAction) handleLongPress:(UILongPressGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateBegan) {
//        CGPoint location = [sender locationInView:self.view];
//        self.selectedIndexPath = [tableView_ indexPathForRowAtPoint:location];
//        TokenCell *cell = (TokenCell *) [tableView_ cellForRowAtIndexPath:_selectedIndexPath];
        [_tableView setEditing:_tableView.editing == NO animated:YES];
        
        if (_tableView.editing == NO) {
//            [tableView_ reloadData];
        }
//        DEBUG_LOG(@"%s", __func__);
    }
}

@end
