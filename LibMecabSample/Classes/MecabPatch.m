//
//  MecabPatch.m
//  LibMecabSample
//
//  Created by matsu on 2015/12/16.
//
//

#import "definitions.h"
#import "Node.h"
#import "MecabPatch.h"

@implementation MecabPatch

static MecabPatch *sharedManager = nil;

@synthesize upperSet=_upperSet;
@synthesize lowerSet=_lowerSet;
@synthesize sentence=_sentence;
@synthesize nodes=_nodes;
@synthesize modified=_modified;
@synthesize appDelegate=_appDelegate;

- (id) init {

    self = [super init];
    if (self != nil) {
        self.appDelegate = (LibMecabSampleAppDelegate *)[[UIApplication sharedApplication] delegate];

        self.upperSet = [NSSet setWithObjects:@"イ", @"キ", @"ギ", @"シ", @"ジ", @"チ", @"ヂ", @"ニ", @"ヒ", @"ビ", @"ミ", @"リ", nil];
        self.lowerSet = [NSSet setWithObjects:@"エ", @"ケ", @"ゲ", @"セ", @"ゼ", @"テ", @"デ", @"ネ", @"ヘ", @"ベ", @"メ", @"レ", nil];
    }
    return self;
}

+ (MecabPatch *) sharedManager {
    @synchronized(self) {
        if (sharedManager == nil) {
            sharedManager = [[self alloc] init];
        }
    }
    return sharedManager;
}

+ (id) allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedManager == nil) {
            sharedManager = [super allocWithZone:zone];
            return sharedManager;
        }
    }
    return nil;
}

- (id) copyWithZone:(NSZone*)zone {
    return self;  // シングルトン状態を保持するため何もせず self を返す
}

- (void) dealloc {

    [super dealloc];
    
    self.upperSet = nil;
    self.lowerSet = nil;
    self.sentence = nil;
    self.nodes = nil;
}

#pragma mark -

- (NSString *) gokanString:(Node *)node {
    NSString *lastSubType1 = [node partOfSpeechSubtype1];
    NSString *lastSubType2 = [node partOfSpeechSubtype2];
    NSString *lastSubType3 = [node partOfSpeechSubtype3];
    NSString *baseToken = @"語幹";
    NSString *lastGokanStr = nil;
    NSUInteger baseTokenLength = [baseToken length];
    
    if ([lastSubType1 length] > baseTokenLength &&
        [[lastSubType1 substringFromIndex:[lastSubType1 length] - baseTokenLength] isEqualToString:baseToken])
    {
        lastGokanStr = [lastSubType1 substringToIndex:[lastSubType1 length] - baseTokenLength];
    } else if ([lastSubType2 length] > baseTokenLength &&
               [[lastSubType2 substringFromIndex:[lastSubType2 length] - baseTokenLength] isEqualToString:baseToken])
    {
        lastGokanStr = [lastSubType2 substringToIndex:[lastSubType2 length] - baseTokenLength];
    } else if ([lastSubType3 length] > baseTokenLength &&
               [[lastSubType3 substringFromIndex:[lastSubType3 length] - baseTokenLength] isEqualToString:baseToken])
    {
        lastGokanStr = [lastSubType3 substringToIndex:[lastSubType3 length] - baseTokenLength];
    }
    return lastGokanStr;
}

// 【注意】必須の処理
- (void) preProcess {

    for (Node *node in _nodes) {
        NSString *gokanStr = [self gokanString:node];

        if ([gokanStr length]) {
#if LOG_PATCH
            DEBUG_LOG(@"語幹[%@]（%@語幹の%@）", node.surface, [gokanStr length] ? gokanStr : @"", [node partOfSpeech]);
#endif
        }
//        if ([[node originalForm] isEqualToString:@"回れる"]) {
//            [node setOriginalForm:@"回る"];
//        }
        node.attribute = @"";
        node.modified = NO;
        node.detailed = NO;
        node.visible = YES;
    }
}

#pragma mark - Patch (ツール)

// 用言（名詞／代名詞）である。
+ (BOOL) isTaigen:(NSString *)hinshi {
    return ([hinshi isEqualToString:@"名詞"] ||
            [hinshi isEqualToString:@"代名詞"]);
}

// 用言（動詞／形容詞／形容動詞）である。
+ (BOOL) isYougen:(NSString *)hinshi {
    return ([hinshi isEqualToString:@"動詞"] ||
            [hinshi isEqualToString:@"形容詞"] ||
            [hinshi isEqualToString:@"形容動詞"]);
}

+ (BOOL) isKeiyoushi:(NSString *)hinshi {
    return ([hinshi isEqualToString:@"形容詞"]);
}

+ (BOOL) isFuzokugo:(NSString *)hinshi {
    return ([hinshi isEqualToString:@"助詞"] ||
            [hinshi isEqualToString:@"助動詞"]);
}

+ (BOOL) isRenyo:(NSString *)useOfType {
    return ([useOfType length] >= 2 &&
            [[useOfType substringToIndex:2] isEqualToString:@"連用"]);
}

- (BOOL) isKutouTen:(NSUInteger)index {
    
    BOOL rc = NO;
    
    if (index < [_nodes count]) {
        Node *node = _nodes[index];
        
        if ([node.surface isEqualToString:@"、"] || [node.surface isEqualToString:@"。"]) {
            rc = YES;
        }
    } else {
        rc = YES;
    }
    return rc;
}

- (NSString *) makeIchidanString:(NSString *)pronunciation {
    
    NSString *str = @"";
    
    if ([pronunciation length]) {
        NSString *lastChar = [pronunciation substringFromIndex:[pronunciation length] - 1];
        if ([_upperSet member:lastChar]) {
            str = @"上一段";
        } else if ([_lowerSet member:lastChar]) {
            str = @"下一段";
        }
    }
    return str;
}

- (Node *) nextNode:(NSUInteger)index {
    
    Node *nextNode = nil;

    for (NSUInteger i = index + 1; i < [_nodes count]; i++) {
        if (((Node *) _nodes[i]).visible) {
            nextNode = _nodes[i];
            break;
        }
    }
    return nextNode;
}

- (Node *) nextNextNode:(NSUInteger)index {
    
    Node *nextNode = nil;
    Node *nextNextNode = nil;
    NSUInteger i = 0;
    
    for (i = index + 1; i < [_nodes count]; i++) {
        if (((Node *) _nodes[i]).visible) {
            nextNode = _nodes[i];
            break;
        }
    }
    if (nextNode) {
        for (++i; i < [_nodes count]; i++) {
            if (((Node *) _nodes[i]).visible) {
                nextNextNode = _nodes[i];
                break;
            }
        }
    }
    return nextNextNode;
}

- (void) devideNode:(Node *)node
              index:(NSUInteger)index
             rentai:(BOOL)rentai {
    
    Node *newNode = [[Node alloc] init];
    NSMutableArray *features = [[NSMutableArray alloc] initWithObjects:@"", @"", @"", @"", @"", @"", @"", @"", @"", nil];
    
    newNode.features = features;
    [features release];
    
    if (rentai) {
#if (LOG_PATCH || SHOW_DEMO_OP)
        DEBUG_LOG(@"分割（連体）：副助詞:[でも]->格助詞:[で],係助詞:[も] %@", _sentence);
#endif
        [node setSurface:@"で"];
        [node setPronunciation:@"デ"];
        [node setOriginalForm:@"で"];
        [node setPartOfSpeech:@"助詞"];
        [node setPartOfSpeechSubtype1:@"格助詞"];
        [_nodes replaceObjectAtIndex:index withObject:node];
        node.modified = YES;
        
        [newNode setSurface:@"も"];
        [newNode setPronunciation:@"モ"];
        [newNode setOriginalForm:@"も"];
        [newNode setPartOfSpeech:@"助詞"];
        [newNode setPartOfSpeechSubtype1:@"係助詞"];
        [newNode setInflection:@""];
    } else {
#if (LOG_PATCH || SHOW_DEMO_OP)
        DEBUG_LOG(@"分割（連用）：副助詞:[でも]->助動詞:[で],係助詞:[も] %@", _sentence);
#endif
        [node setSurface:@"で"];
        [node setPronunciation:@"デ"];
        [node setOriginalForm:@"だ"];
        [node setPartOfSpeech:@"助動詞"];
        [node setPartOfSpeechSubtype1:@""];
        [node setUseOfType:@"連用形"];
        [node setInflection:@"断定"];
        [_nodes replaceObjectAtIndex:index withObject:node];
        node.modified = YES;
        
        [newNode setSurface:@"も"];
        [newNode setPronunciation:@"モ"];
        [newNode setOriginalForm:@"も"];
        [newNode setPartOfSpeech:@"助詞"];
        [newNode setPartOfSpeechSubtype1:@"係助詞"];
        [newNode setInflection:@""];
    }
    newNode.modified = YES;
    newNode.visible = YES;
    [_nodes insertObject:newNode atIndex:index+1];
    [newNode release];
}

#pragma mark - Patch (マージ1)

// 誤りの訂正
// 【注意】語幹の連結前に実行すること！！
- (void) patch_fix_KEIYODOSHI {
    
    NSSet *keiyodoshiSuffixes = [NSSet setWithObjects:@"ヒサシブリ", nil];

    for (Node *node in _nodes) {
        if (node.visible == NO) {
            continue;
        }
        if ([[node partOfSpeech] isEqualToString:@"名詞"])
        {
            if ([keiyodoshiSuffixes member:[node pronunciation]])
            {// 動詞
                // 属性変更する。
                _modified = YES;
#if LOG_PATCH
                DEBUG_LOG(@"%s 「%@」:(%@)→(%@)", __func__, node.surface, [node partOfSpeechSubtype1], @"形容動詞語幹");
#endif
                [node setPartOfSpeechSubtype1:@"形容動詞語幹"];
                node.modified = YES;
            }
        }
    }
}

// 誤りの訂正
// 【注意】語幹の連結前に実行すること！！
- (void) patch_fix_RARERU {
    
    NSSet *transitiveVerbSuffixes = [NSSet setWithObjects:@"す", @"さす", nil];
    
    for (Node *node in _nodes) {
        if (node.visible == NO) {
            continue;
        }
        if ([[node partOfSpeech] isEqualToString:@"動詞"])
        {
            if ([[node partOfSpeechSubtype1] isEqualToString:@"接尾"]) {
                NSString *originalForm = [node originalForm];
                
                if ([originalForm isEqualToString:@"られる"] ||
                    [originalForm isEqualToString:@"れる"] ||
                    [originalForm isEqualToString:@"せる"] ||
                    [originalForm isEqualToString:@"させる"] ||
                    [originalForm isEqualToString:@"がる"]
                   )
                {// こんな動詞はない。
                    // 属性変更する。
                    _modified = YES;
#if LOG_PATCH
                    DEBUG_LOG(@"%s こんな動詞はない。「%@」(%@)→「%@」(%@)", __func__, node.surface, [node partOfSpeech], node.surface, @"助動詞");
#endif
                    [node setPartOfSpeech:@"助動詞"];
                    [node setPartOfSpeechSubtype1:@""];
                    node.modified = YES;
                } else if ([transitiveVerbSuffixes member:originalForm])
                {// "す","さす"
#if LOG_PATCH
                    DEBUG_LOG(@"%s 他動詞のサフィックス「%@」(%@)", __func__, node.surface, [node partOfSpeech]);
#endif
                } else {
                    DEBUG_LOG(@"%s 未確認の接尾辞「%@」 %@", __func__, node.surface, _sentence);
                }
            }
        }
    }
}

// 非自立名詞の連結
// 【注意】語幹の連結前に実行すること！！
- (void) patch_merge_HIJIRITSU_MEISHI {
    Node *lastNode = nil;
    
    for (Node *node in _nodes) {
        if (node.visible == NO) {
            continue;
        }
        if (lastNode) {
            if ([[node partOfSpeech] isEqualToString:@"名詞"])
            {
                BOOL merge = NO;
                BOOL adverb = NO;
                BOOL retainLastSubtype = NO;
                
                if ([[lastNode partOfSpeech] isEqualToString:@"名詞"])
                {// 名詞｜動詞
                    if ([[node partOfSpeechSubtype1] isEqualToString:@"非自立"])
                    {// 名詞＆名詞（非自立）である。
                        if ([[node partOfSpeechSubtype2] isEqualToString:@"副詞可能"]) {
                            adverb = YES;
                        }
                        if ([[node originalForm] isEqualToString:@"ん"]== NO) {
                            merge = YES;
                            retainLastSubtype = YES;
                        } else {
#if LOG_PATCH
                            DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, node.surface, [node partOfSpeech], node.surface, @"助詞");
#endif
                            [node setPartOfSpeech:@"助詞"];
                            [node setPartOfSpeechSubtype1:@"格助詞"];
                            [node setPartOfSpeechSubtype2:@"「の」撥音便"];
                            [node setOriginalForm:@"の"];
                            node.modified = YES;
                        }
                    }
#if SHOW_KANOU
                    NSString *lastSubtype1 = [lastNode partOfSpeechSubtype1];
                    NSString *nodeSubtype2 = [node partOfSpeechSubtype2];
                    
                    if ([lastSubtype1 length] > 2 && [[lastSubtype1 substringFromIndex:[lastSubtype1 length] - 2] isEqualToString:@"可能"]) {
                        DEBUG_LOG(@"%s [%@]%@", __func__, lastSubtype1, lastNode.surface);
                    }
                    if ([nodeSubtype2 length] > 2 && [[nodeSubtype2 substringFromIndex:[nodeSubtype2 length] - 2] isEqualToString:@"可能"]) {
                        DEBUG_LOG(@"%s [%@]%@", __func__, nodeSubtype2, node.surface);
                    }
#endif
                }
                if (merge) {
                    lastNode.visible = NO;
                    
                    // マージする。
                    _modified = YES;
#if LOG_PATCH
                    DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, lastNode.surface, [lastNode partOfSpeech], node.surface, [node partOfSpeech]);
#endif
                    [node setSurface:[[lastNode surface]                 stringByAppendingString:[node surface]]];
                    @try {
                        [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                    }
                    @catch (NSException *exception) {
                        [node setPronunciation:@"?"];
                    }
                    [node setOriginalForm:[[lastNode originalForm]       stringByAppendingString:[node originalForm]]];

                    if (adverb) {
                        [node setPartOfSpeech:@"副詞"];
                        [node setPartOfSpeechSubtype1:@""];
                        [node setPartOfSpeechSubtype2:@""];
                    }
                    node.modified = YES;
                    
                    if (retainLastSubtype) {
                        [node setPartOfSpeechSubtype1:[lastNode partOfSpeechSubtype1]];
                    }
                }
            }
        }
        lastNode = node;
    }
}

// 動詞の連結
// 【注意】語幹の連結前に実行すること！！
- (void) patch_merge_DOSHI {
    Node *lastNode = nil;
    
    NSSet *transitiveVerbSuffixes = [NSSet setWithObjects:@"す", @"さす", nil];
    NSString *mergeDelim = _appDelegate.developmentMode ? @"+" : @"";
    BOOL retainOriginalForm = _appDelegate.developmentMode;
    
    for (Node *node in _nodes) {
        if (node.visible == NO) {
            continue;
        }
        if (lastNode) {
            if ([[node partOfSpeech] isEqualToString:@"動詞"])
            {
                NSString *originalForm = [node originalForm];
                BOOL prefix = NO;
                BOOL suffix = NO;
                
                if ([[lastNode partOfSpeech] isEqualToString:@"動詞"])
                {// 動詞
                    if ([[node partOfSpeechSubtype1] isEqualToString:@"接尾"])
                    {// 動詞＆動詞（接尾辞）である。
                        suffix = YES;
                    }
                } else if ([[lastNode partOfSpeech] isEqualToString:@"接頭詞"]) {
                    {// 接頭詞（名詞接続？）＆動詞である。
                        prefix = YES;
                    }
                }
                if (prefix || suffix) {
                    BOOL transitiveVerb = NO;
                    
                    lastNode.visible = NO;
                    
                    // マージする。
                    _modified = YES;
#if LOG_PATCH
                    DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, lastNode.surface, [lastNode partOfSpeech], node.surface, [node partOfSpeech]);
#endif
                    // 他動詞
                    if (suffix && [transitiveVerbSuffixes member:originalForm]) {
                        [node setPartOfSpeechSubtype1:@"他動詞"];
                        transitiveVerb = YES;
                    }
                    [node setSurface:[[lastNode surface]                 stringByAppendingString:[node surface]]];
                    @try {
                        [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                    }
                    @catch (NSException *exception) {
                        [node setPronunciation:@"?"];
                    }
                    if (transitiveVerb)
                    {// 他動詞のサフィックスだとこれで最後（？）なので、常時終止形でなく現状の活用を原型にする。
                        if (retainOriginalForm) {
                            [node setOriginalForm:[NSString stringWithFormat:@"%@%@%@", [lastNode originalForm], mergeDelim, originalForm]];
                        } else {
                            [node setOriginalForm:[NSString stringWithFormat:@"%@%@%@", lastNode.surface, mergeDelim, originalForm]];
                        }
                        // 活用は、サフィックスのを用いる。
                    } else {
                        if (retainOriginalForm) {
                            [node setOriginalForm:[NSString stringWithFormat:@"%@%@%@", [lastNode originalForm], mergeDelim, originalForm]];
                        } else {
                            [node setOriginalForm:[NSString stringWithFormat:@"%@%@%@", lastNode.surface, mergeDelim, originalForm]];
                        }
//                        if (suffix) {
                            // 「サ変・スル」などを保つ
                            [node setInflection:[lastNode inflection]];
//                        }
                    }
                    node.modified = YES;
                }
            }
        }
        lastNode = node;
    }
}

// 複合動詞の連結（動詞＋動詞）
// 【注意】語幹の連結前に実行すること！！
- (void) patch_merge_FUKUGO_DOSHI {

    Node *lastNode = nil;
    NSString *mergeDelim = _appDelegate.developmentMode ? @"+" : @"";
    BOOL retainOriginalForm = _appDelegate.developmentMode;
    
    for (NSUInteger index = 0; index < [_nodes count]; index++) {
        Node *node = _nodes[index];
        if (node.visible == NO) {
            continue;
        }
        
        if ([[lastNode partOfSpeech] isEqualToString:@"動詞"]) {
            if ([[node partOfSpeech] isEqualToString:@"動詞"] && [[node partOfSpeechSubtype1] isEqualToString:@"非自立"])
            {//
                lastNode.visible = NO;
                
                // マージする。
                _modified = YES;
#if LOG_PATCH
                DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, lastNode.surface, [lastNode partOfSpeech], node.surface, [node partOfSpeech]);
#endif
                [node setPartOfSpeechSubtype1:@"複合動詞"];
                
                [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                if (retainOriginalForm) {
                    [node setOriginalForm:[NSString stringWithFormat:@"%@%@%@", [lastNode originalForm], mergeDelim, [node originalForm]]];
                } else {
                    [node setOriginalForm:[NSString stringWithFormat:@"%@%@%@", lastNode.surface, mergeDelim, [node originalForm]]];
                }
                [node setInflection:[NSString stringWithFormat:@"%@&%@", [lastNode inflection], [node inflection]]];
                node.modified = YES;
            }
        }
        lastNode = node;
    }
}

// 複合動詞の連結（名詞＋動詞）
// 【複合動詞（サ変接続など）】
// 【注意】語幹の連結前に実行すること！！
- (void) patch_merge_FUKUGO_DOSHI_SAHEN {

    Node *lastNode = nil;
    NSString *mergeDelim = _appDelegate.developmentMode ? @"+" : @"";
    BOOL retainOriginalForm = _appDelegate.developmentMode;
    
    for (NSUInteger index = 0; index < [_nodes count]; index++) {
        Node *node = _nodes[index];
        if (node.visible == NO) {
            continue;
        }
        NSString *lastPartOfSpeechSubtype1 = [lastNode partOfSpeechSubtype1];   // サ変接続
        NSString *inflection = [node inflection];                               // サ変・スル
        
        if ([lastPartOfSpeechSubtype1 length] > 2 && [inflection length] > 2) {
            NSString *type = [lastPartOfSpeechSubtype1 substringToIndex:2];     // サ変
            NSString *key = [lastPartOfSpeechSubtype1 substringFromIndex:2];    // 接続
            NSString *inflectionKey = [inflection substringToIndex:2];          // サ変
            NSString *inflectionKey2 = [inflection substringFromIndex:[inflection length] - 2]; // サ行
            BOOL sahen = [type isEqualToString:inflectionKey];                                              // 〜する
            BOOL godanSagyo = ([type isEqualToString:@"サ変"] && [inflectionKey2 isEqualToString:@"サ行"]);  // 〜いたす（候文）
            
            if ((sahen || godanSagyo) && [key isEqualToString:@"接続"]) {
                if ([[lastNode partOfSpeech] isEqualToString:@"名詞"] && [[node partOfSpeech] isEqualToString:@"動詞"])
                {//
                    lastNode.visible = NO;
                    
                    // マージする。
                    _modified = YES;
#if LOG_PATCH
                    DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, lastNode.surface, [lastNode partOfSpeech], node.surface, [node partOfSpeech]);
#endif
                    [node setPartOfSpeechSubtype1:@"複合動詞"];
                    
                    [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                    [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                    if (retainOriginalForm) {
                        [node setOriginalForm:[NSString stringWithFormat:@"%@%@%@", [lastNode originalForm], mergeDelim, [node originalForm]]];
                    } else {
                        [node setOriginalForm:[NSString stringWithFormat:@"%@%@%@", lastNode.surface, mergeDelim, [node originalForm]]];
                    }
                    [node setInflection:[NSString stringWithFormat:@"%@", [node inflection]]];
                    node.modified = YES;
                }
            }
        }
        lastNode = node;
    }
}

// ナイ形容詞語幹＆「が、の」＆「ない」場合、格助詞をナイ形容詞語幹に連結して patch_merge_GOKAN に備える。
// 【注意】語幹の連結前に実行すること！！
- (void) patch_before_merge_GOKAN {
    Node *lastNode = nil;
    Node *nextNode = nil;
    
    for (NSUInteger index = 0; index < [_nodes count]; index++) {
        Node *node = _nodes[index];
        if (node.visible == NO) {
            continue;
        }
        nextNode = [self nextNode:index];

        if (lastNode && nextNode) {
            if ([[node partOfSpeech] isEqualToString:@"助詞"])
            {// 和布蕪は「の」を格助詞として返さないので、partOfSpeechSubtype1 で判断できない。
                NSString *pronunciation = [node pronunciation];

                if ([pronunciation isEqualToString:@"ガ"] || [pronunciation isEqualToString:@"ノ"])
                {// 格助詞「が」「の」
                    NSString *lastGokanStr = [self gokanString:lastNode];
                    
                    if ([lastGokanStr length]) {
                        if ([lastGokanStr isEqualToString:@"ナイ形容詞"] &&
                            [[nextNode originalForm] isEqualToString:@"ない"])
                        {
                            node.visible = NO;
                            
                            // マージする。
                            _modified = YES;
#if LOG_PATCH
                            DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, lastNode.surface, [lastNode partOfSpeech], node.surface, [node partOfSpeech]);
#endif
#if LOG_MERGE
                            DEBUG_LOG(@"語幹マージに先立ち、予めココでナイ形容詞語幹に「%@」をマージしておく。[%@]+[%@]", pronunciation, lastNode.surface, node.surface);
#endif
                            [lastNode setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                            [lastNode setPronunciation:[[lastNode pronunciation] stringByAppendingString:pronunciation]];
                            [lastNode setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                            [lastNode setInflection:[@"" stringByAppendingString:[node inflection]]];
                            lastNode.modified = YES;
                            node = lastNode;
                        }
                    }
                }
            }
        }
        lastNode = node;
    }
}

// 名詞の接尾辞「〜がち」（形容動詞）「〜ぎみ」（形容動詞）「〜やすい」（形容詞）の連結
// 【注意】語幹の連結前に実行すること！！
- (void) patch_merge_GACHI_GIMI_YASUI {

    Node *lastNode = nil;
    NSString *mergeDelim = _appDelegate.developmentMode ? @"+" : @"";
    BOOL retainOriginalForm = _appDelegate.developmentMode;
    
    for (Node *node in _nodes) {
        if (node.visible == NO) {
            continue;
        }
        if (lastNode) {
            NSString *pronunciation = [node pronunciation];
            BOOL merge = NO;

            if ([[lastNode partOfSpeech] isEqualToString:@"動詞"])
            {// 動詞
                if ([[node partOfSpeech] isEqualToString:@"名詞"])
                {
                    if ([[node partOfSpeechSubtype1] isEqualToString:@"接尾"])
                    {// 動詞＆名詞（接尾辞）「がち」である。
                        if ([pronunciation isEqualToString:@"ガチ"]) {
//                            [node setPartOfSpeechSubtype2:@"形容動詞語幹"];
                            merge = YES;
                        } else if ([pronunciation isEqualToString:@"ギミ"]) {
                            [node setPartOfSpeechSubtype2:@"形容動詞語幹"];
                            merge = YES;
                        }
                    }
                } else if ([[node partOfSpeech] isEqualToString:@"形容詞"])
                {
                    if ([[node partOfSpeechSubtype1] isEqualToString:@"非自立"]) {
                        if ([pronunciation isEqualToString:@"ヤスイ"]) {
                            [node setPartOfSpeechSubtype1:@""];
                            [node setPartOfSpeechSubtype2:@"形容詞語幹"];
                            merge = YES;
                        }
                    }
                }
            }
            if (merge) {
                lastNode.visible = NO;
                
                // マージする。
                _modified = YES;
#if LOG_PATCH
                DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, lastNode.surface, [lastNode partOfSpeech], node.surface, [node partOfSpeech]);
#endif
                [node setSurface:[[lastNode surface]                 stringByAppendingString:[node surface]]];
                @try {
                    [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:pronunciation]];
                }
                @catch (NSException *exception) {
                    [node setPronunciation:@"?"];
                }
                if (retainOriginalForm) {
                    [node setOriginalForm:[NSString stringWithFormat:@"%@%@%@", [lastNode originalForm], mergeDelim, [node originalForm]]];
                } else {
                    [node setOriginalForm:[NSString stringWithFormat:@"%@%@%@", lastNode.surface, mergeDelim, [node originalForm]]];
                }
                if ([[node partOfSpeechSubtype2] isEqualToString:@"形容詞語幹"]) {
                    [node setPartOfSpeechSubtype1:@"複合形容詞"];
                } else if ([[node partOfSpeechSubtype2] isEqualToString:@"形容動詞語幹"]) {
                    [node setPartOfSpeechSubtype1:@"複合形容動詞"];
                }
                node.modified = YES;
            }
        }
        lastNode = node;
    }
}

// 動詞に連なる「ん」「んで」の名詞「ん」を「の」（助詞化）にする。
// 和布蕪は名詞に連なる場合の「ん」処理は出来ているが、それに準じて「格助詞」にする。eg.「佐賀ん鳥栖」は処理できている。
// 【注意】語幹の連結前に実行すること！！
- (void) patch_merge_N {
    Node *lastNode = nil;
    
    for (Node *node in _nodes) {
        if (node.visible == NO) {
            continue;
        }
        if (lastNode) {
            BOOL changed = NO;
            
            if ([[lastNode partOfSpeech] isEqualToString:@"動詞"])
            {// 動詞
                if ([[node partOfSpeech] isEqualToString:@"名詞"])
                {
                    if ([[node partOfSpeechSubtype1] isEqualToString:@"非自立"])
                    {// 動詞＆名詞「ん」である。
                        if ([[node originalForm] isEqualToString:@"ん"]) {
                            changed = YES;
                        }
                    }
                }
            }
            if (changed) {
                // 変換する。
                _modified = YES;
#if LOG_PATCH
                DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, node.surface, [node partOfSpeech], node.surface, @"助詞");
#endif
                [node setPartOfSpeech:@"助詞"];
                [node setPartOfSpeechSubtype1:@"格助詞"];
                [node setPartOfSpeechSubtype2:@"「の」撥音便"];
                [node setOriginalForm:@"の"];
                node.modified = YES;
            }
        }
        lastNode = node;
    }
}

// 複合動詞の連結（名詞＋動詞）
// 名詞に連なる動詞の（事実上の）接尾辞「〜じみる」の連結（複合動詞化）
// 【注意】語幹の連結前に実行すること！！
- (void) patch_merge_JIMI {

    Node *lastNode = nil;
    NSString *mergeDelim = _appDelegate.developmentMode ? @"+" : @"";
    BOOL retainOriginalForm = _appDelegate.developmentMode;
    
    for (Node *node in _nodes) {
        if (node.visible == NO) {
            continue;
        }
        if (lastNode) {
            NSString *pronunciation = [node pronunciation];
            BOOL merge = NO;
            
            if ([[lastNode partOfSpeech] isEqualToString:@"名詞"])
            {// 動詞
                if ([[node partOfSpeech] isEqualToString:@"動詞"])
                {
                    if ([[node originalForm] isEqualToString:@"じみる"])
                    {// 名詞＆動詞（事実上の接尾辞）「じみる」である。
                        merge = YES;
                    }
                }
            }
            if (merge) {
                lastNode.visible = NO;
                
                // マージする。
                _modified = YES;
#if LOG_PATCH
                DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, lastNode.surface, [lastNode partOfSpeech], node.surface, [node partOfSpeech]);
#endif
                [node setSurface:[[lastNode surface]                 stringByAppendingString:[node surface]]];
//                [node setPartOfSpeech:@"動詞"];
                [node setPartOfSpeechSubtype1:@"複合動詞"];
                @try {
                    [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:pronunciation]];
                }
                @catch (NSException *exception) {
                    [node setPronunciation:@"?"];
                }
                if (retainOriginalForm) {
                    [node setOriginalForm:[NSString stringWithFormat:@"%@%@%@", [lastNode originalForm], mergeDelim, [node originalForm]]];
                } else {
                    [node setOriginalForm:[NSString stringWithFormat:@"%@%@%@", lastNode.surface, mergeDelim, [node originalForm]]];
                }
                node.modified = YES;
            }
        }
        lastNode = node;
    }
}

#pragma mark - Patch (マージ2)
// 語幹の連結（自分の前が語幹の場合）
- (void) patch_merge_GOKAN {
    Node *lastLastNode = nil;
    Node *lastNode = nil;
    NSSet *keiyoshiSuffixes = [NSSet setWithObjects:@"らしい", nil];
    NSSet *keiyodoshiSuffixes = [NSSet setWithObjects:@"だ", @"で", @"です", @"な", @"に", @"ね", nil];
    NSSet *jyodoshiSuffixes = [NSSet setWithObjects:@"な", @"に", nil];
    
    for (NSUInteger index = 0; index < [_nodes count]; index++) {
        Node *node = _nodes[index];
        if (node.visible == NO) {
            continue;
        }
    start:
        if (lastNode) {
            NSString *lastGokanStr = [self gokanString:lastNode];

            // 語幹の連結は、原則的に付属語が続く場合。
            // 例外：「ない」形容詞
            if ([MecabPatch isFuzokugo:[node partOfSpeech]] ||
                ([lastGokanStr isEqualToString:@"ナイ形容詞"] && [MecabPatch isKeiyoushi:[node partOfSpeech]]))
            {// 付属語（助詞、助動詞）か、ナイ形容詞
                NSString *surface = node.surface;

                if ([lastGokanStr length]) {
                    if ([surface isEqualToString:@"でも"] && [[node partOfSpeechSubtype1] isEqualToString:@"副助詞"]) // 【注意】ここは絶対に「副助詞」
                    {
                        // 分割する。
                        _modified = YES;
#if SHOW_DEMO_OP
                        DEBUG_LOG(@"先行語:[%@](%@),語幹[%@]", lastNode.surface, [lastNode partOfSpeech], [lastGokanStr length] ? lastGokanStr : @"");
#endif
                        // 【注意】語幹の品詞（形容動詞など）を評価して、引数 rentai に渡す。
                        [self devideNode:node index:index rentai:[MecabPatch isTaigen:lastGokanStr]];

                        // 分割してコンティニューする。
                        goto start;
                    } else
                    {// 語幹（多少の例外がある！！）
                        BOOL inhibitNai = NO;
                        BOOL inhibitRashii = NO;
                        BOOL inhibitKeido = NO;
                        NSString *pronunciation = [node pronunciation];
                        NSString *originalForm = [node originalForm];
                        
                        if ([lastGokanStr isEqualToString:@"ナイ形容詞"] &&
                            [originalForm isEqualToString:@"ない"] == NO)
                        {// ただし、「だらしがない」などは patch_before_merge_GOKAN にて前処理ずみ。
                            inhibitNai = YES;
#if LOG_MERGE
                            DEBUG_LOG(@"条件を満たさない「ナイ形容詞」はマージしない。[%@][%@]", lastNode.surface, node.surface);
#endif
                        } else if ([[lastNode partOfSpeech] isEqualToString:@"名詞"] &&
                                   [lastGokanStr isEqualToString:@"形容動詞"])
                        {
                            if ([keiyoshiSuffixes member:originalForm])
                            {// 形容詞型の助動詞を検知した。
                             // 【注意】形容動詞の語幹は残存し最後の処理で形容動詞化する。
                                inhibitRashii = YES;
#if LOG_MERGE
                                DEBUG_LOG(@"[%@] 形容動詞語幹に連なる「%@」はマージせず最終的に非自立の名詞で残存したら形容動詞化する。", _sentence, node.surface);
#endif
                            } else if ([keiyodoshiSuffixes member:originalForm] == NO)
                            {// 形容動詞型の助動詞ではない。
                                inhibitKeido = YES;
#if LOG_MERGE
                                DEBUG_LOG(@"必須「%@」形容動詞の活用ではない。[%@][%@]", _sentence, lastNode.surface, node.surface);
#endif
                            }
                        }
                        // 【例外1】ナイ形容詞
                        // 【例外2】形容動詞語幹に連なる「らしい」
                        if (inhibitNai == NO && inhibitRashii == NO && inhibitKeido == NO) {
                            lastNode.visible = NO;
                            
                            // マージする。
                            _modified = YES;
#if LOG_PATCH
                            DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, lastNode.surface, [lastNode partOfSpeech], node.surface, [node partOfSpeech]);
#endif
                            if ([[lastLastNode partOfSpeech] isEqualToString:@"名詞"] &&
                                [[lastNode partOfSpeech] isEqualToString:@"名詞"])
                            {
                                if ([lastGokanStr isEqualToString:@"助動詞"] == NO)
                                {// 「〜的だ」「〜がちだ」「〜そうだ」
#if LOG_MERGE
                                    DEBUG_LOG(@"語幹マージ中に連続した名詞を検知した！！");
#endif
                                    lastLastNode.visible = NO;
                                    
#if LOG_PATCH
                                    DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)+「%@」(%@)", __func__, lastLastNode.surface, [lastLastNode partOfSpeech], lastNode.surface, [lastNode partOfSpeech], node.surface, [node partOfSpeech]);
#endif
                                    [lastNode setSurface:[[lastLastNode surface]             stringByAppendingString:[lastNode surface]]];
                                    [lastNode setPronunciation:[[lastLastNode pronunciation] stringByAppendingString:[lastNode pronunciation]]];
                                    [lastNode setOriginalForm:[[lastLastNode originalForm]   stringByAppendingString:[lastNode originalForm]]];
                                } else
                                {// 「馬鹿[名詞:形容動詞語幹]そう[名詞:助動詞語幹]だ[助動詞]」が助動詞になるのを防ぐ。
#if LOG_MERGE
                                    DEBUG_LOG(@"必須「%@」の語幹マージ中に連続した名詞を検知したが、２つ目の名詞が助動詞語幹なのでマージしない！！", _sentence);
#endif
                                }
                            }
                            if ([lastGokanStr isEqualToString:@"助動詞"] &&
                                [[node partOfSpeech] isEqualToString:@"助詞"] &&
                                [jyodoshiSuffixes member:node.surface])
                            {// （助動詞語幹の名詞）「よう」＋（副助詞）「に」→（助動詞）「ように」になる際の終止形を設定する。
#if SHOW_SET_ORIGINAL_FORM
                                DEBUG_LOG(@"終止形の設定：（助動詞語幹の名詞）「%@」＋（助詞）「%@」→（助動詞）「%@%@」になる際の終止形を設定する。", lastNode.surface, node.surface, lastNode.surface, node.surface);
#endif
                                [node setOriginalForm:@"だ"];
                            }
                            [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                            [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:pronunciation]];
                            if ([lastGokanStr isEqualToString:@"形容動詞"]) {
                                [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:@"だ"]];
                            } else {
                                [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                            }
                            if ([lastGokanStr isEqualToString:@"ナイ形容詞"]) {
                                [node setPartOfSpeech:@"形容詞"];
                                [node setPartOfSpeechSubtype1:@"自立"];
                                [node setInflection:@"形容詞・アウオ段"];
                                node.modified = YES;
                            } else {
                                [node setPartOfSpeech:lastGokanStr];
                                [node setInflection:[@"" stringByAppendingString:[node inflection]]];
                                node.modified = YES;
                            }
                            // ゴミ処理
                            if ([[node partOfSpeech] isEqualToString:@"形容動詞"])
                            {
                                if ([[node partOfSpeechSubtype1] isEqualToString:@"格助詞"] || [[node partOfSpeechSubtype1] isEqualToString:@"終助詞"]) {
                                    [node setPartOfSpeechSubtype1:@"+"];
                                    node.modified = YES;
                                }
                            }
                        } else if (inhibitRashii) {
                            _modified = YES;
#if LOG_PATCH
                            DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
#endif
                            [lastNode setPartOfSpeech:@"形容動詞"];
                            [lastNode setOriginalForm:[[lastNode originalForm] stringByAppendingString:@"だ"]];
                            lastNode.modified = YES;
                        }
                    }
                }
            }
        }
        lastLastNode = lastNode;
        lastNode = node;
    }
}

#pragma mark - Patch (マージ3)
// 【複合形容詞化】
// 【注意】語幹の連結後、名詞連結の前に実行すること！！
- (BOOL) patch_FUKUGO_KEIYO_SHI {

    Node *lastNode = nil;
    BOOL asked = NO;
    NSString *mergeDelim = _appDelegate.developmentMode ? @"+" : @"";
    BOOL retainOriginalForm = _appDelegate.developmentMode;
    
    for (NSInteger i = 0; i < [_nodes count]; i++) {
        Node *node = _nodes[i];
        if (node.visible == NO) {
            continue;
        }
        if (lastNode && [[node partOfSpeech] isEqualToString:@"形容詞"]) {
            NSString *gokanStr = [self gokanString:lastNode];
            
            BOOL type1 = [[lastNode partOfSpeech] isEqualToString:@"名詞"] && [[lastNode partOfSpeechSubtype1] isEqualToString:@"接尾"] == NO;
            BOOL type2 = [gokanStr isEqualToString:@"形容詞"];
            BOOL type3 = [[lastNode partOfSpeech] isEqualToString:@"動詞"] && [[lastNode useOfType] isEqualToString:@"連用形"];
            BOOL type4 = [[lastNode partOfSpeech] isEqualToString:@"形容詞"];
            
#ifdef DEBUG
//            if (type1 == NO && [[lastNode partOfSpeech] isEqualToString:@"名詞"]) {
//                DEBUG_LOG(@"[%@]+[%@]", lastNode.surface, node.surface);
//            }
#endif
            if (type1 || type2 || type3 || type4)
            {
                lastNode.visible = NO;
                
                // マージする。
                _modified = YES;
#if LOG_PATCH
                DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, lastNode.surface, [lastNode partOfSpeech], node.surface, [node partOfSpeech]);
#endif
                [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                if (retainOriginalForm) {
                    [node setOriginalForm:[NSString stringWithFormat:@"%@%@%@", [lastNode originalForm], mergeDelim, [node originalForm]]];
                } else {
                    [node setOriginalForm:[NSString stringWithFormat:@"%@%@%@", lastNode.surface, mergeDelim, [node originalForm]]];
                }
                [node setPartOfSpeechSubtype1:@"複合形容詞"];
                [node setPartOfSpeechSubtype2:@""];
                [node setInflection:[@"" stringByAppendingString:[node inflection]]];
                node.modified = YES;
            }
        }
        lastNode = node;
    }
    return asked;
}

// 【派生形容詞化】
// 【注意】語幹の連結後、名詞連結の前に実行すること！！
- (BOOL) patch_HASEI_KEIYO_SHI {
    Node *lastNode = nil;
    BOOL asked = NO;
    
    for (NSInteger i = 0; i < [_nodes count]; i++) {
        Node *node = _nodes[i];
        if (node.visible == NO) {
            continue;
        }
        if (lastNode && [[node partOfSpeech] isEqualToString:@"形容詞"]) {
            BOOL type1 = [[lastNode partOfSpeech] isEqualToString:@"接頭詞"];
            
            if (type1)
            {
                lastNode.visible = NO;
                
                // マージする。
                _modified = YES;
#if LOG_PATCH
                DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, lastNode.surface, [lastNode partOfSpeech], node.surface, [node partOfSpeech]);
#endif
                [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                
                [node setPartOfSpeechSubtype1:@"派生形容詞"];
                [node setPartOfSpeechSubtype2:@""];
                [node setInflection:[@"" stringByAppendingString:[node inflection]]];
                node.modified = YES;
            }
        }
        lastNode = node;
    }
    return asked;
}

#pragma mark - Patch (マージ4)

// 名詞の連結
// 【注意】語幹の連結後に実行すること！！
- (void) patch_merge_MEISHI {

    Node *lastNode = nil;
    NSString *mergeDelim = _appDelegate.developmentMode ? @"." : @"";
    BOOL retainOriginalForm = _appDelegate.developmentMode;
    
    for (Node *node in _nodes) {
        if (node.visible == NO) {
            continue;
        }
        if (lastNode) {
            if ([[node partOfSpeech] isEqualToString:@"名詞"])
            {
                BOOL merge = NO;
                BOOL retainLastSubtype = NO;
                BOOL adverb = NO;
                BOOL noun = NO;
                NSString *lastPartOfSpeech = [lastNode partOfSpeech];

                if ([lastPartOfSpeech isEqualToString:@"名詞"] ||
                    [lastPartOfSpeech isEqualToString:@"動詞"] ||
                    [lastPartOfSpeech isEqualToString:@"形容詞"]
                )
                {// 名詞｜動詞｜形容詞
                    if ([[node partOfSpeechSubtype1] isEqualToString:@"接尾"])
                    {// 派生名詞
                     //（名詞｜動詞｜形容詞）＆名詞（接尾辞）である。
                        merge = YES;
                        retainLastSubtype = YES;
                    } else if ([lastPartOfSpeech isEqualToString:@"名詞"])
                    {// 複合名詞
                     // 名詞が連続している。
                        if ([[node partOfSpeechSubtype1] isEqualToString:@"副詞可能"] &&
                            [[node pronunciation] isEqualToString:@"イライ"])
                        {// 「以来」を「今日限り」「それ以上」「する以上」に合わせる。
                            merge = YES;
                            adverb = YES;
                        } else {
                            merge = YES;
                            retainLastSubtype = YES;
                        }
                    } else if ([[node partOfSpeechSubtype2] isEqualToString:@"副詞可能"])
                    {// （名詞｜動詞）＆副詞可能　eg.「今日限り」「それ以上」「する以上」
                        merge = YES;
                        adverb = YES;
                    } else if ([lastPartOfSpeech isEqualToString:@"動詞"] &&
                               (
                                ([[lastNode useOfType] isEqualToString:@"基本形"] && [[node originalForm] isEqualToString:@"こと"]) ||
                                ([[lastNode useOfType] isEqualToString:@"連用形"] && [[node partOfSpeech] isEqualToString:@"名詞"])
                               )
                    )
                    {// 複合名詞
                     // （動詞[終止形]）＆「こと」　eg.「すること（名詞化）」「歩くこと（名詞化）」
                     // （動詞[連用形]）＆（名詞）　eg.「打ち明け話（名詞化）」
#if SHOW_FUKUGO_MEISHI
                        DEBUG_LOG(@"複合名詞:[%@]+[%@]", lastNode.surface, node.surface);
#endif
                        merge = YES;
                        noun = YES;
                    }
#if SHOW_KANOU
                    NSString *lastSubtype1 = [lastNode partOfSpeechSubtype1];
                    NSString *nodeSubtype2 = [node partOfSpeechSubtype2];
                    
                    if ([lastSubtype1 length] > 2 && [[lastSubtype1 substringFromIndex:[lastSubtype1 length] - 2] isEqualToString:@"可能"]) {
                        DEBUG_LOG(@"%s [%@]%@", __func__, lastSubtype1, lastNode.surface);
                    }
                    if ([nodeSubtype2 length] > 2 && [[nodeSubtype2 substringFromIndex:[nodeSubtype2 length] - 2] isEqualToString:@"可能"]) {
                        DEBUG_LOG(@"%s [%@]%@", __func__, nodeSubtype2, node.surface);
                    }
#endif
                } else if ([[lastNode partOfSpeech] isEqualToString:@"接頭詞"] &&
                           [[lastNode partOfSpeechSubtype1] isEqualToString:@"名詞接続"])
                {// 派生名詞
                 // 接頭詞・名詞接続に続いた名詞である。
                 // 直前が名詞接続の接頭詞である。
                    merge = YES;
                }
                if (merge) {
                    lastNode.visible = NO;
                    
                    // マージする。
                    _modified = YES;
#if LOG_PATCH
                    DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, lastNode.surface, [lastNode partOfSpeech], node.surface, [node partOfSpeech]);
#endif
                    [node setSurface:[[lastNode surface]                 stringByAppendingString:[node surface]]];
                    @try {
                        [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                    }
                    @catch (NSException *exception) {
                        [node setPronunciation:@"?"];
                    }
//                    if (noun) {
                        if (retainOriginalForm) {
                            [node setOriginalForm:[NSString stringWithFormat:@"%@%@%@", [lastNode originalForm], mergeDelim, [node originalForm]]];
                        } else {
                            [node setOriginalForm:[NSString stringWithFormat:@"%@%@%@", lastNode.surface, mergeDelim, [node originalForm]]];
                        }
//                    } else {
//                        [node setOriginalForm:[[lastNode originalForm]       stringByAppendingString:[node originalForm]]];
//                    }
                    node.modified = YES;
                    
                    if (retainLastSubtype) {
//                        [node setPartOfSpeechSubtype1:[lastNode partOfSpeechSubtype1]];
                        [node setPartOfSpeechSubtype1:@"派生名詞"];
#if SHOW_HASEI_MEISHI
                        DEBUG_LOG(@"派生名詞:[%@][%@]", lastNode.surface, node.surface);
#endif
                    } else if (adverb) {
                        [node setPartOfSpeech:@"副詞"];
                        [node setPartOfSpeechSubtype1:@""];
                        [node setPartOfSpeechSubtype2:@""];
#if SHOW_FUKUSHIKA
                        DEBUG_LOG(@"副詞化:[%@][%@]", lastNode.surface, node.surface);
#endif
                    } else if (noun) {
                        [node setPartOfSpeechSubtype1:@"複合名詞"];
                        [node setPartOfSpeechSubtype2:@"動詞.名詞"];
#if SHOW_FUKUGO_MEISHI
                        DEBUG_LOG(@"複合名詞:[%@][%@]", lastNode.surface, node.surface);
#endif
                    } else {
#if SHOW_FUKUGO_MEISHI
                        DEBUG_LOG(@"複合名詞？:[%@][%@]", lastNode.surface, node.surface);
#endif
                    }
                }
            }
        }
        lastNode = node;
    }
}

#pragma mark - Patch (パッチ)

// 【副詞化】副詞可能な名詞＋「、」→副詞
- (void) patch_detect_FUKUSHI {
    Node *nextNode = nil;
    
    for (NSInteger i = 0; i < [_nodes count]; i++) {
        Node *node = _nodes[i];
        if (node.visible == NO) {
            continue;
        }
        nextNode = [self nextNode:i];
        
        if (nextNode &&
            [[node partOfSpeech] isEqualToString:@"名詞"] &&
            ([[node partOfSpeechSubtype1] isEqualToString:@"副詞可能"] || [[node partOfSpeechSubtype2] isEqualToString:@"副詞可能"] || [[node partOfSpeechSubtype3] isEqualToString:@"副詞可能"]) &&
            ([nextNode.surface isEqualToString:@"、"] || [MecabPatch isYougen:[nextNode partOfSpeech]]))
        {
            // 修正された。
            _modified = YES;

            [node setPartOfSpeech:@"副詞"];
            [node setPartOfSpeechSubtype1:@""];
            [node setPartOfSpeechSubtype2:@""];
            [node setPartOfSpeechSubtype3:@""];
            node.modified = YES;
#if LOG_PATCH
            DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
#endif
        }
    }
}

// 【助動詞化】体言＋助詞「で、」→助動詞「だ」（連用形）
// 【注意】後端の「、」が必須条件（制限事項！！）
- (void) patch_TAIGEN_DA {
    Node *lastNode = nil;
    Node *nextNode = nil;
    
    for (NSInteger i = 0; i < [_nodes count]; i++) {
        Node *node = _nodes[i];
        if (node.visible == NO) {
            continue;
        }
        nextNode = [self nextNode:i];

        if (lastNode && [MecabPatch isTaigen:[lastNode partOfSpeech]] &&
            nextNode && [nextNode.surface isEqualToString:@"、"])
        {
            if ([[node partOfSpeech] isEqualToString:@"助詞"] &&
                [node.surface isEqualToString:@"で"])
            {
                // 修正された。
                _modified = YES;

                [node setPartOfSpeech:@"助動詞"];
                [node setPartOfSpeechSubtype1:@""];
                [node setPartOfSpeechSubtype2:@""];
                [node setOriginalForm:@"だ"];
                [node setUseOfType:@"連用形"];
                [node setInflection:[@"" stringByAppendingString:@"断定"]];
                node.modified = YES;
#if LOG_PATCH
                DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
#endif
            }
        }
        lastNode = node;
    }
}

// 【準体助詞】「なのだ」「向こうから来るのは」の「の」が名詞ではおかしい。
// 【注意】非自立の名詞「の」は準体助詞
// 【注意】「から」は格助詞になっているので準体助詞化させる必要はないか？
- (void) patch_NANODA_NO {
    
    for (Node *node in _nodes) {
        if (node.visible == NO) {
            continue;
        }
        if (([node.surface isEqualToString:@"の"] || [node.surface isEqualToString:@"から"]) &&
            [[node partOfSpeech] isEqualToString:@"名詞"])
        {
            if ([[node partOfSpeechSubtype1] isEqualToString:@"非自立"])
            {// 準体助詞である。
                // 修正された。
                _modified = YES;

                [node setPartOfSpeech:@"助詞"];
                [node setPartOfSpeechSubtype1:@"準体助詞"];
                [node setPartOfSpeechSubtype2:@""];
                node.modified = YES;
#if LOG_PATCH
                DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
#endif
            }
        }
    }
}

// 【感動詞】「そう」がいつも副詞ではおかしい。
- (void) patch_KANDOSHI_SO {

    NSSet *kandoshiLiterals = [NSSet setWithObjects:@"そう", nil];
    
    if ([_nodes count] == 1) {
        Node *node = _nodes[0];
        if (node.visible) {
            if ([kandoshiLiterals member:node.surface] &&
                [[node partOfSpeech] isEqualToString:@"副詞"] &&
                [[node partOfSpeechSubtype1] isEqualToString:@"助詞類接続"])
            {
                // 修正された。
                _modified = YES;

                [node setPartOfSpeech:@"感動詞"];
                [node setPartOfSpeechSubtype1:@""];
                [node setPartOfSpeechSubtype2:@""];
                node.modified = YES;
#if LOG_PATCH
                DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
#endif
            }
        }
    } else if ([_nodes count] > 1) {
        for (NSUInteger i = 0; i < [_nodes count]; i++) {
            Node *node = _nodes[i];
            if (node.visible == NO) {
                continue;
            }
            if ([kandoshiLiterals member:node.surface] &&
                [[node partOfSpeech] isEqualToString:@"副詞"] &&
                [[node partOfSpeechSubtype1] isEqualToString:@"助詞類接続"])
            {// 副詞である。
                if (i < [_nodes count] - 1) {
                    if ([self isKutouTen:i + 1])
                    {
                        // 修正された。
                        _modified = YES;

                        [node setPartOfSpeech:@"感動詞"];
                        [node setPartOfSpeechSubtype1:@""];
                        [node setPartOfSpeechSubtype2:@""];
                        node.modified = YES;
#if LOG_PATCH
                        DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
#endif
                    }
                } else {
                    // 修正された。
                    _modified = YES;

                    [node setPartOfSpeech:@"感動詞"];
                    [node setPartOfSpeechSubtype1:@""];
                    [node setPartOfSpeechSubtype2:@""];
                    node.modified = YES;
#if LOG_PATCH
                    DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
#endif
                }
            }
        }
    }
}

// 【感動詞】「ああ」は用言が続いても副詞でないことがある。
- (void) patch_KANDOSHI_AA {
    
    NSSet *kandoshiLiterals = [NSSet setWithObjects:@"ああ", nil];
    
    if ([_nodes count] == 1) {
        Node *node = _nodes[0];
        if (node.visible) {
            if ([kandoshiLiterals member:node.surface] &&
                [[node partOfSpeech] isEqualToString:@"副詞"] &&
                [[node partOfSpeechSubtype1] isEqualToString:@"助詞類接続"])
            {
                // 修正された。
                _modified = YES;
                
                [node setPartOfSpeech:@"感動詞"];
                [node setPartOfSpeechSubtype1:@""];
                [node setPartOfSpeechSubtype2:@""];
                node.modified = YES;
#if LOG_PATCH
                DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
#endif
            }
        }
    } else if ([_nodes count] > 1) {
        for (NSUInteger i = 0; i < [_nodes count]; i++) {
            Node *node = _nodes[i];
            if (node.visible == NO) {
                continue;
            }
            if ([kandoshiLiterals member:node.surface]) {
                NSString *partOfSpeech = [node partOfSpeech];

                if ([partOfSpeech isEqualToString:@"副詞"])
                {// 副詞である。
                    if ([[node partOfSpeechSubtype1] isEqualToString:@"助詞類接続"]) {
                        if (i < [_nodes count] - 1) {
                            if ([self isKutouTen:i + 1])
                            {
                                // 修正された。
                                _modified = YES;
                                
                                [node setPartOfSpeech:@"感動詞"];
                                [node setPartOfSpeechSubtype1:@""];
                                [node setPartOfSpeechSubtype2:@""];
                                node.modified = YES;
#if LOG_PATCH
                                DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
#endif
                            }
                        } else {
                            // 修正された。
                            _modified = YES;
                            
                            [node setPartOfSpeech:@"感動詞"];
                            [node setPartOfSpeechSubtype1:@""];
                            [node setPartOfSpeechSubtype2:@""];
                            node.modified = YES;
#if LOG_PATCH
                            DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
#endif
                        }
                    }
                } else if ([partOfSpeech isEqualToString:@"感動詞"]) {
                    Node *nextNode = [self nextNode:i];

                    if (nextNode && [MecabPatch isYougen:[nextNode partOfSpeech]])
                    {// 用言が直後に続いているのに、副詞でないのはおかしい。
                        // 修正された。
                        _modified = YES;
                        
                        [node setPartOfSpeech:@"副詞"];
                        [node setPartOfSpeechSubtype1:@"助詞類接続"];
                        [node setPartOfSpeechSubtype2:@""];
                        node.modified = YES;
#if LOG_PATCH
                        DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
#endif
                    }
                }
            }
        }
    }
}

// 【補助形容詞化】事前のトークンが連用形の形容詞／形容動詞の場合の「ない」「ほしい」「よい（いい）」は補助形容詞。
/*
 -------------------------------------------------------------------------------
 補助形容詞とされるものには、「ない」「ほしい」「よい（いい）」などがあります。
 専門的に研究するのでなければ（中学生や高校生ならば）、この三つを覚えておけば十分です。
 -------------------------------------------------------------------------------
 「ない」は、形容詞や形容動詞、助動詞「だ」の連用形、あるいはそれらに副助詞の付いた形に接続します。
 [例] 楽しく（は）ない、静かで（は）ない、おもしろく（も）ない、元気で（も）ない、私で（も）ない
 
 「ほしい」は、動詞の連用形に接続助詞「て（で）」や、それに副助詞の付いた形に接続します。
 [例] 教えてほしい
 
 「よい」は、用言や助動詞「だ」の連用形に接続助詞「て（で）」の付いた形、
 あるいはそれに副助詞の付いた形に接続します。
 [例] 帰って（も）よい、つまらなくて（も）よい、危険で(も)よい、あなたで（も）よい
 -------------------------------------------------------------------------------
 前に、形容詞・形容動詞の連用形（「～く」「～で」）、接続助詞「て（で）」、副助詞（「は・も」など）があれば
 補助形容詞、というのが見分けるコツです。
 -------------------------------------------------------------------------------
 もっと機械的にいえば、直前に「く・で・て・」か副助詞があれば補助形容詞、ということになります。
 -------------------------------------------------------------------------------
 */
// ※動詞／形容詞／形容動詞に導かれる、補助形容詞「ほしい」「ない」の現状は下記。
// ○動詞+てほしい eg.「きてほしい」
// -形容詞+ほしい
// -形容動詞+ほしい
// ○動詞+ない（助動詞） eg.「こない」
// ×形容詞+ない eg.「かわいくない」
// ×形容動詞+ない eg.「きれいでない」
//
- (void) patch_HOJO_KEIYOUSHI {
    Node *lastNode = nil;
    NSSet *hojyoKeiyoshiSuffixes = [NSSet setWithObjects:@"ナイ", @"ホシイ", @"ヨイ", nil];
    
    for (Node *node in _nodes) {
        if (node.visible == NO) {
            continue;
        }
        if (lastNode)
        {
            if ([hojyoKeiyoshiSuffixes member:[node pronunciation]])
            {
                if ([[node partOfSpeech] isEqualToString:@"形容詞"] || [[node partOfSpeech] isEqualToString:@"助動詞"])
                {// 和布蕪に「助動詞」と誤認されるのもある。
                    NSString *lastPartOfSpeech = [lastNode partOfSpeech];
                    NSString *lastPartOfSpeechSubtype1 = [lastNode partOfSpeechSubtype1];
                    NSString *lastUseOfType = [lastNode useOfType];
                    NSString *lastPronunciation = [lastNode pronunciation];
                    BOOL isRenyo = [MecabPatch isRenyo:lastUseOfType];
#if 0
                    if ((([lastPartOfSpeech isEqualToString:@"形容詞"] || [lastPartOfSpeech isEqualToString:@"形容動詞"]) && isRenyo) ||
                        ([lastPartOfSpeechSubtype1 isEqualToString:@"接続助詞"] && ([lastPronunciation isEqualToString:@"テ"] || [lastPronunciation isEqualToString:@"デ"])) ||
                        ([lastPartOfSpeechSubtype1 isEqualToString:@"係助詞"] && ([lastPronunciation isEqualToString:@"ワ"] || [lastPronunciation isEqualToString:@"モ"]))
                    ) // 連用形の形容詞／形容動詞に連なる場合は補助形容詞。
                    {// 形容詞／形容動詞＋補助形容詞（ない）
                        // 修正された。
                        _modified = YES;
                        
                        [node setPartOfSpeech:@"形容詞"];
                        [node setPartOfSpeechSubtype1:@"補助形容詞"];
                        [node setInflection:@"形・形動の連用(く/で),接助(て|で)"];
                        node.modified = YES;
#if LOG_PATCH
                        DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
#endif
                    }
#else
                    if (([lastPartOfSpeech isEqualToString:@"形容詞"] || [lastPartOfSpeech isEqualToString:@"形容動詞"]) && isRenyo) // 連用形の形容詞／形容動詞に連なる場合は補助形容詞。
                    {// 形容詞／形容動詞＋補助形容詞（ない）
                        // 修正された。
                        _modified = YES;
                        
                        [node setPartOfSpeech:@"形容詞"];
                        [node setPartOfSpeechSubtype1:@"補助形容詞"];
                        [node setInflection:@"形・形動の連用(く/で)"];
                        node.modified = YES;
#if LOG_PATCH
                        DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
#endif
                    } else if (([lastPartOfSpeechSubtype1 isEqualToString:@"接続助詞"] && ([lastPronunciation isEqualToString:@"テ"] || [lastPronunciation isEqualToString:@"デ"])) ||
                               ([lastPartOfSpeechSubtype1 isEqualToString:@"係助詞"] && ([lastPronunciation isEqualToString:@"ワ"] || [lastPronunciation isEqualToString:@"モ"]))
                               ) // 連用形の形容詞／形容動詞に連なる場合は補助形容詞。
                    {// 形容詞／形容動詞＋補助形容詞（ない）
                        // 修正された。
//                        _modified = YES;
//
//                        [node setPartOfSpeech:@"形容詞"];
//                        [node setPartOfSpeechSubtype1:@"補助形容詞"];
//                        [node setInflection:@"接助(て|で)"];
//                        node.modified = YES;
#if LOG_PATCH
                        DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
#endif
                    } else if ([lastPartOfSpeech isEqualToString:@"助動詞"])
                    {// 助動詞（”〜く”）＋助動詞（ない）→形容詞（ない）
                        NSRange range = [lastPronunciation rangeOfString:@"ク"];

                        if (range.length && range.location == [lastPronunciation length] - 1) {
                            // 修正された。
                            _modified = YES;
                            
                            [node setPartOfSpeech:@"形容詞"];
//                            [node setPartOfSpeechSubtype1:@"補助形容詞"];
                            [node setInflection:@"助動詞の連用(く)"];
                            node.modified = YES;
#if LOG_PATCH
                            DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
#endif
                        }
                    }
#endif
                }
            }
        }
        lastNode = node;
    }
}

// 【形容詞化】体言＋助動詞「らしい」＋体言→形容詞（連体形）
// 【形容詞化】体言＋助動詞「らしく」＋用言→形容詞（連用形）
// eg.「人間らしい」
- (void) patch_TAIGEN_RASHII {
    Node *lastNode = nil;
    
    for (NSInteger i = 0; i < [_nodes count]; i++) {
        Node *node = _nodes[i];
        if (node.visible == NO) {
            continue;
        }
        if (lastNode && [MecabPatch isTaigen:[lastNode partOfSpeech]] && [[lastNode partOfSpeechSubtype1] isEqualToString:@"代名詞"] == NO)
        {// 代名詞の「〜らしい、〜らしく」は形容詞にはならない？
            if ([[node partOfSpeech] isEqualToString:@"助動詞"] &&
                [[node originalForm] isEqualToString:@"らしい"] &&
                [[[node inflection] substringToIndex:3] isEqualToString:@"形容詞"])
            {
                Node *nextNode = [self nextNode:i];
                BOOL rentai = [node.surface isEqualToString:@"らしい"] && [MecabPatch isTaigen:[nextNode partOfSpeech]];
//                BOOL renyou = [node.surface isEqualToString:@"らしく"] && [MecabPatch isYougen:[nextNode partOfSpeech]];
                BOOL renyou = [node.surface isEqualToString:@"らしく"]; // 助詞が来る

                if (rentai || renyou)
                {
                    lastNode.visible = NO;
                    
                    // マージする。
                    _modified = YES;
#if LOG_PATCH
                    DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, lastNode.surface, [lastNode partOfSpeech], node.surface, [node partOfSpeech]);
#endif
                    [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                    [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                    [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                    
                    [node setPartOfSpeech:@"形容詞"];
                    [node setPartOfSpeechSubtype1:@""];
                    [node setPartOfSpeechSubtype2:@""];
                    if (rentai) {
                        [node setUseOfType:@"連体形"];
                        [node setInflection:@"形容詞・イ段"];
                    } else if (renyou) {
                        [node setUseOfType:@"連用形"];
                        [node setInflection:@"形容詞・ウ段"];
                    }
//                    [node setInflection:[@"" stringByAppendingString:[node inflection]]];
                    node.modified = YES;
                }
            }
        }
        lastNode = node;
    }
}

// 【終助詞化】末端の接続助詞「とも」は強調を示す終助詞。
- (void) patch_TOMO {
    
    for (NSUInteger i = 0; i < [_nodes count]; i++) {
        Node *node = _nodes[i];
        if (node.visible == NO) {
            continue;
        }
        if ([[node partOfSpeechSubtype1] isEqualToString:@"接続助詞"] &&
            [node.surface isEqualToString:@"とも"])
        {
            if ([self isKutouTen:i + 1])
            {
                // 属性変更された。
                _modified = YES;

                [node setPartOfSpeechSubtype1:@"終助詞"];
                [node setInflection:@"強調"];
                node.modified = YES;
#if LOG_PATCH
                DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
#endif
            }
        }
    }
}

// 【終助詞化】句点を従えた接続助詞「とも」は強調を示す終助詞。
- (void) patch_TOMO_KUTEN {
    Node *lastNode = nil;
    Node *nextNode = nil;
    
    for (NSInteger i = 0; i < [_nodes count]; i++) {
        Node *node = _nodes[i];
        if (node.visible == NO) {
            continue;
        }
        nextNode = [self nextNode:i];

        if (lastNode && [lastNode.surface isEqualToString:@"と"] && [[lastNode partOfSpeechSubtype1] isEqualToString:@"格助詞"] &&
            nextNode && [nextNode.surface isEqualToString:@"。"])
        {
            if ([node.surface isEqualToString:@"も"] && [[node partOfSpeechSubtype1] isEqualToString:@"係助詞"])
            {
                lastNode.visible = NO;
                
                // マージする。
                _modified = YES;
#if LOG_PATCH
                DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, lastNode.surface, [lastNode partOfSpeech], node.surface, [node partOfSpeech]);
#endif
                [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                
                [node setPartOfSpeechSubtype1:@"終助詞"];
                [node setPartOfSpeechSubtype2:@""];
                [node setInflection:[@"" stringByAppendingString:@"強調"]];
                [node setInflection:[@"" stringByAppendingString:[node inflection]]];
                node.modified = YES;
            }
        }
        lastNode = node;
    }
}

// 【接続助詞化】「呼んでも」の「で・も」→接続助詞「でも」
- (void) patch_MERGE_YOUGEN_DEMO {
    Node *lastNode = nil;
    Node *nextNode = nil;
    Node *nextNextNode = nil;
    
    for (NSInteger i = 0; i < [_nodes count]; i++) {
        Node *node = _nodes[i];
        if (node.visible == NO) {
            continue;
        }
        nextNode     = [self nextNode:i];
        nextNextNode = [self nextNextNode:i];

        // 【注意1】MeCab は体言に「でも」が続いた場合、基本的に「で(格助詞)・も(係助詞)」として扱う。
        // 【注意2】MeCab は用言に「でも」が続いた場合、基本的に「で(接続助詞)・も(係助詞)」として扱う。
        // 【注意3】MeCab は「でも」の扱いがよく分からない場合、「でも(副助詞)」として扱う。
        // 【注意4】MeCab の「〜でも[ない]」「〜でも[い]ない」処理結果を適用しマージを禁則する。
        if (lastNode && [MecabPatch isYougen:[lastNode partOfSpeech]] &&
            ([node.surface isEqualToString:@"て"] || [node.surface isEqualToString:@"で"]) && [[node partOfSpeechSubtype1] isEqualToString:@"接続助詞"] &&
            nextNode && [nextNode.surface isEqualToString:@"も"] && [[nextNode partOfSpeechSubtype1] isEqualToString:@"係助詞"]
            && ([nextNextNode.surface isEqualToString:@"ない"] == NO && [nextNextNode.surface isEqualToString:@"い"] == NO)
        )
        {
            nextNode.visible = NO;
            
            // マージする。
            _modified = YES;
#if (LOG_PATCH || SHOW_DEMO_OP)
            DEBUG_LOG(@"連結（連用）：%@[%@],%@:[%@] -> 接続助詞:[%@%@] %@", [node partOfSpeechSubtype1], node.surface, [nextNode partOfSpeechSubtype1], nextNode.surface, node.surface, nextNode.surface, _sentence);
#endif
            [node setSurface:[[node surface]             stringByAppendingString:[nextNode surface]]];
            [node setPronunciation:[[node pronunciation] stringByAppendingString:[nextNode pronunciation]]];
            [node setOriginalForm:[[node originalForm]   stringByAppendingString:[nextNode originalForm]]];
            
            [node setPartOfSpeechSubtype1:@"接続助詞"];
            [node setPartOfSpeechSubtype2:@""];
            [node setOriginalForm:@"ても"];
            [node setInflection:[@"" stringByAppendingString:[node inflection]]];
            node.modified = YES;
        }
        lastNode = node;
    }
}

// 【副助詞の分割】「こちらでも、」の副助詞「でも」→格助詞「で」と副助詞「も」
- (void) patch_DIVIDE_TAIGEN_DEMO {
    Node *lastNode = nil;
    
    for (NSUInteger index = 0; index < [_nodes count]; index++) {
        Node *node = _nodes[index];
        if (node.visible == NO) {
            continue;
        }
        if (lastNode) {
            if (index < [_nodes count] - 1) {
                Node *nextNode = [self nextNode:index];
                
                if ([MecabPatch isTaigen:[lastNode partOfSpeech]] &&
                    [node.surface isEqualToString:@"でも"] && [[node partOfSpeechSubtype1] isEqualToString:@"副助詞"] // 【注意】ここは絶対に「副助詞」
                    && [nextNode.surface isEqualToString:@"、"]
                )
                {
                    // 分割する。
                    _modified = YES;
#ifdef DEBUG
#if SHOW_DEMO_OP
                    NSString *lastGokanString = [self gokanString:lastNode];
                    DEBUG_LOG(@"先行語:[%@](%@),語幹[%@]", lastNode.surface, [lastNode partOfSpeech], [lastGokanString length] ? lastGokanString : @"");
#endif
#endif
                    // 【注意】引数 rentai は何時も YES。
                    [self devideNode:node index:index rentai:YES];
                }
            }
        }
        lastNode = node;
    }
}

// 【副助詞化】「子供でも」の「でも」＋動詞→副助詞「でも」
- (BOOL) patch_MERGE_TAIGEN_DEMO {
    Node *lastNode = nil;
    Node *nextNode = nil;
    BOOL asked = NO;
    
    for (NSInteger i = 0; i < [_nodes count]; i++) {
        Node *node = _nodes[i];
        if (node.visible == NO) {
            continue;
        }
        nextNode = [self nextNode:i];
        if (lastNode && ([lastNode.surface isEqualToString:@"て"] || [lastNode.surface isEqualToString:@"で"]) && [[lastNode partOfSpeechSubtype1] isEqualToString:@"格助詞"] &&
            node && [node.surface isEqualToString:@"も"] && [[node partOfSpeechSubtype1] isEqualToString:@"係助詞"] &&
            nextNode && ([[nextNode partOfSpeech] isEqualToString:@"動詞"] || [[nextNode partOfSpeech] isEqualToString:@"副詞"]))
        {
            lastNode.visible = NO;
            
            // マージする。
            _modified = YES;
#if (LOG_PATCH || SHOW_DEMO_OP)
            DEBUG_LOG(@"連結（連体）：%@[%@],%@:[%@] -> 係助詞:[%@%@] %@", [lastNode partOfSpeechSubtype1], lastNode.surface, [node partOfSpeechSubtype1], node.surface, lastNode.surface, node.surface, _sentence);
#endif
            [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
            [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
            [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
            
            [node setPartOfSpeechSubtype1:@"係助詞"];
            [node setPartOfSpeechSubtype2:@""];
            [node setOriginalForm:@"ても"];
            [node setInflection:[@"" stringByAppendingString:[node inflection]]];
            node.modified = YES;
        }
        lastNode = node;
    }
    return asked;
}

// 【助動詞化】「〜でも、〜でもない」の格助詞「で」＋副助詞「も」→助動詞「で」＋副助詞「も」
- (BOOL) patch_FIX_HEIRITSU_DEMO {
    Node *lastNode = nil;
    Node *nextNode = nil;
    NSUInteger demoIndex = NSNotFound;
    NSUInteger naiIndex = NSNotFound;
    BOOL asked = NO;
    
    // 体言＋格助詞「で」＋副助詞「も」、「ない」検出
    for (NSInteger i = 0; i < [_nodes count]; i++) {
        Node *node = _nodes[i];
        if (node.visible == NO) {
            continue;
        }
        nextNode = [self nextNode:i];
        if ([MecabPatch isTaigen:[lastNode partOfSpeech]] &&
            node && [node.surface isEqualToString:@"で"] && [[node partOfSpeechSubtype1] isEqualToString:@"格助詞"] &&
            nextNode && [nextNode.surface isEqualToString:@"も"] && [[nextNode partOfSpeechSubtype1] isEqualToString:@"係助詞"])
        {
            demoIndex = i;
        }
        if ([node.surface isEqualToString:@"ない"]) {
            naiIndex = i;
        }
        lastNode = node;
    }

    lastNode = nil;
    if (demoIndex != NSNotFound && naiIndex != NSNotFound && naiIndex > demoIndex) {
        for (NSInteger i = 0; i < [_nodes count]; i++) {
            Node *node = _nodes[i];
            if (node.visible == NO) {
                continue;
            }
            nextNode = [self nextNode:i];
            if ([MecabPatch isTaigen:[lastNode partOfSpeech]] &&
                node && [node.surface isEqualToString:@"で"] && [[node partOfSpeechSubtype1] isEqualToString:@"格助詞"] &&
                nextNode && [nextNode.surface isEqualToString:@"も"] && [[nextNode partOfSpeechSubtype1] isEqualToString:@"係助詞"])
            {
                // 変更する。
                _modified = YES;
#if (LOG_PATCH || SHOW_DEMO_OP)
                DEBUG_LOG(@"変更（で,も）：格助詞[で],副助詞:[も] -> 助動詞[で],副助詞:[も] %@", _sentence);
#endif
                [node setOriginalForm:@"だ"];
                [node setPartOfSpeech:@"助動詞"];
                [node setPartOfSpeechSubtype1:@""];
                [node setPartOfSpeechSubtype2:@""];
                [node setUseOfType:@"連用形"];
                [node setInflection:@"断定"];
                node.modified = YES;
            }
            lastNode = node;
        }
    }
    return asked;
}

// 【形容動詞化】「こんな」「そんな」「あんな」「どんな」「同じ」は連体詞ではなく形容動詞
- (BOOL) patch_DONNA {

    NSSet *donnaKeiyodoshiSuffixes = [NSSet setWithObjects:@"コンナ", @"ソンナ", @"アンナ", @"ドンナ", @"オナジ", nil];
    BOOL asked = NO;
    
    for (NSInteger i = 0; i < [_nodes count]; i++) {
        Node *node = _nodes[i];
        if (node.visible == NO) {
            continue;
        }
        
        if (node && [[node partOfSpeech] isEqualToString:@"連体詞"] && [donnaKeiyodoshiSuffixes member:[node pronunciation]])
        {
            // 変更する。
            _modified = YES;
#if LOG_PATCH
            DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, node.surface, [node partOfSpeech], node.surface, @"形容動詞");
#endif
            [node setPartOfSpeech:@"形容動詞"];
            [node setPartOfSpeechSubtype1:@"連体詞ではない"];
            node.modified = YES;
        }
    }
    return asked;
}

// 【副詞化】「例えば」は接続詞ではなく副詞
- (BOOL) patch_TATOEBA {
    
    NSSet *fukushiCandidateSuffixes = [NSSet setWithObjects:@"タトエバ", nil];
    BOOL asked = NO;
    
    for (NSInteger i = 0; i < [_nodes count]; i++) {
        Node *node = _nodes[i];
        if (node.visible == NO) {
            continue;
        }
        
        if (node && [[node partOfSpeech] isEqualToString:@"接続詞"] && [fukushiCandidateSuffixes member:[node pronunciation]])
        {
            // 変更する。
            _modified = YES;
#if LOG_PATCH
            DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, node.surface, [node partOfSpeech], node.surface, @"副詞");
#endif
            [node setPartOfSpeech:@"副詞"];
            [node setPartOfSpeechSubtype1:@"接続詞ではない"];
            node.modified = YES;
        }
    }
    return asked;
}

#pragma mark - Patch (単なる用語の置換)
// 【終止形／連体形／連用形】
- (void) postProcess {
    
    NSSet *doushiSet = [NSSet setWithObjects:@"いる",
                                             @"居る",
                                             @"ある",
                                             @"有る",
                                             @"おる",
                                             @"おく",
                                             @"いく",
                                             @"いける",
                                             @"くる",
                                             @"くれる",
                                             @"くださる",
                                             @"下さる",
                                             @"もらう",
                                             @"貰う",
                                             @"みる",
                                             @"見る",
                                             @"しまう", nil];
    NSSet *keiyoshiSet = [NSSet setWithObjects:@"ほしい",
                                               @"欲しい",
                                               @"いい",
                                               @"よい",
                                               @"良い",
                                               @"やすい",
                                               @"易い", nil];

    for (NSInteger i = 0; i < [_nodes count]; i++) {
        Node *node = _nodes[i];

        if (node.visible == NO) {
            continue;
        }
        NSString *useOfType = [node useOfType];
        NSString *partOfSpeech = [node partOfSpeech];
        NSString *partOfSpeechSubtype1 = [node partOfSpeechSubtype1];
        NSString *originalForm = [node originalForm];
        NSString *inflection = [node inflection];
        NSString *gokanStr = [self gokanString:node];
        Node *nextNode = [self nextNode:i];
        
        // 【名詞（XXX語幹）】partOfSpeech
        if ([partOfSpeech isEqualToString:@"名詞"]) {
            if ([partOfSpeechSubtype1 isEqualToString:@"非自立"])
            {// 残存した補助名詞
//                DEBUG_LOG(@"!!!文章「%@」 の \"%@\" は非自立の名詞", _sentence, originalForm);
                [node setPartOfSpeechSubtype1:@"補助名詞"];
            }
            if ([gokanStr length])
            {// 語幹であると見なされたが未だ名詞であるダメな奴。
                NSString *pronunciation = [node pronunciation];

                if ([gokanStr isEqualToString:@"助動詞"] && [partOfSpeechSubtype1 isEqualToString:@"派生名詞"]) {
                    // 問題ない。
                } else if ([gokanStr isEqualToString:@"ナイ形容詞"]) {
                    // 問題ない。
                } else if ([gokanStr isEqualToString:@"形容動詞"]) {
                    [node setPartOfSpeech:@"形容動詞"];
                    [node setOriginalForm:[[node originalForm] stringByAppendingString:@"だ"]];
                    [node setPartOfSpeechSubtype1:@""];
                } else {
                    if ([pronunciation isEqualToString:@"ヨー"]) {
                        [node setPartOfSpeech:@"助詞"];
                        [node setPartOfSpeechSubtype1:@"終助詞"];
                        [node setPartOfSpeechSubtype2:@""];
                    } else if ([pronunciation isEqualToString:@"イカガ"]) {
                        [node setPartOfSpeech:@"副詞"];
                        [node setPartOfSpeechSubtype1:@""];
                        [node setPartOfSpeechSubtype2:@""];
                    } else {
                        DEBUG_LOG(@"!!![%@]:[名詞]語幹残存：対処が必要か？：「%@」（%@）", _sentence, node.surface, pronunciation);
                    }
                }
            }
        }
        // 【形容詞（XXX語幹）】partOfSpeech
        if ([partOfSpeech isEqualToString:@"形容詞"]) {
            if ([NSLocalizedString(@"cancel", @"キャンセル") isEqualToString:@"キャンセル"] == NO) {
                [node setPartOfSpeech:@"イ形容詞"];
            }
            if ([partOfSpeechSubtype1 isEqualToString:@"非自立"])
            {// 残存した補助形容詞
#ifdef DEBUG
                if ([keiyoshiSet member:originalForm] == NO) {
                    DEBUG_LOG(@"!!!文章「%@」 の \"%@\" は非自立の形容詞", _sentence, originalForm);
                }
#endif
                [node setPartOfSpeechSubtype1:@"補助形容詞"];
            }
            if ([gokanStr length] && [gokanStr isEqualToString:@"形容詞"] == NO)
            {// 語幹であると見なされたが未だ名詞であるダメな奴。
                DEBUG_LOG(@"!!![%@]:[形容詞]語幹残存：対処が必要か？：「%@」", _sentence, node.surface);
            }
        }
        // 【形容動詞（XXX語幹）】partOfSpeech
        if ([partOfSpeech isEqualToString:@"形容動詞"]) {
            if ([NSLocalizedString(@"cancel", @"キャンセル") isEqualToString:@"キャンセル"] == NO) {
                [node setPartOfSpeech:@"ナ形容詞"];
            }
            if ([gokanStr length] && [gokanStr isEqualToString:@"形容動詞"] == NO)
            {// 語幹であると見なされたが未だ名詞であるダメな奴。
                DEBUG_LOG(@"!!![%@]:[形容動詞]語幹残存：対処が必要か？：「%@」", _sentence, node.surface);
            }
        }
        // 【補助動詞】partOfSpeech
        if ([partOfSpeech isEqualToString:@"動詞"])
        {
            if ([partOfSpeechSubtype1 isEqualToString:@"自立"])
            {// 本動詞である。
                [node setPartOfSpeechSubtype1:@"本動詞"];
            }
            if ([partOfSpeechSubtype1 isEqualToString:@"非自立"])
            {// 接続助詞「て」を介するなどして、結合できなかった補助動詞は助動詞にしないと文節を構成してしまう！！
             // eg.「いる」「ある」「しまう」「いく」「くる」「くださる」「もらう」「みる」「おる」...
#ifdef DEBUG
                // 残存した補助形動詞
                if ([doushiSet member:originalForm] == NO) {
                    DEBUG_LOG(@"!!!文章「%@」 の \"%@\" は非自立の動詞", _sentence, originalForm);
                }
#endif
                [node setPartOfSpeechSubtype1:@"補助動詞"];
            }
            if ([partOfSpeechSubtype1 isEqualToString:@"接尾"])
            {// 動詞の接尾辞は助動詞に変換済みであるべき！！
                DEBUG_LOG(@"!!![%@]:[動詞]接尾辞のまま：対処が必要か？：「%@」", _sentence, node.surface);
            }
        }
        // 【係助詞→副助詞】partOfSpeechSubtype1
        if ([partOfSpeechSubtype1 isEqualToString:@"係助詞"] ||
            [partOfSpeechSubtype1 isEqualToString:@"並立助詞"])
        {// 副助詞化される前の属性をメモワイズした。
            [node setPartOfSpeechSubtype2:[@"←" stringByAppendingString:[node partOfSpeechSubtype1]]];
            [node setPartOfSpeechSubtype1:@"副助詞"];
        }
        // 【終止形／連体形／連用形】useOfType
        if ([useOfType isEqualToString:@"基本形"])
        {
            if (([partOfSpeech isEqualToString:@"動詞"] ||
                 [partOfSpeech isEqualToString:@"形容詞"] ||
                 [partOfSpeech isEqualToString:@"形容動詞"]))
            {// 動詞／形容詞／形容動詞である。
                if ([MecabPatch isTaigen:[nextNode partOfSpeech]])
                {// 動詞／形容詞／形容動詞が体言（に連なって／を従えて）いるので「連体形」である。
                    [node setUseOfType:@"連体形"];
#if SHOW_RENTAIKA
                    DEBUG_LOG(@"連体化[%@][%@]", node.surface, nextNode.surface);
#endif

// 【注意】終止形の用言が列挙などで連続している場合に上手く機能しないのでペンディングにする。
//   eg.「身の多い少ないが重大な問題となる。」
//                } else if ([MecabPatch isYougen:[nextNode partOfSpeech]])
//                {// 動詞／形容詞／形容動詞が用言（に連なって／を従えて）いるので「連用形」である。。
//                    DEBUG_LOG(@"連用化[%@][%@]", node.surface, nextNode.surface);
//                    [node setUseOfType:@"連用形"];
                } else {
                    [node setUseOfType:@"終止形"];
                }
            } else {
                [node setUseOfType:@"終止形"];
            }
        } else if ([useOfType isEqualToString:@"体言接続"])
        {
            [node setUseOfType:@"連体形"];
        } else if ([useOfType isEqualToString:@"用言接続"])
        {
            [node setUseOfType:@"連用形"];
        }
        // 一段
        if ([inflection isEqualToString:@"一段"]) {
            NSString *str = [self makeIchidanString:[node pronunciation]];
            
            if ([str length]) {
                [node setInflection:str];
            }
        }
    }
}
@end
