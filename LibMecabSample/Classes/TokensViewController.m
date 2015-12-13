//
//  TokensViewController.m
//  LibMecabSample
//
//  Created by tmatsugaki on 2015/11/24.
//

#import "TokensViewController.h"

@implementation TokensViewController

@synthesize myNavigationBar=_myNavigationBar;
@synthesize myNavigationItem=_myNavigationItem;
@synthesize editButton=_editButton;
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
    self.editButton = nil;
    self.searchBar = nil;
    self.tokenCell = nil;
    self.listItems = nil;
    self.rawSentences = nil;
    self.filteredSentences = nil;
    
    [super dealloc];
}

#pragma mark - IBAction

- (IBAction) cancel:(id)sender {
    [self dismissMe];
}

- (IBAction) toggleEdit:(id)sender {
    
//    UIBarButtonItem *editButton = myNavigationItem.rightBarButtonItems[0];

    [_tableView setEditing:_tableView.editing == NO animated:YES];

    if (_tableView.editing)
    {// ブラウズモード >> 編集モード
        _editButton.style = UIBarButtonItemStyleDone;
        _editButton.title = @"完了";
    } else
    {// 編集モード >> ブラウズモード
        _editButton.style = UIBarButtonItemStylePlain;
        _editButton.title = @"編集";

        [_tableView reloadData];
    }
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
	[super viewDidLoad];
    
    self.listItems = _rawSentences;
    self.filteredSentences = [[[NSMutableArray alloc] init] autorelease];

    _searchBar.delegate = self;
    
//    [self createGestureRecognizers];
    [_tableView becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSString *searchingToken = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsSearchingToken];
    NSString *sentence = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsSentence];
    
    if ([searchingToken length])
    {// 検索中の文字列がある場合は、サーチバーに設定し、フィルタリングする。
        _searchBar.text = searchingToken;
        [self filterContentForSearchText:searchingToken];
    }
    
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
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (_listItems) {
		return [_listItems count];
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
		cell = _tokenCell;
		self.tokenCell = nil;
    }
    
	NSString *str = [_listItems objectAtIndex:indexPath.row];
    cell.textLabel.text = str;
    return cell;
}

- (void) dismissMe {
    // 画面を閉じる
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
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
- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

//    DEBUG_LOG(@"%s", __func__);

    @try {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            [_listItems removeObject:[_listItems objectAtIndex:indexPath.row]];
            [_listItems writeToFile:kLibXMLPath atomically:YES];
            
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
    return [_listItems count] > 1;
}

// Override to support conditional editing of the table view.
- (BOOL) tableView:(UITableView *)tableView
canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    DEBUG_LOG(@"%s", __func__);
    return tableView.editing && [_listItems count] > 1;
}

// Override to support conditional editing of the table view.
- (void) tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)indexPath
       toIndexPath:(NSIndexPath *)toIndexPath {
    
//    DEBUG_LOG(@"%s [%ld]->[%ld]", __func__, (long)indexPath.row, (long)toIndexPath.row);
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

- (void) searchBar:(UISearchBar *)searchBar
     textDidChange:(NSString *)searchText
{
}

// called when keyboard search button pressed
- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // 検索中の文字列をユーザーデフォルトに保持する。
    [[NSUserDefaults standardUserDefaults] setObject:searchBar.text forKey:kDefaultsSearchingToken];
    [self filterContentForSearchText:searchBar.text];

    // キーボードを閉じる（FirstResponder をキャンセルする）
    [_searchBar resignFirstResponder];
    [_tableView reloadData];
}

// called when cancel button pressed
- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if ([searchBar.text length] == 0) {
        // 空の文字列をユーザーデフォルトに保持する。
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:kDefaultsSearchingToken];
        [self filterContentForSearchText:_searchBar.text];
    }
    // キーボードを閉じる（FirstResponder をキャンセルする）
    [_searchBar resignFirstResponder];
    [_tableView reloadData];
}

- (void) filterContentForSearchText:(NSString *)searchText
{
    if ([searchText length]) {
        [_filteredSentences removeAllObjects]; // First clear the filtered array.
        
        // オプションは、「ウムラウト関連を無視」、「シフトケースを無視」
        NSStringCompareOptions opt = (NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch);
        NSRange range;
        
        @try {
            /*
             Search the main list for products whose type matches the scope (if selected) and whose name matches searchText; add items that match to the filtered array.
             */
            for (NSString *sentence in _rawSentences)
            {
                BOOL match = NO;
                
                NSArray *tokens = [[searchText componentsSeparatedByString:@" "] retain];   // ちょっとの間 retain
                
                for (NSString *token in tokens) {
                    range = [sentence length] ? [sentence rangeOfString:token options:opt] : NSMakeRange(NSNotFound, 0);
                    if (range.length)
                    {
                        [_filteredSentences addObject:sentence];
                        match = YES;
                        break;
                    }
                }
                [tokens release];
            }
        }
        @catch (NSException *exception) {
            DEBUG_LOG(@"%s %@", __func__, exception);
        }
        self.listItems = _filteredSentences;
    } else {
        self.listItems = _rawSentences;
    }
}

#pragma mark - UIKeyboard用ツール

// 【注意】ローテーションで width/height を入れ替えること！！
- (CGFloat) keyboardHeight:(CGRect)keyboardRect {
    
    CGFloat height;
    
    //    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    switch ((int) orientation) {
        case UIDeviceOrientationLandscapeRight:     // 90度
        case UIDeviceOrientationLandscapeLeft:      // 270度
            height = keyboardRect.size.width;
            break;
        case UIDeviceOrientationPortrait:           // 0度
        case UIDeviceOrientationPortraitUpsideDown: // 180度
        default:
            height = keyboardRect.size.height;
            break;
    }
    return height;
}

- (void) ViewHeightChangeAnimation:(UIView *)view
                             delta:(CGFloat)delta
                          duration:(NSTimeInterval)duration {
    
    CGRect frame = view.frame;
    
    frame.size.height += delta;
    [UIView animateWithDuration:duration
                     animations:^{
                         [view setFrame:frame];
                     }
                     completion:^(BOOL finished) {
                     }];
}

/*******************************************************************************
 * 基本的にキーボードは遠くから来て、遠くに去って行く！！
 * ビューの管理はキーボードレクタングルに頼るのではなく、ビューのバウンダリを自前できちんと管理すること。
 *******************************************************************************/
// キーボードを表示する余地がない場合は、キーボードを表示しない。
// キーボード表示の可否は、ビューにキーボードを表示後も44ピクセルの余地の有無で決める。
- (BOOL) keyboardShowAnimation:(UIView *)view
                  keyboardRect:(CGRect)keyboardRect
                      duration:(NSTimeInterval)duration {
    
    CGFloat viewHeight = view.bounds.size.height;
    CGFloat keyboardHeight = [self keyboardHeight:keyboardRect];
    BOOL result = NO;
    
    if (viewHeight > keyboardHeight)
    {
        [self ViewHeightChangeAnimation:view
                                  delta:-keyboardHeight
                               duration:duration];
        result = YES;
    } else {
#ifdef DEBUG
        NSAssert(viewHeight > keyboardHeight, @"キーボード出せない！！");
#endif
    }
    return result;
}

- (void) keyboardHideAnimation:(UIView *)view
                  keyboardRect:(CGRect)keyboardRect
                      duration:(NSTimeInterval)duration {
    
    [self ViewHeightChangeAnimation:view
                              delta:[self keyboardHeight:keyboardRect]
                           duration:duration];
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
    
    (void) [self keyboardShowAnimation:_tableView
                          keyboardRect:endFrame
                              duration:duration];
}

// キーボードの大きさ分、ビューを伸長する。
- (void) keyboardWillHide:(NSNotification *)aNotification
{
    CGRect endFrame   = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [[[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [self keyboardHideAnimation:_tableView
                   keyboardRect:endFrame
                       duration:duration];
    
    _tableView.hidden = NO;
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
