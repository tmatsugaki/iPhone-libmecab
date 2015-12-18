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
@synthesize nodes=_nodes;
@synthesize modified=_modified;

- (id) init {

    self = [super init];
    if (self != nil) {
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
}

#pragma mark -

- (NSString *) gokanString:(Node *)node {
    NSString *lastSubType1 = [node partOfSpeechSubtype1];
    NSString *lastSubType2 = [node partOfSpeechSubtype2];
    NSString *lastSubType3 = [node partOfSpeechSubtype3];
    NSString *baseToken = @"語幹";
    NSString *gokanStr = nil;
    NSUInteger baseTokenLength = [baseToken length];
    
    if ([lastSubType1 length] > baseTokenLength &&
        [[lastSubType1 substringFromIndex:[lastSubType1 length] - baseTokenLength] isEqualToString:baseToken])
    {
        gokanStr = [lastSubType1 substringToIndex:[lastSubType1 length] - baseTokenLength];
    } else if ([lastSubType2 length] > baseTokenLength &&
               [[lastSubType2 substringFromIndex:[lastSubType2 length] - baseTokenLength] isEqualToString:baseToken])
    {
        gokanStr = [lastSubType2 substringToIndex:[lastSubType2 length] - baseTokenLength];
    } else if ([lastSubType3 length] > baseTokenLength &&
               [[lastSubType3 substringFromIndex:[lastSubType3 length] - baseTokenLength] isEqualToString:baseToken])
    {
        gokanStr = [lastSubType3 substringToIndex:[lastSubType3 length] - baseTokenLength];
    }
    return gokanStr;
}

// 【注意】必須の処理
- (void) preProcess {

    for (Node *node in _nodes) {
        NSString *gokanStr = [self gokanString:node];

        if ([gokanStr length]) {
#if LOG_PATCH
            DEBUG_LOG(@"語幹[%@]（%@語幹の%@）", node.surface, gokanStr, [node partOfSpeech]);
#endif
        }
        node.attribute = @"";
        node.visible = YES;
    }
}

#pragma mark - Patch (ツール)

// 用言（動詞／形容詞／形容動詞）である。
- (BOOL) isTaigen:(NSString *)hinshi {
    return ([hinshi isEqualToString:@"名詞"] ||
            [hinshi isEqualToString:@"代名詞"]);
}

// 用言（動詞／形容詞／形容動詞）である。
- (BOOL) isYougen:(NSString *)hinshi {
    return ([hinshi isEqualToString:@"動詞"] ||
            [hinshi isEqualToString:@"形容詞"] ||
            [hinshi isEqualToString:@"形容動詞"]);
}

- (BOOL) isKeiyoushi:(NSString *)hinshi {
    return ([hinshi isEqualToString:@"形容詞"]);
}

- (BOOL) isFuzokugo:(NSString *)hinshi {
    return ([hinshi isEqualToString:@"助詞"] ||
            [hinshi isEqualToString:@"助動詞"]);
}

- (BOOL) isEndOfSentence:(NSUInteger)nextIndex {
    
    BOOL rc = NO;
    
    if (nextIndex < [_nodes count]) {
        Node *node = _nodes[nextIndex];
        
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

#pragma mark - Patch (マージ)

// 複合動詞の連結
- (void) patch_merge_FUKUGO_DOSHI {
    Node *lastNode = nil;
    
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
                [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                [node setInflection:[NSString stringWithFormat:@"%@%@&%@", @"™" , [lastNode inflection], [node inflection]]];
            }
        }
        lastNode = node;
    }
}

// 【複合動詞（サ変接続など）】
- (void) patch_merge_FUKUGO_DOSHI_SAHEN {
    Node *lastNode = nil;
    
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
            
            if ([type isEqualToString:inflectionKey] && [key isEqualToString:@"接続"]) {
                if ([[node partOfSpeech] isEqualToString:@"動詞"] && [[lastNode partOfSpeech] isEqualToString:@"名詞"])
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
                    [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                    [node setInflection:[NSString stringWithFormat:@"%@%@", @"™" , [node inflection]]];
                }
            }
        }
        lastNode = node;
    }
}

// 語幹の連結の前処理
// ナイ形容詞語幹＆「が、の」＆「ない」場合、格助詞をナイ形容詞語幹に連結して patch_merge_GOKAN に備える。
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
                    NSString *gokanStr = [self gokanString:lastNode];
                    
                    if ([gokanStr length]) {
                        if ([gokanStr isEqualToString:@"ナイ形容詞"] &&
                            [[nextNode originalForm] isEqualToString:@"ない"])
                        {
                            node.visible = NO;
                            
                            // マージする。
                            _modified = YES;
#if LOG_PATCH
                            DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, lastNode.surface, [lastNode partOfSpeech], node.surface, [node partOfSpeech]);
#endif
                            DEBUG_LOG(@"ナイ形容詞語幹に「%@」をマージした。[%@]+[%@]", pronunciation, lastNode.surface, node.surface);
                            [lastNode setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                            [lastNode setPronunciation:[[lastNode pronunciation] stringByAppendingString:pronunciation]];
                            [lastNode setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                            [lastNode setInflection:[@"™" stringByAppendingString:[node inflection]]];
                            node = lastNode;
                        }
                    }
                }
            }
        }
        lastNode = node;
    }
}

// 語幹の連結
- (void) patch_merge_GOKAN {
    Node *lastNode = nil;
    
    for (NSUInteger index = 0; index < [_nodes count]; index++) {
        Node *node = _nodes[index];
        if (node.visible == NO) {
            continue;
        }
    start:
        if (lastNode) {
            NSString *gokanStr = [self gokanString:lastNode];

            if (([gokanStr isEqualToString:@"ナイ形容詞"] && [self isKeiyoushi:[node partOfSpeech]]) ||
                [self isFuzokugo:[node partOfSpeech]])
            {// 付属語（助詞、助動詞）
                NSString *lastSubType1 = [lastNode partOfSpeechSubtype1];
                NSString *surface = node.surface;

                if ([gokanStr length]) {
                    if ([surface isEqualToString:@"でも"] &&
                        [[node partOfSpeechSubtype1] isEqualToString:@"副助詞"]) // 【注意】ここは絶対に「副助詞」
                    {
                        Node *newNode = [[Node alloc] init];
                        NSMutableArray *features = [[NSMutableArray alloc] initWithObjects:@"", @"", @"", @"", @"", @"", @"", @"", @"", nil];
                        
                        newNode.features = features;
                        [features release];
                        
                        // 「でも」→「で」
                        [node setSurface:@"で"];
                        [node setPronunciation:@"デ"];
                        [node setOriginalForm:@"だ"];
                        [node setPartOfSpeech:@"助動詞"];
                        [node setPartOfSpeechSubtype1:@""];
                        [node setUseOfType:@"連用形"];
                        [node setInflection:@"™断定"];
                        [_nodes replaceObjectAtIndex:index withObject:node];
                        
                        [newNode setSurface:@"も"];
                        [newNode setPronunciation:@"モ"];
                        [newNode setOriginalForm:@"も"];
                        [newNode setPartOfSpeech:@"助詞"];
                        [newNode setPartOfSpeechSubtype1:@"係助詞"];
                        [newNode setInflection:@"™"];
                        newNode.visible = YES;
                        [_nodes insertObject:newNode atIndex:index+1];
                        [newNode release];

                        DEBUG_LOG(@"分割：[%@]->[%@][%@]", surface, node.surface, newNode.surface);
                        goto start;
                    } else
                    {// 語幹（多少の例外がある！！）
                        BOOL inhibitNai = NO;
                        BOOL inhibitRashii = NO;
                        BOOL changeIntoAdverb = NO;
                        NSString *pronunciation = [node pronunciation];
                        NSString *originalForm = [node originalForm];
                        
                        if ([gokanStr isEqualToString:@"ナイ形容詞"] &&
                            [originalForm isEqualToString:@"ない"] == NO)
                        {// ただし、「だらしがない」などは patch_before_merge_GOKAN にて前処理ずみ。
                            inhibitNai = YES;
                            DEBUG_LOG(@"条件を満たさない「ナイ形容詞」はマージしない。[%@] -> [%@]", lastNode.surface, node.surface);
                        } else if ([[lastNode partOfSpeech] isEqualToString:@"名詞"] &&
                                   [lastSubType1 isEqualToString:@"形容動詞語幹"])
                        {
                            if ([originalForm isEqualToString:@"らしい"]) {
                                inhibitRashii = YES;
                                DEBUG_LOG(@"形容動詞語幹に連なる「らしい」はマージしない。[%@] -> [%@]", lastNode.surface, node.surface);
                            } else if ([pronunciation isEqualToString:@"ニ"])
                            {// 形容動詞語幹に「に」が連なると副詞になる。
                                changeIntoAdverb = YES;
                            }
                        }
                        // 【例外1】ナイ形容詞
                        // 【例外2】形容動詞語幹に連なる「らしい」
                        if (inhibitNai == NO && inhibitRashii == NO) {
                            lastNode.visible = NO;
                            
                            // マージする。
                            _modified = YES;
#if LOG_PATCH
                            DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, lastNode.surface, [lastNode partOfSpeech], node.surface, [node partOfSpeech]);
#endif
                            [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                            [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:pronunciation]];
                            [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                            if ([gokanStr isEqualToString:@"ナイ形容詞"]) {
                                [node setPartOfSpeech:@"形容詞"];
                                [node setPartOfSpeechSubtype1:@"自立"];
                                [node setInflection:@"™形容詞・アウオ段"];
                            } else {
                                [node setPartOfSpeech:gokanStr];
                                [node setInflection:[@"™" stringByAppendingString:[node inflection]]];
                            }
                            if (changeIntoAdverb) {
                                [node setPartOfSpeech:@"副詞"];
                                [node setPartOfSpeechSubtype1:@"助詞副詞化"];
                            }
                            // ゴミ処理
                            if ([[node partOfSpeech] isEqualToString:@"形容動詞"] &&
                                [[node partOfSpeechSubtype1] isEqualToString:@"格助詞"])
                            {
                                [node setPartOfSpeechSubtype1:@""];
                            }
                        } else if (inhibitRashii) {
                            [lastNode setPartOfSpeech:@"形容動詞"];
                            [lastNode setOriginalForm:[[lastNode originalForm] stringByAppendingString:@"だ"]];
                        }
                    }
                }
            }
        }
        lastNode = node;
    }
}

// 名詞の連結
// 【注意】語幹の連結後に実行すること！！
- (void) patch_merge_MEISHI {
    Node *lastNode = nil;
    
    for (Node *node in _nodes) {
        if (node.visible == NO) {
            continue;
        }
        if (lastNode) {
            if ([[node partOfSpeech] isEqualToString:@"名詞"])
            {
                BOOL merge = NO;
                BOOL retainLastSubtype = NO;

                if ([[lastNode partOfSpeech] isEqualToString:@"名詞"])
                {// 名詞に連なっている。
                    if ([[node partOfSpeechSubtype1] isEqualToString:@"接尾"])
                    {// 接尾辞である。
                        merge = YES;
                        retainLastSubtype = YES;
                    } else if ([[node partOfSpeechSubtype1] isEqualToString:@"一般"])
                    {// 一般名詞が連なっている。
                        merge = YES;
                        retainLastSubtype = YES;
                    }
                } else if ([[lastNode partOfSpeech] isEqualToString:@"接頭詞"] &&
                           [[lastNode partOfSpeechSubtype1] isEqualToString:@"名詞接続"])
                {// 接頭詞・名詞接続に連なった一般名詞である。
                    if ([[node partOfSpeechSubtype1] isEqualToString:@"一般"])
                    {// 直前が名詞接続の接頭詞である。
                        merge = YES;
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
                        [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                    }
                    @catch (NSException *exception) {
                        [node setPronunciation:@"?"];
                    }
                    [node setOriginalForm:[[lastNode originalForm]       stringByAppendingString:[node originalForm]]];
                    
                    if (retainLastSubtype) {
                        [node setPartOfSpeechSubtype1:[lastNode partOfSpeechSubtype1]];
                    }
//                    [node setPartOfSpeechSubtype2:[lastNode partOfSpeechSubtype2]]; // 元の属性を保全する。
//                    [node setPartOfSpeechSubtype3:[lastNode partOfSpeechSubtype3]]; // 元の属性を保全する。
                }
            }
        }
        lastNode = node;
    }
}

#pragma mark - Patch (パッチ)

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

        if (lastNode && [self isTaigen:[lastNode partOfSpeech]] &&
            nextNode && [nextNode.surface isEqualToString:@"、"])
        {
            if ([[node partOfSpeech] isEqualToString:@"助詞"] &&
                [node.surface isEqualToString:@"で"])
            {
                [node setPartOfSpeech:@"助動詞"];
                [node setPartOfSpeechSubtype1:@""];
                [node setPartOfSpeechSubtype2:@""];
                [node setOriginalForm:@"だ"];
                [node setUseOfType:@"連用形"];
                [node setInflection:[@"™" stringByAppendingString:@"断定"]];

                // 修正された。
                _modified = YES;
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
- (void) patch_NANODA_NO {
    
    for (Node *node in _nodes) {
        if (node.visible == NO) {
            continue;
        }
        if ([node.surface isEqualToString:@"の"] &&
            [[node partOfSpeech] isEqualToString:@"名詞"])
        {
            if ([[node partOfSpeechSubtype1] isEqualToString:@"非自立"])
            {// 準体助詞である。
                [node setPartOfSpeech:@"助詞"];
                [node setPartOfSpeechSubtype1:@"準体助詞"];
                [node setPartOfSpeechSubtype2:@""];

                // 修正された。
                _modified = YES;
#if LOG_PATCH
                DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
#endif
            }
        }
    }
}

// 【感動詞】「そう」がいつも副詞ではおかしい。
- (void) patch_KANDOSHI_SOU {
    
    if ([_nodes count] == 1) {
        Node *node = _nodes[0];
        if (node.visible) {
            if ([node.surface isEqualToString:@"そう"] &&
                [[node partOfSpeech] isEqualToString:@"副詞"] &&
                [[node partOfSpeechSubtype1] isEqualToString:@"助詞類接続"])
            {
                [node setPartOfSpeech:@"感動詞"];
                [node setPartOfSpeechSubtype1:@""];
                [node setPartOfSpeechSubtype2:@""];

                // 修正された。
                _modified = YES;
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
            if ([node.surface isEqualToString:@"そう"] &&
                [[node partOfSpeech] isEqualToString:@"副詞"] &&
                [[node partOfSpeechSubtype1] isEqualToString:@"助詞類接続"])
            {// 副詞である。
                if (i < [_nodes count] - 1) {
                    Node *nextNode = [self nextNode:i];
                    
                    if ([self isYougen:[nextNode partOfSpeech]] == NO) {
                        [node setPartOfSpeech:@"感動詞"];
                        [node setPartOfSpeechSubtype1:@""];
                        [node setPartOfSpeechSubtype2:@""];

                        // 修正された。
                        _modified = YES;
#if LOG_PATCH
                        DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
#endif
                    }
                } else {
                    [node setPartOfSpeech:@"感動詞"];
                    [node setPartOfSpeechSubtype1:@""];
                    [node setPartOfSpeechSubtype2:@""];

                    // 修正された。
                    _modified = YES;
#if LOG_PATCH
                    DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
#endif
                }
            }
        }
    }
}

// 【補助形容詞化】事前のトークンが連用形の形容詞／形容動詞の場合の「ない」は補助形容詞。
//
// ※動詞／形容詞／形容動詞に導かれる、補助形容詞「ほしい」「ない」の現状は下記。
// ○動詞+てほしい eg.「きてほしい」
// -形容詞+ほしい
// -形容動詞+ほしい
// ○動詞+ない（助動詞） eg.「こない」
// ×形容詞+ない eg.「かわいくない」
// ×形容動詞+ない eg.「きれいでない」
//
- (void) patch_HOJO_KEIYOUSHI_NAI {
    Node *lastNode = nil;
    
    for (Node *node in _nodes) {
        if (node.visible == NO) {
            continue;
        }
        if (lastNode) {
            if ([[node partOfSpeech] isEqualToString:@"助動詞"] &&
                [[node originalForm] isEqualToString:@"ない"])
            {
                NSString *lastPartOfSpeech = [lastNode partOfSpeech];
                NSString *lastUseOfType = [lastNode useOfType];
                
                if (([lastPartOfSpeech isEqualToString:@"形容詞"] || [lastPartOfSpeech isEqualToString:@"形容動詞"])
                    && [lastUseOfType length] >= 2 && [[lastUseOfType substringToIndex:2] isEqualToString:@"連用"]
                    ) // 連用形の形容詞／形容動詞に連なる場合は補助形容詞。
                {// 形容詞／形容動詞＋補助形容詞（ない）
                    [node setPartOfSpeech:@"形容詞"];
                    [node setPartOfSpeechSubtype1:@"補助形容詞"];
                    [node setInflection:@"™形容詞／形容動詞の補助動詞「ない」"];

                    // 修正された。
                    _modified = YES;
#if LOG_PATCH
                    DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
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
        if (lastNode && [self isTaigen:[lastNode partOfSpeech]])
        {
            if ([[node partOfSpeech] isEqualToString:@"助動詞"] &&
                [[node originalForm] isEqualToString:@"らしい"] &&
                [[[node inflection] substringToIndex:3] isEqualToString:@"形容詞"])
            {
                Node *nextNode = [self nextNode:i];
                BOOL rentai = [node.surface isEqualToString:@"らしい"] && [self isTaigen:[nextNode partOfSpeech]];
                BOOL renyou = [node.surface isEqualToString:@"らしく"] && [self isYougen:[nextNode partOfSpeech]];

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
                    } else if (renyou) {
                        [node setUseOfType:@"連用形"];
                    }
                    [node setInflection:[@"™" stringByAppendingString:[node inflection]]];
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
            if ([self isEndOfSentence:i + 1]) {
                [node setPartOfSpeechSubtype1:@"終助詞"];
                [node setInflection:@"™強調"];

                // 修正された。
                _modified = YES;
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
                [node setInflection:[@"™" stringByAppendingString:@"強調"]];
                [node setInflection:[@"™" stringByAppendingString:[node inflection]]];
            }
        }
        lastNode = node;
    }
}

// 【接続助詞化】動詞が五段活用時の「呼んでも」の「で・も」→接続助詞「でも」
- (void) patch_DE_MO {
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

        if (lastNode && [[lastNode inflection] length] >= 2 && [[[lastNode inflection] substringToIndex:2] isEqualToString:@"五段"] &&
            [node.surface isEqualToString:@"で"] && [[node partOfSpeechSubtype1] isEqualToString:@"接続助詞"] &&
            nextNode && [nextNode.surface isEqualToString:@"も"] && [[nextNode partOfSpeechSubtype1] isEqualToString:@"係助詞"] &&
            [self isYougen:[nextNextNode partOfSpeech]] == NO)
        {
            nextNode.visible = NO;
            
            // マージする。
            _modified = YES;
#if LOG_PATCH
            DEBUG_LOG(@"%s 「%@」(%@)+「%@」(%@)", __func__, node.surface, [node partOfSpeech], nextNode.surface, [nextNode partOfSpeech]);
#endif
            [node setSurface:[[node surface]             stringByAppendingString:[nextNode surface]]];
            [node setPronunciation:[[node pronunciation] stringByAppendingString:[nextNode pronunciation]]];
            [node setOriginalForm:[[node originalForm]   stringByAppendingString:[nextNode originalForm]]];
            
            [node setPartOfSpeechSubtype1:@"接続助詞"];
            [node setPartOfSpeechSubtype2:@""];
            [node setOriginalForm:@"ても"];
            [node setInflection:[@"™" stringByAppendingString:[node inflection]]];
        }
        lastNode = node;
    }
}

// 【副助詞の分割】「こちらでも、」の副助詞「でも」→格助詞「で」と副助詞「も」
- (void) patch_DEMO {
    Node *lastNode = nil;
    
    for (NSUInteger index = 0; index < [_nodes count]; index++) {
        Node *node = _nodes[index];
        if (node.visible == NO) {
            continue;
        }
        if (lastNode) {
            if (index < [_nodes count] - 1) {
                Node *nextNode = [self nextNode:index];
                
                if ([[lastNode partOfSpeech] isEqualToString:@"名詞"] &&
                    [node.surface isEqualToString:@"でも"] && [[node partOfSpeechSubtype1] isEqualToString:@"副助詞"] && // 【注意】ここは絶対に「副助詞」
                    [nextNode.surface isEqualToString:@"、"])
                {
                    Node *newNode = [[Node alloc] init];
                    NSMutableArray *features = [[NSMutableArray alloc] initWithObjects:@"", @"", @"", @"", @"", @"", @"", @"", @"", nil];
                    
                    newNode.features = features;
                    [features release];
                    
                    // 「でも」→「で」「も」
                    [node setSurface:@"で"];
                    [node setPronunciation:@"デ"];
                    [node setOriginalForm:@"で"];
                    [node setPartOfSpeech:@"助詞"];
                    [node setPartOfSpeechSubtype1:@"格助詞"];
                    [_nodes replaceObjectAtIndex:index withObject:node];
                    
                    [newNode setSurface:@"も"];
                    [newNode setPronunciation:@"モ"];
                    [newNode setOriginalForm:@"も"];
                    [newNode setPartOfSpeech:@"助詞"];
                    [newNode setPartOfSpeechSubtype1:@"係助詞"];
                    [newNode setInflection:@"™"];
                    newNode.visible = YES;
                    [_nodes insertObject:newNode atIndex:index+1];
                    [newNode release];

                    // 修正された。
                    _modified = YES;
#if LOG_PATCH
                    DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
#endif
                }
            }
        }
        lastNode = node;
    }
}

// 【副助詞化】「子供でも」の「でも」＋動詞→副助詞「でも」
- (BOOL) patch_DATTE {
    Node *lastNode = nil;
    Node *nextNode = nil;
    BOOL asked = NO;
    
    for (NSInteger i = 0; i < [_nodes count]; i++) {
        Node *node = _nodes[i];
        if (node.visible == NO) {
            continue;
        }
        nextNode = [self nextNode:i];
        if (lastNode && [lastNode.surface isEqualToString:@"で"] && [[lastNode partOfSpeechSubtype1] isEqualToString:@"格助詞"] &&
            node && [node.surface isEqualToString:@"も"] && [[node partOfSpeechSubtype1] isEqualToString:@"係助詞"] &&
            nextNode && [[nextNode partOfSpeech] isEqualToString:@"動詞"])
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
            
            [node setPartOfSpeechSubtype1:@"係助詞"];
            [node setPartOfSpeechSubtype2:@""];
            [node setOriginalForm:@"でも"];
            [node setInflection:[@"™" stringByAppendingString:[node inflection]]];
        }
        lastNode = node;
    }
    return asked;
}

#pragma mark - Patch (単なる用語の置換)
// 【終止形／連体形／連用形】
- (void) postProcess {
    
    for (Node *node in _nodes) {
        if (node.visible == NO) {
            continue;
        }
        NSString *useOfType = [node useOfType];
        NSString *partOfSpeechSubtype1 = [node partOfSpeechSubtype1];
        NSString *inflection = [node inflection];
        
        // 【名詞（XXX語幹）】partOfSpeech
        if ([[node partOfSpeech] isEqualToString:@"名詞"]) {
            if ([self gokanString:node])
            {// 語幹であると見なされたが未だ名詞であるダメな奴。
                NSString *pronunciation = [node pronunciation];

                if ([pronunciation isEqualToString:@"ヨー"]) {
                    [node setPartOfSpeech:@"助詞"];
                    [node setPartOfSpeechSubtype1:@"終助詞"];
                    [node setPartOfSpeechSubtype2:@""];
                } else {
                    DEBUG_LOG(@"!!!対処が必要か？：「%@」（%@）", node.surface, pronunciation);
                }
            }
        }
        // 【補助動詞】partOfSpeech
        if ([[node partOfSpeech] isEqualToString:@"動詞"])
        {
            if ([partOfSpeechSubtype1 isEqualToString:@"自立"])
            {// 本動詞である。
                [node setPartOfSpeechSubtype1:@"本動詞"];
            }
            if ([partOfSpeechSubtype1 isEqualToString:@"非自立"])
            {// 補助動詞である。
                [node setPartOfSpeechSubtype1:@"補助動詞"];
            }
        }
        // 【係助詞→副助詞】partOfSpeechSubtype1
        if ([partOfSpeechSubtype1 isEqualToString:@"係助詞"])
        {
            [node setPartOfSpeechSubtype1:@"副助詞"];
        }
        // 【終止形／連体形／連用形】useOfType
        if ([useOfType isEqualToString:@"基本形"])
        {
            [node setUseOfType:@"終止形"];
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

#pragma mark - Patch (未使用)

// 未使用
// 【副詞】用言に連なる「そう」は全て副詞だが、mecab は名詞を返す。
- (void) patch_OLD_FUKUSHI_SO {
    Node *lastNode = nil;
    
    for (Node *node in _nodes) {
        if (node.visible == NO) {
            continue;
        }
        if (lastNode) {
            if ([self isYougen:[lastNode partOfSpeech]] &&
                [node.surface isEqualToString:@"そう"])
            {// 用言に連なる「そう」は全て副詞。
                [node setPartOfSpeech:@"副詞"];
                [node setPartOfSpeechSubtype1:@""];
                [node setPartOfSpeechSubtype2:@""];
                [node setPartOfSpeechSubtype3:@""];
            }
        }
        lastNode = node;
    }
}

// 未使用
// 【伝聞、様相の助動詞】伝聞、様相の「そうです」は助動詞だが、mecab は名詞+助動詞を返す。
- (void) patch_OLD_SOU {
    Node *lastNode = nil;
    
    for (Node *node in _nodes) {
        if (node.visible == NO) {
            continue;
        }
        if (lastNode) {
            if ([[node partOfSpeech] isEqualToString:@"助動詞"])
            {
                NSString *pronunciation = [node pronunciation];

                if ([[lastNode partOfSpeech] isEqualToString:@"名詞"] &&
                    [lastNode.surface isEqualToString:@"そう"])
                {// 伝聞の「そうです」は助動詞
                    lastNode.visible = NO;
                    
                    // マージする。
                    _modified = YES;
                    [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                    [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:pronunciation]];
                    [node setOriginalForm:@"そうだ"];
                    [node setInflection:@"™伝聞"];
                }
                if ([[lastNode partOfSpeech] isEqualToString:@"副詞"] &&
                    [lastNode.surface isEqualToString:@"そう"])
                {// 様相の「そうです」は助動詞
                    lastNode.visible = NO;
                    
                    // マージする。
                    _modified = YES;
                    [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                    [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:pronunciation]];
                    [node setOriginalForm:@"そうだ"];
                    [node setInflection:@"™様相"];
                }
            }
        }
        lastNode = node;
    }
}

// 未使用
// 【副詞化】形容動詞＋助詞（に）で副詞化はすべきだが、mecab は名詞+助動詞を返す。
- (void) patch_OLD_FUKUSHI_KA {
    Node *lastNode = nil;
    
    for (Node *node in _nodes) {
        if (node.visible == NO) {
            continue;
        }
        if (lastNode) {
            if ([[node partOfSpeech] isEqualToString:@"助詞"])
            {
                if ([[lastNode partOfSpeech] isEqualToString:@"名詞"] &&
                    [[lastNode partOfSpeechSubtype1] isEqualToString:@"形容動詞語幹"])
                {// 形容動詞＋助詞（に）は形容動詞
                    BOOL isRenyou = [node.surface isEqualToString:@"に"];
                    lastNode.visible = NO;
                    
                    // マージする。
                    _modified = YES;
                    [node setSurface:[[lastNode surface] stringByAppendingString:[node surface]]];
                    [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                    [node setOriginalForm:[[lastNode originalForm] stringByAppendingString:@"だ"]];
                    //                    [node setInflection:@"™伝聞"];
                    [node setPartOfSpeech:@"形容動詞"];
                    if (isRenyou) {
                        [node setUseOfType:@"連用形"];
                    }
                }
            }
        }
        lastNode = node;
    }
}
@end
