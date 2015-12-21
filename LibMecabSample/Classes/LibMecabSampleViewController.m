//
//  LibMecabSampleViewController.m
//  LibMecabSample
//
//  Created by Watanabe Toshinori on 10/12/27.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import "definitions.h"
#import "LibMecabSampleViewController.h"
#import "TokensViewController.h"
#import "Mecab.h"
#import "Node.h"
#import "MecabPatch.h"
#import "Utility.h"

//#import "CloudKit/CKDefines.h"
#import "CloudKit/CKContainer.h"
#import "CloudKit/CKRecordID.h"
#import "CloudKit/CKRecord.h"
#import "CloudKit/CKFetchRecordsOperation.h"
#import "CloudKit/CKDatabase.h"

@implementation LibMecabSampleViewController

@synthesize textField=_textField;
@synthesize tableView=_tableView;
@synthesize nodeCell=_nodeCell;
@synthesize smallNodeCell=_smallNodeCell;
@synthesize examples=_examples;
@synthesize explore=_explore;
@synthesize patch=_patch;
@synthesize mecab=_mecab;
@synthesize nodes=_nodes;
@synthesize sentenceItems=_sentenceItems;
@synthesize shortFormat=_shortFormat;
//@synthesize selectedIndexPath=_selectedIndexPath;

#pragma mark - IBAction

- (IBAction)parse:(id)sender {

    [_textField resignFirstResponder];

    NSString *string = _textField.text;
    
    if ([string isEqualToString:@"*"])
    {// ダイアグノシス
        NSUInteger i;

        for (i = 0; i < [_sentenceItems count]; i++) {
            NSMutableDictionary *sentenceDic = _sentenceItems[i];
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
            // マージ
            [mecabPatcher patch_merge_DOSHI];
            [mecabPatcher patch_merge_FUKUGO_DOSHI];
            [mecabPatcher patch_merge_FUKUGO_DOSHI_SAHEN];
            [mecabPatcher patch_before_merge_GOKAN];        // 語幹のマージに先立つこと！！
            [mecabPatcher patch_merge_GACHI_GIMI_YASUI];    // 語幹のマージに先立つこと！！
            [mecabPatcher patch_merge_GOKAN];
            [mecabPatcher patch_merge_MEISHI];              // 原則的に、名詞の連結は語幹連結の後にしないとダメ！！
            // パッチ
            [mecabPatcher patch_detect_FUKUSHI];
            [mecabPatcher patch_TAIGEN_DA];
            [mecabPatcher patch_NANODA_NO];
//            [mecabPatcher patch_KANDOSHI_SOU];
            [mecabPatcher patch_HOJO_KEIYOUSHI_NAI];
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
            [_sentenceItems replaceObjectAtIndex:i withObject:sentenceDic];
#endif
        }
#if REPLACE_OBJECT
        [_sentenceItems writeToFile:kLibXMLPath atomically:YES];
#endif
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
            // マージ
            [mecabPatcher patch_merge_DOSHI];
            [mecabPatcher patch_merge_FUKUGO_DOSHI];
            [mecabPatcher patch_merge_FUKUGO_DOSHI_SAHEN];
            [mecabPatcher patch_before_merge_GOKAN];        // 語幹のマージに先立つこと！！
            [mecabPatcher patch_merge_GACHI_GIMI_YASUI];    // 語幹のマージに先立つこと！！
            [mecabPatcher patch_merge_GOKAN];
            [mecabPatcher patch_merge_MEISHI];              // 原則的に、名詞の連結は語幹連結の後にしないとダメ！！
            // パッチ
            [mecabPatcher patch_detect_FUKUSHI];
            [mecabPatcher patch_TAIGEN_DA];
            [mecabPatcher patch_NANODA_NO];
//            [mecabPatcher patch_KANDOSHI_SOU];
            [mecabPatcher patch_HOJO_KEIYOUSHI_NAI];
            [mecabPatcher patch_TAIGEN_RASHII];
            [mecabPatcher patch_TOMO];
            [mecabPatcher patch_TOMO_KUTEN];
            [mecabPatcher patch_DE_MO];
            [mecabPatcher patch_DEMO];
            [mecabPatcher patch_DATTE];
            // 用語置換
            [mecabPatcher postProcess];
        }
        [_tableView reloadData];
        
        if ([string length]) {
            NSUInteger foundIndex = NSNotFound;
            
            for (NSUInteger i = 0; i < [_sentenceItems count]; i++) {
                NSDictionary *dic = _sentenceItems[i];
                if ([dic[@"sentence"] isEqualToString:string]) {
                    foundIndex = i;
                    break;
                }
            }
            if (foundIndex != NSNotFound) {
                NSMutableDictionary *dic = _sentenceItems[foundIndex];

                dic[@"modified"] = [NSNumber numberWithBool:mecabPatcher.modified];
            } else {
                NSMutableDictionary *newDic = [[[NSMutableDictionary alloc] init] autorelease];

                newDic[@"sentence"] = string;
                newDic[@"tag"]      = @"";
                newDic[@"modified"] = [NSNumber numberWithBool:mecabPatcher.modified];
                [_sentenceItems addObject:newDic];
            }
            [_sentenceItems writeToFile:kLibXMLPath atomically:YES];

            // iCloud
#if 0
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kUse_iCloudKey]) {
                CKContainer *defaultContainer =[CKContainer defaultContainer];
                CKDatabase *privateCloudDatabase = [defaultContainer privateCloudDatabase];
                CKRecordID *publicSentencesID = [[CKRecordID alloc] initWithRecordName:@"46705d64-48e5-4f02-8899-083af3baed2d"];
                CKRecord *record = [[CKRecord alloc] initWithRecordType:@"File" recordID:publicSentencesID];
                
                [record setObject:@"Sentences.xml" forKey:@"FileName"];
                [record setObject:[NSArray arrayWithContentsOfFile:kLibXMLPath] forKey:@"Asset"];
                
                [privateCloudDatabase saveRecord:record
                               completionHandler:^(CKRecord *record, NSError *error) {
                                   DEBUG_LOG(@"erorr : %@", error);
                                   CKAsset *asset = record[@"Asset"];
                                   
                                   // asset.fileURL.pathにファイルがダウンロードされてる
                                   DEBUG_LOG(@"%@", asset.fileURL.path);
                               }];
            }
#endif
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:kDefaultsSentence];
        }
    }
}

- (IBAction) setPatchDefaults:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:_patch.on forKey:kDefaultsPatchMode];
}

- (IBAction) openTokensView:(id)sender {
    
    [_textField resignFirstResponder];

    if ([_sentenceItems count])
    {// トークンリストのモーダルダイアログを表示する。
        TokensViewController *viewController = [[TokensViewController alloc] initWithNibName:@"TokensViewController"
                                                                                      bundle:nil
                                                                              sentencesArray:_sentenceItems];
        
        [self presentViewController:viewController animated:YES completion:nil];
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

#if (GIVEUP_EDIT_WHEN_SCROLL == 1)
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [_textField resignFirstResponder];
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

    NSString *string = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsSentence];

    if ([string length] == 0 && [_sentenceItems count]) {
        string = ((NSDictionary *) _sentenceItems[0])[@"sentence"];
    }
    [_textField setText:[string length] ? string : @""];
    [self parse:self];
}

- (void)viewDidLoad {

//    DEBUG_LOG(@"%s", __func__);

    [super viewDidLoad];

    _shortFormat = YES;
    [self createGestureRecognizers];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsPatchMode] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDefaultsPatchMode];
    }
    [self setupByPreferences];
    
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
}

- (void) viewWillAppear:(BOOL)animated {

//    DEBUG_LOG(@"%s", __func__);

    [super viewWillAppear:animated];

#if INITIAL_DOC
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kUse_iCloudKey] &&
        [[NSFileManager defaultManager] fileExistsAtPath:kLibXMLPath] == NO)
    {
        [self deactivateControls];
        // iCloud
        CKContainer *defaultContainer =[CKContainer defaultContainer];
        CKDatabase *publicDatabase = [defaultContainer publicCloudDatabase];
        CKRecordID *publicSentencesID = [[CKRecordID alloc] initWithRecordName:@"7cc4ea03-43e9-42a4-ba32-cdf95f76c941"];
#if 1
        [publicDatabase fetchRecordWithID:publicSentencesID
                        completionHandler:^(CKRecord *fetchedParty, NSError *error) {
                            DEBUG_LOG(@"erorr : %@", error);
                            CKAsset *asset = fetchedParty[@"Asset"];
                            
                            // asset.fileURL.pathにファイルがダウンロードされてる
                            DEBUG_LOG(@"%@", asset.fileURL.path);
                            if ([[NSFileManager defaultManager] fileExistsAtPath:kLibXMLPath] == NO) {
                                [[NSFileManager defaultManager] moveItemAtPath:asset.fileURL.path toPath:kLibXMLPath error:nil];
                            }
                            self.sentences = [NSMutableArray arrayWithArray:[NSArray arrayWithContentsOfFile:kLibXMLPath]];
                            [self activateControls];
                            [self initialParse];
                        }];
#else
        CKFetchRecordsOperation * op = [[CKFetchRecordsOperation alloc] initWithRecordIDs:@[publicSentencesID]];
        op.queuePriority = NSOperationQueuePriorityVeryHigh;
        op.perRecordProgressBlock = ^(CKRecordID * recordId, double progress) {
            DEBUG_LOG(@"progress : %lf", progress);
        };
        op.perRecordCompletionBlock = ^(CKRecord *fetchedParty, CKRecordID * recordId,  NSError *error) {
            DEBUG_LOG(@"erorr : %@", error);
            CKAsset *asset = fetchedParty[@"Asset"];
            DEBUG_LOG(@"%@", asset.fileURL.path);
            if ([[NSFileManager defaultManager] fileExistsAtPath:kLibXMLPath] == NO) {
                [[NSFileManager defaultManager] moveItemAtPath:asset.fileURL.path toPath:kLibXMLPath error:nil];
            }
            self.tokens = [NSMutableArray arrayWithArray:[NSArray arrayWithContentsOfFile:kLibXMLPath]];
            [self activateControls];
            [self initialParse];
        };
        [publicDatabase addOperation:op];
#endif
    } else {
        self.sentences = [NSMutableArray arrayWithArray:[NSArray arrayWithContentsOfFile:kLibXMLPath]];
        [self initialParse];
    }
#else
    self.sentenceItems = [NSMutableArray arrayWithArray:[NSArray arrayWithContentsOfFile:kLibXMLPath]];
    [self initialParse];
#endif

#if (GIVEUP_EDIT_WHEN_SCROLL == 0)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
#endif
}

- (void) viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    // キーボードフォーカスを破棄する。
    [_textField resignFirstResponder];
    
#if (GIVEUP_EDIT_WHEN_SCROLL == 0)
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
#endif
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

    if (node.detailed) {
        NodeCell *cell = (NodeCell *)[tableView dequeueReusableCellWithIdentifier:@"NodeCell"];

        if (cell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"NodeCell" owner:self options:nil];
            cell = _nodeCell;
            self.nodeCell = nil;
        }
        cell.delegate = self;
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsPatchMode]) {
            if (([self nthPhrase:indexPath.row] % 2) == 0) {
                [cell.contentView setBackgroundColor:[UIColor whiteColor]];
            } else {
                [cell.contentView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.04]];
            }
        }
        NSString *reading = [node reading];
        NSString *partOfSpeech = [node partOfSpeech];
        
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
            [partOfSpeech isEqualToString:@"記号"]) {
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
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsPatchMode]) {
            if (([self nthPhrase:indexPath.row] % 2) == 0) {
                [cell.contentView setBackgroundColor:[UIColor whiteColor]];
            } else {
                [cell.contentView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.04]];
            }
        }
        NSString *reading = [node reading];
        NSString *partOfSpeech = [node partOfSpeech];
        
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
            [partOfSpeech isEqualToString:@"記号"]) {
            cell.partOfSpeechLabel.textColor = [UIColor colorWithRed:255 green:0 blue:255 alpha:0.4];
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

- (void)dealloc {

    self.textField = nil;
    self.tableView = nil;
    self.nodeCell = nil;
    self.smallNodeCell = nil;
    self.examples = nil;
    self.explore = nil;
    self.patch = nil;

    self.mecab = nil;
	self.nodes = nil;
    self.sentenceItems = nil;

//    self.selectedIndexPath = nil;
	
    [super dealloc];
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)textFld {
    [_textField resignFirstResponder];
    return NO;
}

#pragma mark - UITextFieldDelegate

- (void) setupByPreferences {
    
    //    YardbirdAppDelegate *appDelegate = (YardbirdAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUse_iCloudKey] == nil)
    {
        @try {
            // no default values have been set, create them here based on what's in our Settings bundle info
            //
            NSString *settingsBundlePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Settings.bundle"];
            NSString *rootFinalPath = [settingsBundlePath stringByAppendingPathComponent:@"Root.plist"];
            NSDictionary *rootSettingsDict = [NSDictionary dictionaryWithContentsOfFile:rootFinalPath];
            NSArray *rootPrefSpecifierArray = [rootSettingsDict objectForKey:@"PreferenceSpecifiers"];
            
            NSNumber *use_iCloudDefault = [NSNumber numberWithBool:YES];    // iCloud 使用する
            
            for (NSDictionary *prefItem in rootPrefSpecifierArray)
            {
                NSString *keyValueStr = [prefItem objectForKey:@"Key"];
                id defaultValue = [prefItem objectForKey:@"DefaultValue"];
                
                DEBUG_LOG(@"%s %@=%@", __func__, keyValueStr, defaultValue);
                if (keyValueStr)
                {
                    if ([keyValueStr isEqualToString:kUse_iCloudKey]) {
                        use_iCloudDefault = defaultValue;
                    }
                }
            }
            // since no default values have been set (i.e. no preferences file created), create it here
            NSDictionary *defaultsDic = [NSDictionary dictionaryWithObjectsAndKeys:use_iCloudDefault, kUse_iCloudKey, nil];
            
            [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDic];
            if ([[NSUserDefaults standardUserDefaults] synchronize]) {
                DEBUG_LOG(@"UserDefaults synchronize OK");
            } else {
                DEBUG_LOG(@"UserDefaults synchronize NG");
            }
        }
        @catch (NSException *exception) {
            DEBUG_LOG(@"%s デフォルト破壊（設定で例外発生）：Line#:%d %@", __func__, __LINE__, exception);
            // 再度登録を促す。
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUse_iCloudKey];
            return;
        }
    } else {
        @try {
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        @catch (NSException *exception) {
            DEBUG_LOG(@"%s デフォルト破壊（シンクできない）Line#:%d %@", __func__, __LINE__, exception);
            // 再度登録を促す。
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUse_iCloudKey];
        }
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

- (NSUInteger) nthPhrase:(NSUInteger)index {

    NSUInteger nth = 0;

    for (NSUInteger i = 0; i <= index; i++) {
        Node *node = _nodes[i];

        if (node.visible &&
            ([[node partOfSpeech] isEqualToString:@"記号"] == NO && [MecabPatch isFuzokugo:[node partOfSpeech]] == NO))
        {
            nth++;
        }
    }
    return nth;
}
@end
