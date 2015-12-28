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

#pragma mark - Life Cycle

- (void)dealloc {
    
    self.myNavigationBar = nil;
    self.myNavigationItem = nil;
    self.searchBar = nil;
    self.tokenCell = nil;
    self.listItems = nil;
    self.rawSentences = nil;
    self.filteredSentences = nil;
    
#if ICLOUD_ENABLD
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:iCloudDownloadCompletedNotification
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

    if (_tableView.editing)
    {// ブラウズモード >> 編集モード
        [editButton setStyle:UIBarButtonItemStyleDone];
        [editButton setTitle:@"完了"];
    } else
    {// 編集モード >> ブラウズモード
        [editButton setStyle:UIBarButtonItemStylePlain];
        [editButton setTitle:@"編集"];

#if RELOAD_WHEN_TOGGLE_EDIT
        // 4S とか遅い機種では障害が発生するので中止した。
        [_tableView reloadData];
#else
        [_tableView setNeedsLayout];
        [_tableView setNeedsDisplay];
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

//    [_tableView setBackgroundColor:kTableViewBackgroundColor];
    
    self.listItems = _rawSentences;
    self.filteredSentences = [[[NSMutableArray alloc] init] autorelease];

    _searchBar.delegate = self;
    
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
#if ICLOUD_ENABLD
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(iCloudListDownloadCompleted:)
                                                 name:iCloudDownloadCompletedNotification
                                               object:self];
#endif
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
#if 0
		[[NSBundle mainBundle] loadNibNamed:@"TokenCell" owner:self options:nil];
#else
        // リソースは使わない。
        self.tokenCell = [[TokenCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
#endif
		cell = _tokenCell;
		self.tokenCell = nil;
    }
#if 0
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
#else
    UIView *selectedBackgroudView = [[UIView alloc] init];
    
    selectedBackgroudView.backgroundColor = kSelectionColor;
    [cell setSelectedBackgroundView:selectedBackgroudView];
    [selectedBackgroudView release];
#endif

	NSDictionary *dic = [_listItems objectAtIndex:indexPath.row];

#ifdef DEBUG
//    if (((NSNumber *) dic[@"modified"]).boolValue) {
//        cell.textLabel.textColor = [UIColor orangeColor];
//    } else {
//        cell.textLabel.textColor = [UIColor blackColor];
//    }
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
            NSDictionary *dic = [_listItems objectAtIndex:indexPath.row];
            NSString *searchingToken = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsEvaluatingSentence];
            
            if ([dic[@"sentence"] isEqualToString:searchingToken])
            {// 削除対象のディクショナリーの文字列が解析対象の文字列であるならば、初期化する。
                [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:kDefaultsEvaluatingSentence];
            }
            [_listItems removeObject:dic];
            // 文章を削除したので、XML ファイルに反映する。
            [_listItems writeToFile:kLibXMLPath atomically:YES];

            // iCloud
            LibMecabSampleAppDelegate *appDelegate = (LibMecabSampleAppDelegate *)[[UIApplication sharedApplication] delegate];

#if ICLOUD_ENABLD
            if (appDelegate.use_iCloud) {
                [appDelegate saveTo_iCloud];
            }
#endif

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
            NSDictionary *dic = [_listItems[indexPath.row] retain];

            [_listItems removeObject:dic];
            if (toIndexPath.row == numRows - 1)
            {// 末端
                [_listItems addObject:dic];
            } else
            {
                [_listItems insertObject:dic atIndex:toIndexPath.row];
            }
            // 文章を移動したので、XML ファイルに反映する。
            [_listItems writeToFile:kLibXMLPath atomically:YES];

            // iCloud
            LibMecabSampleAppDelegate *appDelegate = (LibMecabSampleAppDelegate *)[[UIApplication sharedApplication] delegate];

#if ICLOUD_ENABLD
            if (appDelegate.use_iCloud) {
                [appDelegate saveTo_iCloud];
            }
#endif
            [[NSUserDefaults standardUserDefaults] setObject:dic[@"sentence"] forKey:kDefaultsEvaluatingSentence];

            [dic release];
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

    NSString *sentence = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsEvaluatingSentence];

    if ([searchBar.text length] == 0) {
        // 空の文字列をユーザーデフォルトに保持する。
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:kDefaultsSearchingToken];
        [self filterContentForSearchText:_searchBar.text];
    }
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

#pragma mark - iCloud 用リスナーのコールバック

#if ICLOUD_ENABLD
- (void) iCloudListDownloadCompleted:(id)sender {
    
    // iCloud との授受に使用するデータのパス
    NSString *agentPath = [[iCloudStorage sandboxContainerDocPath] stringByAppendingPathComponent:kLibXMLName];
    NSData *iCloudData = [NSData dataWithContentsOfFile:agentPath];
    
    if (iCloudData) {
        NSData *fileData = [NSData dataWithContentsOfFile:kLibXMLPath];
        
        if (fileData) {
            if ([fileData isEqualToData:iCloudData] == NO) {
                [FileUtil copyItemAtPath:agentPath toPath:kLibXMLPath];
                DEBUG_LOG(@"%s Library.xml を置換しました。", __func__);
            }
        } else {
            [FileUtil copyItemAtPath:agentPath toPath:kLibXMLPath];
            DEBUG_LOG(@"%s Library.xml を置換しました。", __func__);
        }
    }
    self.listItems = [NSMutableArray arrayWithArray:[NSArray arrayWithContentsOfFile:kLibXMLPath]];
    [_tableView reloadData];
}
#endif
@end
