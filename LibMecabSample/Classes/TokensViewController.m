//
//  TokensViewController.m
//  LibMecabSample
//
//  Created by tmatsugaki on 2015/11/24.
//

#import "TokensViewController.h"
#import "Utility.h"
#import "LibMecabSampleAppDelegate.h"
#import "FileUtil.h"

@implementation TokensViewController

@synthesize myNavigationBar=_myNavigationBar;
@synthesize myNavigationItem=_myNavigationItem;
@synthesize searchBar=_searchBar;
@synthesize tableView=_tableView;
@synthesize tokenCell=_tokenCell;
@synthesize rawSentences=_rawSentences;
@synthesize filteredSentences=_filteredSentences;
@synthesize edit_mode=_edit_mode;
@synthesize smudged=_smudged;

#pragma mark - Life Cycle

- (void)dealloc {
    
    self.myNavigationBar = nil;
    self.myNavigationItem = nil;
    self.searchBar = nil;
    self.tokenCell = nil;
//    self.listItems = nil;
    self.rawSentences = nil;
    self.filteredSentences = nil;
    
#if ICLOUD_ENABLD
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:iCloudDownloadCompletedNotification
                                                  object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:iCloudSyncNotification
                                                  object:self];
#endif

    [super dealloc];
}

#pragma mark - IBAction

- (void) cancel:(id)sender {
    [self dismissMe];
}

- (void) toggleEdit:(id)sender {
    
    UIBarButtonItem *editButton = sender;

    [_tableView setEditing:_tableView.editing == NO animated:YES];

    _edit_mode = _tableView.editing;
    
    [self becomeFirstResponder];
    
    if (_tableView.editing)
    {// ブラウズモード >> 編集モード
        [editButton setStyle:UIBarButtonItemStyleDone];
        [editButton setTitle:NSLocalizedString(@"done", @"完了")];
    } else
    {// 編集モード >> ブラウズモード
        [editButton setStyle:UIBarButtonItemStylePlain];
        [editButton setTitle:NSLocalizedString(@"edit", @"編集")];

#if ICLOUD_ENABLD
        if (_smudged) {
            // iCloud に反映する。
            LibMecabSampleAppDelegate *appDelegate = (LibMecabSampleAppDelegate *)[[UIApplication sharedApplication] delegate];
            
            if (appDelegate.use_iCloud) {
                [appDelegate saveTo_iCloud];
            }
            _smudged = NO;
        }
#endif
    }
    [_myNavigationItem setRightBarButtonItem:editButton];

#if RELOAD_WHEN_TOGGLE_EDIT
    // 4S とか遅い機種では障害が発生するので中止した。
    [_tableView reloadData];
#endif
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

#if 0
- (BOOL) canBecomeFirstResponder {
    return YES;
}

- (BOOL) canResignFirstResponder {
    return YES;
}
#endif

#pragma mark - UIViewController

- (NSUInteger) getSelectedIndex {
    
    NSUInteger selectedIndex = NSNotFound;
    NSString *sentence = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsEvaluatingSentence];
    
    if ([sentence length]) {
        for (NSUInteger i = 0; i < [_listItems count]; i++) {
            NSDictionary *dic = _listItems[i];
            if ([dic[@"sentence"] isEqualToString:sentence]) {
                selectedIndex = i;
                break;
            }
        }
    }
    return selectedIndex;
}

// タイトルバーのメンテ
- (void) setupTitle {
    
    NSUInteger selectedIndex = [self getSelectedIndex];
    
    if ([_listItems count]) {
        if (selectedIndex != NSNotFound) {
            _myNavigationItem.title = [NSString stringWithFormat:@"%@ (%u:%lu)", NSLocalizedString(@"examplesLong", @"文例"), selectedIndex + 1, (unsigned long)[_listItems count]];
        } else {
            _myNavigationItem.title = [NSString stringWithFormat:@"%@ (%lu)", NSLocalizedString(@"examplesLong", @"文例"), (unsigned long)[_listItems count]];
        }
    } else {
        _myNavigationItem.title = NSLocalizedString(@"examplesLong", @"文例");
    }
}

- (void)viewDidLoad {

//    DEBUG_LOG(@"%s", __func__);

    [super viewDidLoad];

//    [_tableView setBackgroundColor:kTableViewBackgroundColor];
    
    self.listItems = _rawSentences;
    self.filteredSentences = [[[NSMutableArray alloc] init] autorelease];

    _searchBar.delegate = self;
    
    [_tableView becomeFirstResponder];

//    _myNavigationItem.title = NSLocalizedString(@"examplesLong", @"文例");
    [self setupTitle];
    
    [_searchBar setPlaceholder:NSLocalizedString(@"require_token", @"検索する文字列を入力してください。")];
    
    // ナビゲーションアイテムの初期化（閉じるボタン）
    _myNavigationItem.leftBarButtonItem
    = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"close", @"閉じる")
                                        style:UIBarButtonItemStylePlain
                                       target:self
                                       action:@selector(cancel:)] autorelease];
    _myNavigationItem.leftBarButtonItem.possibleTitles = [NSSet setWithObjects:@"閉じる", nil];
    _myNavigationItem.leftBarButtonItem.tintColor = kEnabledTextColor;
    // ナビゲーションアイテムの初期化（編集ボタン）
    _myNavigationItem.rightBarButtonItem
    = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"edit", @"編集")
                                        style:UIBarButtonItemStylePlain
                                       target:self
                                       action:@selector(toggleEdit:)] autorelease];
    _myNavigationItem.rightBarButtonItem.possibleTitles = [NSSet setWithObjects:NSLocalizedString(@"edit", @"編集"), NSLocalizedString(@"done", @"完了"), nil];
    _myNavigationItem.rightBarButtonItem.tintColor = kEnabledTextColor;

    //
    NSString *searchingToken = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsSearchingToken];

    if ([searchingToken length])
    {// 検索中の文字列がある場合は、サーチバーに設定し、フィルタリングする。
        _searchBar.text = searchingToken;
        [self filterContentForSearchText:searchingToken];
        [_tableView reloadData];
    }
#if ICLOUD_ENABLD
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(iCloudListDownloadCompleted:)
                                                 name:iCloudDownloadCompletedNotification
                                               object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(iCloudListDownloadCompleted:)
                                                 name:iCloudSyncNotification
                                               object:self];
#endif
    _edit_mode = NO;
    _smudged = NO;
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    NSString *sentence = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsEvaluatingSentence];

    if ([sentence length]) {
        NSUInteger index = NSNotFound;
        
        for (NSUInteger i = 0; i < [_listItems count]; i++) {
            NSDictionary *dic = _listItems[i];
            if ([dic[@"sentence"] isEqualToString:sentence]) {
                index = i;
                break;
            }
        }
        
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
#if ICLOUD_ENABLD
    LibMecabSampleAppDelegate *appDelegate = (LibMecabSampleAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDelegate.use_iCloud) {
        // 【必須】サンドボックス・コンテナに Library.xml を取得する。
        [appDelegate.iCloudStorage requestListing:kLibXMLName];
    }
#endif
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
        // リソースは使わない。
        self.tokenCell = [[TokenCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
		cell = _tokenCell;
		self.tokenCell = nil;
    }
    UIView *selectedBackgroudView = [[UIView alloc] init];

    selectedBackgroudView.backgroundColor = kSelectionColor;
    [cell setSelectedBackgroundView:selectedBackgroudView];
    [selectedBackgroudView release];

	NSDictionary *dic = [_listItems objectAtIndex:indexPath.row];

#ifdef DEBUG
    if (((NSNumber *) dic[@"modified"]).boolValue) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
#endif
    cell.textLabel.text = dic[@"sentence"];
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

    NSDictionary *dic = [_listItems objectAtIndex:indexPath.row];
    [[NSUserDefaults standardUserDefaults] setObject:dic[@"sentence"] forKey:kDefaultsEvaluatingSentence];
    // 画面を閉じる
    [self performSelector:@selector(dismissMe) withObject:nil afterDelay:0.5];

    // 検索中の文字列をユーザーデフォルトに保持する。
    [[NSUserDefaults standardUserDefaults] setObject:_searchBar.text forKey:kDefaultsSearchingToken];
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
            NSDictionary *dic = [[_listItems objectAtIndex:indexPath.row] retain];
            NSString *searchingToken = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsEvaluatingSentence];
            
            if ([dic[@"sentence"] isEqualToString:searchingToken])
            {// 削除対象のディクショナリーの文字列が解析対象の文字列であるならば、初期化する。
                [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:kDefaultsEvaluatingSentence];
            }
            // 生リストのオブジェクトを削除する。
            [_rawSentences removeObject:dic];
            // フィルタリングされたリストのオブジェクトを削除する。
            [_listItems removeObject:dic];
            // 文章を削除したので、XML ファイルに反映する。
            [_rawSentences writeToFile:kLibXMLPath atomically:YES];
            [dic release];

#if ICLOUD_ENABLD
            if (_edit_mode == NO) {
                // iCloud に反映する。
                LibMecabSampleAppDelegate *appDelegate = (LibMecabSampleAppDelegate *)[[UIApplication sharedApplication] delegate];
                
                if (appDelegate.use_iCloud) {
                    [appDelegate saveTo_iCloud];
                }
            } else {
                _smudged = YES;
            }
#endif

            [self setupTitle];
            
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
#if FREELY_DELETE
    // フィルタリングされても編集できるようにした
    return [_listItems count] > 1;
#else
    return (_listItems == _rawSentences) && [_listItems count] > 1;
#endif
}

// Override to support conditional editing of the table view.
- (BOOL) tableView:(UITableView *)tableView
canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    DEBUG_LOG(@"%s", __func__);

    // 移動できるのは、少なくとも複数セルがある場合
#if FREELY_MOVE
    return tableView.editing && [_listItems count] > 1;
#else
    // 移動できるのは、検索中でない場合
    return tableView.editing && (_listItems == _rawSentences) && [_listItems count] > 1;
#endif
}

// Override to support conditional editing of the table view.
- (void) tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)indexPath
       toIndexPath:(NSIndexPath *)toIndexPath {
    
//    DEBUG_LOG(@"%s", __func__);

    @try {
        if (indexPath.row != toIndexPath.row) {
            NSDictionary *curObj = [_listItems[indexPath.row] retain];

#if FREELY_MOVE
            NSUInteger numRows = [self tableView:tableView numberOfRowsInSection:0];
            NSDictionary *toObj = [_listItems objectAtIndex:toIndexPath.row];
            NSDictionary *lastObj = [_listItems lastObject];
            BOOL toTheEnd = NO;

            [_listItems removeObject:curObj];
            if (toIndexPath.row == numRows - 1)
            {// 末端
                [_listItems addObject:curObj];
                toTheEnd = YES;
            } else
            {
                [_listItems insertObject:curObj atIndex:toIndexPath.row];
            }
            if (_listItems != _rawSentences) {
                NSUInteger toIndex = NSNotFound;

                if (toTheEnd)
                {// 末端
                    toIndex = [_rawSentences indexOfObject:lastObj];
                } else
                {
                    toIndex = [_rawSentences indexOfObject:toObj];
                }
                if (toIndex != NSNotFound) {
                    [_rawSentences removeObject:curObj];
                    [_rawSentences insertObject:curObj atIndex:toIndex];
                }
            }
#else
            NSUInteger numRows = [self tableView:tableView numberOfRowsInSection:0];

            [_listItems removeObject:dic];
            if (toIndexPath.row == numRows - 1)
            {// 末端
                [_listItems addObject:dic];
            } else
            {
                [_listItems insertObject:dic atIndex:toIndexPath.row];
            }
#endif
            // 文章を移動したので、XML ファイルに反映する。
            [_rawSentences writeToFile:kLibXMLPath atomically:YES];

#if ICLOUD_ENABLD
            _smudged = YES;
#endif
            [[NSUserDefaults standardUserDefaults] setObject:curObj[@"sentence"] forKey:kDefaultsEvaluatingSentence];

            [curObj release];
        }
    }
    @catch (NSException *exception) {
    }
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView
            editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {

//    DEBUG_LOG(@"%s[%d]", __func__, tableView.editing);

//    return tableView.editing ? UITableViewCellEditingStyleNone : UITableViewCellEditingStyleDelete;
    return UITableViewCellEditingStyleDelete;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 29.0;
}

- (CGFloat)tableView:(UITableView *)tableView
heightForFooterInSection:(NSInteger)section {
    
    return 1.0;
}

#pragma mark - UISearchBarDelegate

- (BOOL) searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    
    if (searchBar == _searchBar) {
        LibMecabSampleAppDelegate *appDelegate = (LibMecabSampleAppDelegate *)[[UIApplication sharedApplication] delegate];

        if (appDelegate.incrementalSearch) {
            [_searchBar setReturnKeyType:UIReturnKeyDone];
        } else {
            [_searchBar setReturnKeyType:UIReturnKeySearch];
        }
        
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
    LibMecabSampleAppDelegate *appDelegate = (LibMecabSampleAppDelegate *)[[UIApplication sharedApplication] delegate];

    if (appDelegate.incrementalSearch) {
        // フィルタリングしリロードする。
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
    // フィルタリングしリロードする。
    [self filterContentForSearchText:searchBar.text];
    [_tableView reloadData];

    // キーボードを閉じる（FirstResponder をキャンセルする）
    [_searchBar resignFirstResponder];
}

// called when cancel button pressed
- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    DEBUG_LOG(@"%s", __func__);

    NSString *sentence = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsEvaluatingSentence];

    // 検索中の文字列をユーザーデフォルトに保持する。
    [[NSUserDefaults standardUserDefaults] setObject:searchBar.text forKey:kDefaultsSearchingToken];
    // フィルタリングしリロードする。
    [self filterContentForSearchText:searchBar.text];
    [_tableView reloadData];
    
    if ([sentence length]) {
        NSUInteger index = NSNotFound;
        
        for (NSUInteger i = 0; i < [_listItems count]; i++) {
            NSDictionary *dic = _listItems[i];
            if ([dic[@"sentence"] isEqualToString:sentence]) {
                index = i;
                break;
            }
        }        
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

// 編集ボタンの制御（フィルタリングされても編集できるようにした）
- (void) maintainEditButton:(NSString *)searchText {

#if FREELY_DELETE
    _myNavigationItem.rightBarButtonItem.enabled = YES;
#else
    if ([searchText length]) {
        _myNavigationItem.rightBarButtonItem.enabled = NO;
    } else {
        _myNavigationItem.rightBarButtonItem.enabled = YES;
    }
#endif
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
        for (NSUInteger i = 0; i < [_rawSentences count]; i++)
        {
            NSDictionary *sentenceDic = _rawSentences[i];
            NSString *sentence = sentenceDic[@"sentence"];
            BOOL match = NO;
            
            NSArray *tokens = [searchText componentsSeparatedByString:@" "];
            
            for (NSString *token in tokens) {
                range = [sentence length] ? [sentence rangeOfString:token options:opt] : NSMakeRange(NSNotFound, 0);
                if (range.length)
                {
                    [_filteredSentences addObject:sentenceDic];
                    match = YES;
                    break;
                }
            }
        }
        self.listItems = _filteredSentences;
    } else {
        self.listItems = _rawSentences;
    }
    // 編集ボタンの制御
    [self maintainEditButton:searchText];
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

#pragma mark - iCloud 用リスナーのコールバック

#if ICLOUD_ENABLD
- (void) iCloudListDownloadCompleted:(id)sender {
    
    if ([NSThread isMainThread] == NO)
    {// メインスレッドで実行する。
        [self performSelectorOnMainThread:@selector(iCloudListDownloadCompleted:)
                               withObject:sender
                            waitUntilDone:YES];  // 同期する。
    } else {
        // iCloud との授受に使用するデータのパス
        NSString *agentPath = [[iCloudStorage sandboxContainerDocPath] stringByAppendingPathComponent:kLibXMLName];
        NSData *iCloudData = [NSData dataWithContentsOfFile:agentPath];
        
        if (iCloudData) {
            NSData *fileData = [NSData dataWithContentsOfFile:kLibXMLPath];
            
            if (fileData) {
                if ([fileData isEqualToData:iCloudData] == NO) {
                    [FileUtil copyItemAtPath:agentPath toPath:kLibXMLPath];
#if (ICLOUD_LOG == 1)
                    DEBUG_LOG(@"%s Library.xml を置換しました。", __func__);
#endif
                }
            } else {
                [FileUtil copyItemAtPath:agentPath toPath:kLibXMLPath];
#if (ICLOUD_LOG == 1)
                DEBUG_LOG(@"%s Library.xml を置換しました。", __func__);
#endif
            }
        }
        self.rawSentences = [NSMutableArray arrayWithArray:[NSArray arrayWithContentsOfFile:kLibXMLPath]];
#if 0
        self.listItems = _rawSentences;
#else
        // フィルタリングしリロードする。
        [self filterContentForSearchText:_searchBar.text];
#endif
        [self setupTitle];

        [_tableView reloadData];
    }
}
#endif
@end
