//
//  LibMecabSampleViewController.m
//  LibMecabSample
//
//  Created by Watanabe Toshinori on 10/12/27.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import "definitions.h"
#import "LibMecabSampleViewController.h"
#import "Mecab.h"
#import "Node.h"
#import "MecabPatch.h"
#import "Utility.h"
#import "LibMecabSampleAppDelegate.h"
#import "FileUtil.h"
#import "NSString+TM.h"

//#import "CloudKit/CKContainer.h"
//#import "CloudKit/CKRecordID.h"
//#import "CloudKit/CKRecord.h"
//#import "CloudKit/CKFetchRecordsOperation.h"
//#import "CloudKit/CKDatabase.h"

@implementation LibMecabSampleViewController

@synthesize textField=_textField;
@synthesize tableView=_tableView;
@synthesize nodeCell=_nodeCell;
@synthesize smallNodeCell=_smallNodeCell;
@synthesize optionTitle=_optionTitle;
@synthesize examples=_examples;
@synthesize explore=_explore;
@synthesize patch=_patch;
@synthesize mecab=_mecab;
@synthesize nodes=_nodes;
@synthesize listItems=_listItems;
@synthesize shortFormat=_shortFormat;
@synthesize patchedResult=_patchedResult;
@synthesize tokensViewController=_tokensViewController;

#pragma mark - IBAction

- (IBAction)parse:(id)sender {

    [_textField resignFirstResponder];

    NSString *string = _textField.text;
    
    if ([string isEqualToString:@"*"])
    {// ダイアグノシス
        NSUInteger i;

        for (i = 0; i < [_listItems count]; i++) {
            NSMutableDictionary *sentenceDic = _listItems[i];
            NSString *sentence = sentenceDic[@"sentence"];

            DEBUG_LOG(@"**********************************************************************\n");
            DEBUG_LOG(@"文章「%@」", sentence);
            self.nodes = [NSMutableArray arrayWithArray:[_mecab parseToNodeWithString:sentence]];

            // 和布蕪パッチシングルトンを取得する。
            MecabPatch *mecabPatcher = [MecabPatch sharedManager];
            // 和布蕪パッチシングルトンに解析結果アレイを設定する。
            [mecabPatcher setNodes:_nodes];
            [mecabPatcher setModified:NO];
            // 【注意】必須！！
            [mecabPatcher preProcess];
            [mecabPatcher patch_fix_KEIYODOSHI];
            [mecabPatcher patch_fix_RARERU];
//            [mecabPatcher patch_fix_TEOKU_TOKU];
            [mecabPatcher patch_merge_HIJIRITSU_MEISHI];
            // マージ
            [mecabPatcher patch_merge_DOSHI];
            [mecabPatcher patch_merge_FUKUGO_DOSHI];
            [mecabPatcher patch_merge_FUKUGO_DOSHI_SAHEN];
            [mecabPatcher patch_before_merge_GOKAN];        // 語幹のマージに先立つこと！！
            [mecabPatcher patch_merge_GACHI_GIMI_YASUI];    // 語幹のマージに先立つこと！！
            [mecabPatcher patch_merge_JIMI];                // 語幹のマージに先立つこと！！
            [mecabPatcher patch_merge_N];
            [mecabPatcher patch_merge_GOKAN];
            //
            [mecabPatcher patch_FUKUGO_KEIYO_SHI];          // 語幹のマージ後、名詞マージの前！！
            [mecabPatcher patch_HASEI_KEIYO_SHI];           // 語幹のマージ後、名詞マージの前！！
            //
            [mecabPatcher patch_merge_MEISHI];              // 原則的に、名詞の連結は語幹連結の後にしないとダメ！！
            // パッチ
            [mecabPatcher patch_detect_FUKUSHI];
            [mecabPatcher patch_TAIGEN_DA];
            [mecabPatcher patch_NANODA_NO];
//            [mecabPatcher patch_KANDOSHI_SOU];
            [mecabPatcher patch_HOJO_KEIYOUSHI];
            [mecabPatcher patch_TAIGEN_RASHII];
            [mecabPatcher patch_TOMO];
            [mecabPatcher patch_TOMO_KUTEN];
            [mecabPatcher patch_DE_MO];
            [mecabPatcher patch_DEMO];
            [mecabPatcher patch_DATTE];
            // 用語置換
            [mecabPatcher postProcess];

#if REPLACE_OBJECT
            sentenceDic[@"modified"] = [NSNumber numberWithBool:mecabPatcher.modified];
            [_listItems replaceObjectAtIndex:i withObject:sentenceDic];
#endif
        }
    } else {
        self.nodes = [NSMutableArray arrayWithArray:[_mecab parseToNodeWithString:string]];
        
        // 和布蕪パッチシングルトンを取得する。
        MecabPatch *mecabPatcher = [MecabPatch sharedManager];
        // 和布蕪パッチシングルトンに解析結果アレイを設定する。
        [mecabPatcher setNodes:_nodes];
        [mecabPatcher setModified:NO];
        // 【注意】必須！！
        [mecabPatcher preProcess];

        if (_patch.on) {
            // 致命的な欠点を無くす処理
            [mecabPatcher patch_fix_KEIYODOSHI];
            [mecabPatcher patch_fix_RARERU];
//            [mecabPatcher patch_fix_TEOKU_TOKU];
            // マージ
            [mecabPatcher patch_merge_HIJIRITSU_MEISHI];
            [mecabPatcher patch_merge_DOSHI];
            [mecabPatcher patch_merge_FUKUGO_DOSHI];
            [mecabPatcher patch_merge_FUKUGO_DOSHI_SAHEN];
            [mecabPatcher patch_before_merge_GOKAN];        // 語幹のマージに先立つこと！！
            [mecabPatcher patch_merge_GACHI_GIMI_YASUI];    // 語幹のマージに先立つこと！！
            [mecabPatcher patch_merge_JIMI];                // 語幹のマージに先立つこと！！
            [mecabPatcher patch_merge_N];
            //
            [mecabPatcher patch_merge_GOKAN];
            //
            [mecabPatcher patch_FUKUGO_KEIYO_SHI];          // 語幹のマージ後、名詞マージの前！！
            [mecabPatcher patch_HASEI_KEIYO_SHI];           // 語幹のマージ後、名詞マージの前！！
            //
            [mecabPatcher patch_merge_MEISHI];              // 原則的に、名詞の連結は語幹連結の後にしないとダメ！！
            // パッチ
            [mecabPatcher patch_detect_FUKUSHI];
            [mecabPatcher patch_TAIGEN_DA];
            [mecabPatcher patch_NANODA_NO];
//            [mecabPatcher patch_KANDOSHI_SOU];
            [mecabPatcher patch_HOJO_KEIYOUSHI];
            [mecabPatcher patch_TAIGEN_RASHII];
            [mecabPatcher patch_TOMO];
            [mecabPatcher patch_TOMO_KUTEN];
            [mecabPatcher patch_DE_MO];
            [mecabPatcher patch_DEMO];
            [mecabPatcher patch_DATTE];
            // 用語置換
            [mecabPatcher postProcess];
        }
        _patchedResult = _patch.on;
#if 1
        [_tableView reloadData];
#elif 0
        [UIView animateWithDuration:0.2
                         animations:^{
                             [_tableView reloadData];
                         }
                         completion:^(BOOL finished) {
                         }];
#else
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        [UIView beginAnimations:nil context:context];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationTransition:UIViewAnimationTransitionNone
                               forView:_tableView
                                 cache:NO];
        [_tableView reloadData];
        [UIView commitAnimations];
#endif
        if ([string length]) {
            NSUInteger foundIndex = NSNotFound;
            
            for (NSUInteger i = 0; i < [_listItems count]; i++) {
                NSDictionary *dic = _listItems[i];
                if ([dic[@"sentence"] isEqualToString:string]) {
                    foundIndex = i;
                    break;
                }
            }
            if (foundIndex != NSNotFound) {
                NSMutableDictionary *dic = _listItems[foundIndex];
                BOOL changed = ((NSNumber *) dic[@"modified"]).boolValue != mecabPatcher.modified;

                dic[@"modified"] = [NSNumber numberWithBool:mecabPatcher.modified];
#if REPLACE_OBJECT
                if (changed) {
                    [_listItems replaceObjectAtIndex:foundIndex withObject:dic];
                    // パース結果、変更フラグに遷移があったので、XML ファイルに反映する。
                    [_listItems writeToFile:kLibXMLPath atomically:YES];
#if ICLOUD_ENABLD
                    // iCloud に反映する。
                    LibMecabSampleAppDelegate *appDelegate = (LibMecabSampleAppDelegate *)[[UIApplication sharedApplication] delegate];

                    if (appDelegate.use_iCloud) {
                        [appDelegate saveTo_iCloud];
                    }
#endif
                }
#endif
            } else {
                NSMutableDictionary *newDic = [[[NSMutableDictionary alloc] init] autorelease];

                newDic[@"sentence"] = string;
                newDic[@"tag"]      = @"";
                newDic[@"modified"] = [NSNumber numberWithBool:mecabPatcher.modified];
                [_listItems addObject:newDic];

                // 文章を追加したので、XML ファイルに反映する。
                [_listItems writeToFile:kLibXMLPath atomically:YES];

#if ICLOUD_ENABLD
                // iCloud に反映する。
                LibMecabSampleAppDelegate *appDelegate = (LibMecabSampleAppDelegate *)[[UIApplication sharedApplication] delegate];

                if (appDelegate.use_iCloud) {
                    [appDelegate saveTo_iCloud];
                }
#endif
            }
            [[NSUserDefaults standardUserDefaults] setObject:string forKey:kDefaultsEvaluatingSentence];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:kDefaultsEvaluatingSentence];
        }
    }
}

- (IBAction) setPatchDefaults:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:_patch.on forKey:kDefaultsPatchMode];
}

- (IBAction) openTokensView:(id)sender {
    
    [_textField resignFirstResponder];

    if ([_listItems count])
    {// トークンリストのモーダルダイアログを表示する。
        TokensViewController *viewController = [[TokensViewController alloc] initWithNibName:@"TokensViewController"
                                                                                      bundle:nil
                                                                              sentencesArray:_listItems];
        
        [self presentViewController:viewController animated:YES completion:nil];
        self.tokensViewController = viewController;
        [viewController release];
    }
}

#pragma mark - UIResponder

- (BOOL) canBecomeFirstResponder {
    return YES;
}

- (BOOL) canResignFirstResponder {
    return YES;
}

#pragma mark - UIScrollView

#if (DISPOSE_KEYBOARD_WHEN_SCROLL == 1)
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if ([_textField.text length] == 0)
    {// 解析対象の文字列が空の場合には、キーボードはただの障害物なのでスクロールでキーボードを閉じる。
        [_textField resignFirstResponder];
    }
}
#endif

#pragma mark - UIViewController

- (void) activateControls {
    _examples.enabled = YES;
    _explore.enabled = YES;
}

- (void) deactivateControls {
    _examples.enabled = NO;
    _explore.enabled = NO;
}

- (void) initialParse {

    NSString *string = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsEvaluatingSentence];

    if ([string length] == 0 && [_listItems count]) {
        string = ((NSDictionary *) _listItems[0])[@"sentence"];
    }
    [_textField setText:[string length] ? string : @""];
    [self parse:self];
}

- (void)viewDidLoad {

//    DEBUG_LOG(@"%s", __func__);

    [super viewDidLoad];

    [_examples setTitle:NSLocalizedString(@"examples", @"文例") forState:UIControlStateNormal];
    [_textField setPlaceholder:NSLocalizedString(@"require_sentence", @"文章を入力してください。")];
    [_optionTitle setText:NSLocalizedString(@"optionTitle", @"学校文法")];
    [_explore setTitle:NSLocalizedString(@"parse", @"解析") forState:UIControlStateNormal];
    
    [_tableView setBackgroundColor:kTableViewBackgroundColor];

    _shortFormat = YES;
    [self createGestureRecognizers];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsPatchMode] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDefaultsPatchMode];
    }    
    [_tableView becomeFirstResponder];

    self.mecab = [[Mecab new] autorelease];
    _explore.layer.cornerRadius = 5.0;
    [_patch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsPatchMode]];
    
    _textField.delegate = self;

    // 罫線を突き抜けさせる。
    if ([_tableView respondsToSelector:@selector(separatorInset)]) {
        _tableView.separatorInset = UIEdgeInsetsZero;
    }
    if ([_tableView respondsToSelector:@selector(layoutMargins)]) {
        _tableView.layoutMargins = UIEdgeInsetsZero;
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
}

- (void) viewWillAppear:(BOOL)animated {

//    DEBUG_LOG(@"%s", __func__);

    [super viewWillAppear:animated];
    
    self.listItems = [NSMutableArray arrayWithArray:[NSArray arrayWithContentsOfFile:kLibXMLPath]];

    [_examples setTitleColor:kEnabledTextColor forState:UIControlStateNormal];
    [_examples setTitleColor:kDisabledTextColor forState:UIControlStateDisabled];
    // 文例ボタンをアクティベート化する。
    [_examples setEnabled:[_listItems count] > 0];
    
    [self initialParse];

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

        //
        NSString *agentPath = [[iCloudStorage sandboxContainerDocPath] stringByAppendingPathComponent:kLibXMLName];

        BOOL isDirectory;
        if ([FileUtil fileExistsAtPath:agentPath isDirectory:&isDirectory]) {
//            DEBUG_LOG(@"%@", array);
            [self iCloudListDownloadCompleted:nil];
        }
    }
#endif
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.tokensViewController = nil;
}

- (void) viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    // キーボードフォーカスを破棄する。
    [_textField resignFirstResponder];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
	if (_nodes) {
		return [_nodes count];
	}
	return 0;
}

// セパレータ（罫線）の設定
-(void)tableView:(UITableView *)tableView
 willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Node *node = [_nodes objectAtIndex:indexPath.row];
    NSString *reading = [node reading];
    NSString *partOfSpeech = [node partOfSpeech];
    NSString *partOfSpeechSubtype1 = [node partOfSpeechSubtype1];

    if (node.detailed) {
        NodeCell *cell = (NodeCell *)[tableView dequeueReusableCellWithIdentifier:@"NodeCell"];

        if (cell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"NodeCell" owner:self options:nil];
            cell = _nodeCell;
            self.nodeCell = nil;
        }
        cell.delegate = self;
        if (_patchedResult) {
            if (([self phraseNth:indexPath.row] % 2) == 0) {
                [cell.contentView setBackgroundColor:kJiritsugoCellColor];
            } else {
                [cell.contentView setBackgroundColor:kFuzokugoCellColor];
            }
        } else {
            [cell.contentView setBackgroundColor:[UIColor whiteColor]];
        }

        if (reading && ! [reading isEqualToString:@"(null)"]) {
            cell.surfaceLabel.text = node.surface;
        } else {
            cell.surfaceLabel.text = node.surface;
        }
        // 読み
        cell.readingLabel.text = [node reading];
        // 発音
        cell.pronunciationLabel.text = [node pronunciation];
        // 原形
        cell.originalFormLabel.text = [node originalForm];
        
        cell.partOfSpeechLabel.text = [node partOfSpeech];
        cell.partOfSpeechSubtype1Label.text = [node partOfSpeechSubtype1];
        cell.partOfSpeechSubtype2Label.text = [node partOfSpeechSubtype2];
        cell.partOfSpeechSubtype3Label.text = [node partOfSpeechSubtype3];
        
        // 活用形
        NSMutableString *inflection = [[node inflection] mutableCopy];

        if (node.modified) {
            cell.inflectionLabel.textColor = [UIColor brownColor];
        } else {
            cell.inflectionLabel.textColor = [UIColor blackColor];
        }
        if ([partOfSpeech isEqualToString:@"助詞"] ||
            [partOfSpeech isEqualToString:@"助動詞"] ||
            [partOfSpeech isEqualToString:@"記号"] ||
            [partOfSpeech isEqualToString:@"フィラー"] ||
            [partOfSpeechSubtype1 isEqualToString:@"補助動詞"]) {
            cell.partOfSpeechLabel.textColor = [UIColor colorWithRed:255 green:0 blue:255 alpha:0.4];
        } else {
            cell.partOfSpeechLabel.textColor = [UIColor magentaColor];
        }
        cell.inflectionLabel.text = inflection;
        // 活用型
        cell.useOfTypeLabel.text = [node useOfType];
        return cell;
    } else {
        SmallNodeCell *cell = (SmallNodeCell *)[tableView dequeueReusableCellWithIdentifier:@"SmallNodeCell"];

        if (cell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"SmallNodeCell" owner:self options:nil];
            cell = _smallNodeCell;
            self.smallNodeCell = nil;
        }
        cell.delegate = self;
        if (_patchedResult) {
            if (([self phraseNth:indexPath.row] % 2) == 0) {
                [cell.contentView setBackgroundColor:kJiritsugoCellColor];
            } else {
                [cell.contentView setBackgroundColor:kFuzokugoCellColor];
            }
        } else {
            [cell.contentView setBackgroundColor:[UIColor whiteColor]];
        }
        
        if (reading && ! [reading isEqualToString:@"(null)"]) {
            cell.surfaceLabel.text = node.surface;
        } else {
            cell.surfaceLabel.text = node.surface;
        }
        // 原形
        cell.originalFormLabel.text = [node originalForm];
        // 品詞
        cell.partOfSpeechLabel.text = [node partOfSpeech];
        // 品詞のカラーリング
        if ([partOfSpeech isEqualToString:@"助詞"] ||
            [partOfSpeech isEqualToString:@"助動詞"] ||
            [partOfSpeech isEqualToString:@"記号"] ||
            [partOfSpeech isEqualToString:@"フィラー"] ||
            [partOfSpeechSubtype1 isEqualToString:@"補助動詞"]) {
            cell.partOfSpeechLabel.textColor = [UIColor colorWithRed:1.0 green:0.0 blue:1.0 alpha:0.4];
        } else {
            cell.partOfSpeechLabel.textColor = [UIColor magentaColor];
        }
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Node *node = [_nodes objectAtIndex:indexPath.row];

    if (node.visible) {
        if (node.detailed) {
            return 74.0;
        } else {
            return 29.0;
        }
    } else {
        return 0.0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView
heightForFooterInSection:(NSInteger)section {
    
    return 1.0;
}

- (void)dealloc {

#if ICLOUD_ENABLD
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:iCloudDownloadCompletedNotification
                                                  object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:iCloudSyncNotification
                                                  object:self];
#endif
    self.textField = nil;
    self.tableView = nil;
    self.nodeCell = nil;
    self.smallNodeCell = nil;
    self.examples = nil;
    self.optionTitle = nil;
    self.explore = nil;
    self.patch = nil;

    self.mecab = nil;
	self.nodes = nil;
    self.listItems = nil;

//    self.selectedIndexPath = nil;
	
    [super dealloc];
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)textFld {
    [_textField resignFirstResponder];
    return NO;
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

// 長押しで表示モードをトグルさせる。
- (IBAction) handleLongPress:(UILongPressGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint location = [sender locationInView:_tableView];
        NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:location];
        BOOL shortFormat = (((Node *) _nodes[indexPath.row]).detailed == NO);
        DEBUG_LOG(@"%s[%ld]", __func__, (long)indexPath.row);

        // 表示モードをトグルさせる。
//        _shortFormat = ! _shortFormat;

        _shortFormat = ! shortFormat;
        for (Node *node in _nodes) {
            node.detailed = (_shortFormat == NO);
        }
        [_tableView reloadData];
        [_tableView selectRowAtIndexPath:indexPath
                                animated:NO
                          scrollPosition:UITableViewScrollPositionMiddle];
    }
}

- (void) toggleCellSize:(UITableViewCell *)cell {
    
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    Node *node = _nodes[indexPath.row];
    
    node.detailed = ! node.detailed;
    [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                      withRowAnimation:UITableViewRowAnimationFade];
}

- (void) showWikiPage:(UITableViewCell *)cell {
    
    NSSet *hinshiSet = [NSSet setWithObjects:@"名詞",
                                             @"代名詞",
                                             @"動詞",
                                             @"形容詞",
                                             @"形容動詞",
                                             @"副詞",
                                             @"連体詞",
                                             @"感動詞",
                                             @"接続詞",
                                             @"助詞",
                                             @"格助詞",
                                             @"並列助詞",
                                             @"副助詞",
                                             @"係助詞",
                                             @"接続助詞",
                                             @"終助詞",
                                             @"間投助詞",
                                             @"準体言助詞",
                                             @"準体助詞",
                                             @"助動詞", nil];
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    Node *node = _nodes[indexPath.row];
    NSString *partOfSpeech = [node partOfSpeech];
    NSString *partOfSpeechSubtype1 = [node partOfSpeechSubtype1];
    NSString *partOfSpeechSubtype2 = [node partOfSpeechSubtype2];
    NSString *partOfSpeechSubtype3 = [node partOfSpeechSubtype3];
    NSString *hinshi = nil;
    
    if ([hinshiSet member:partOfSpeechSubtype3]) {
        hinshi = partOfSpeechSubtype3;
    } else if ([hinshiSet member:partOfSpeechSubtype2]) {
        hinshi = partOfSpeechSubtype2;
    } else if ([hinshiSet member:partOfSpeechSubtype1]) {
        hinshi = partOfSpeechSubtype1;
    } else if ([hinshiSet member:partOfSpeech]) {
        hinshi = partOfSpeech;
    }
    
    if ([hinshi length]) {
        NSString *urlStr = [@"https://ja.wikipedia.org/wiki/" stringByAppendingString:[hinshi encodeURL:NSUTF8StringEncoding]];
        // URL エンコードしないこと！！
        NSURL *url = [NSURL URLWithString:urlStr];
        
        if (url && [[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

- (NSUInteger) phraseNth:(NSUInteger)index {

    NSUInteger nth = 0;

    for (NSUInteger i = 0; i <= index; i++) {
        Node *node = _nodes[i];

        if (node.visible &&
            ([[node partOfSpeech] isEqualToString:@"記号"] == NO &&
             [[node partOfSpeech] isEqualToString:@"フィラー"] == NO &&
             [MecabPatch isFuzokugo:[node partOfSpeech]] == NO &&
             [[node partOfSpeechSubtype1] isEqualToString:@"補助動詞"] == NO)
        )
        {
            nth++;
        }
    }
    return nth;
}

#pragma mark - iCloud 用リスナーのコールバック

#if ICLOUD_ENABLD
// Library.xml を iCloud から取得したファイルに置換する。
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
                DEBUG_LOG(@"%s Library.xml を置換しました。", __func__);
            }
        }
        self.listItems = [NSMutableArray arrayWithArray:[NSArray arrayWithContentsOfFile:kLibXMLPath]];
        // 文例ボタンをアクティベート化する。
        [_examples setEnabled:[_listItems count] > 0];
        
        if (_tokensViewController) {
            NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
            // ユーザーデフォルトの設定が変わったことを LibMecabSampleViewController に通知する。
            [userInfo setObject:[self class] forKey:@"class"];
            
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:iCloudDownloadCompletedNotification
                                                                                                 object:_tokensViewController
                                                                                               userInfo:userInfo]];
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:iCloudSyncNotification
                                                                                                 object:_tokensViewController
                                                                                               userInfo:userInfo]];
        }
    }
}
#endif
@end
