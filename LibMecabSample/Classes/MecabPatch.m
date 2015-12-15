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

// 【注意】必須の処理
- (void) preProcess {
    NSUInteger count = 0;
    for (Node *node in _nodes) {
        NSString *subType1 = [node partOfSpeechSubtype1];
        NSString *subType2 = [node partOfSpeechSubtype2];
        NSString *subType3 = [node partOfSpeechSubtype3];
        NSString *baseToken = @"語幹";
        NSUInteger baseTokenLength = [baseToken length];
        
        if (([subType1 length] > baseTokenLength && [[subType1 substringFromIndex:[subType1 length] - baseTokenLength] isEqualToString:baseToken]) ||
            ([subType2 length] > baseTokenLength && [[subType2 substringFromIndex:[subType2 length] - baseTokenLength] isEqualToString:baseToken]) ||
            ([subType3 length] > baseTokenLength && [[subType3 substringFromIndex:[subType3 length] - baseTokenLength] isEqualToString:baseToken])) {
            DEBUG_LOG(@">>[%02lu]%@:%@", (unsigned long)++count, node.surface, [node partOfSpeech]);
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

#pragma mark - Patch (マージ)

// 複合動詞の連結
- (void) patch_merge_FUKUGO_DOSHI {
    Node *lastNode = nil;
    
    for (NSUInteger index = 0; index < [_nodes count]; index++) {
        Node *node = _nodes[index];
        
        if ([[lastNode partOfSpeech] isEqualToString:@"動詞"]) {
            if ([[node partOfSpeech] isEqualToString:@"動詞"] && [[node partOfSpeechSubtype1] isEqualToString:@"非自立"])
            {//
                lastNode.visible = NO;
                
                // マージする。
                [node setPartOfSpeechSubtype1:@"複合動詞"];
                
                [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                [node setInflection:[NSString stringWithFormat:@"%@%@&%@", @"™" , [lastNode inflection], [node inflection]]];
                DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
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
                    [node setPartOfSpeechSubtype1:@"複合動詞"];
                    
                    [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                    [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                    [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                    [node setInflection:[NSString stringWithFormat:@"%@%@", @"™" , [node inflection]]];
                    DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
                }
            }
        }
        lastNode = node;
    }
}

// 名詞の連結
- (void) patch_merge_MEISHI {
    Node *lastNode = nil;
    
    for (Node *node in _nodes) {
        if (lastNode) {
            if ([[node partOfSpeech] isEqualToString:@"名詞"])
            {
                BOOL merge = NO;
                BOOL retainLastSubtype = NO;
                
                if ([[lastNode partOfSpeech] isEqualToString:@"名詞"])
                {// 名詞が連なっている。
                    if ([[node partOfSpeechSubtype1] isEqualToString:@"接尾"])
                    {// 接尾辞である。
                        merge = YES;
                        retainLastSubtype = YES;
                    }
                } else if ([[node partOfSpeechSubtype1] isEqualToString:@"一般"])
                {// 一般名詞である。
                    if ([[lastNode partOfSpeech] isEqualToString:@"接頭詞"] &&
                        [[lastNode partOfSpeechSubtype1] isEqualToString:@"名詞接続"])
                    {// 直前が名詞接続の接頭詞である。
                        merge = YES;
                    }
                }
                if (merge) {
                    lastNode.visible = NO;
                    
                    // マージする。
                    [node setSurface:[[lastNode surface]                 stringByAppendingString:[node surface]]];
                    @try {
                        [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                    }
                    @catch (NSException *exception) {
                        [node setPronunciation:@"例外!!"];
                    }
                    [node setOriginalForm:[[lastNode originalForm]       stringByAppendingString:[node originalForm]]];
                    
                    if (retainLastSubtype) {
                        [node setPartOfSpeechSubtype1:[lastNode partOfSpeechSubtype1]];
                    }
                    //                    [node setPartOfSpeechSubtype2:[lastNode partOfSpeechSubtype2]]; // 元の属性を保全する。
                    //                    [node setPartOfSpeechSubtype3:[lastNode partOfSpeechSubtype3]]; // 元の属性を保全する。
                    DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
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
    start:
        if (lastNode) {
            if ([self isFuzokugo:[node partOfSpeech]])
            {// 付属語（助詞、助動詞）
                NSString *lastSubType1 = [lastNode partOfSpeechSubtype1];
                NSString *lastSubType2 = [lastNode partOfSpeechSubtype2];
                NSString *lastSubType3 = [lastNode partOfSpeechSubtype3];
                NSString *baseToken = @"語幹";
                NSString *jointKey = nil;
                NSUInteger baseTokenLength = [baseToken length];
                
                if ([lastSubType1 length] > baseTokenLength &&
                    [[lastSubType1 substringFromIndex:[lastSubType1 length] - baseTokenLength] isEqualToString:baseToken])
                {
                    jointKey = [lastSubType1 substringToIndex:[lastSubType1 length] - baseTokenLength];
                } else if ([lastSubType2 length] > baseTokenLength &&
                           [[lastSubType2 substringFromIndex:[lastSubType2 length] - baseTokenLength] isEqualToString:baseToken])
                {
                    jointKey = [lastSubType2 substringToIndex:[lastSubType2 length] - baseTokenLength];
                } else if ([lastSubType3 length] > baseTokenLength &&
                           [[lastSubType3 substringFromIndex:[lastSubType3 length] - baseTokenLength] isEqualToString:baseToken])
                {
                    jointKey = [lastSubType3 substringToIndex:[lastSubType3 length] - baseTokenLength];
                }
                if ([jointKey length]) {
                    if ([node.surface isEqualToString:@"でも"] &&
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
                        goto start;
                    } else
                    {// 語幹（多少の例外がある！！）
                        BOOL inhibitNai = NO;
                        BOOL inhibitRashii = NO;
                        
                        if ([jointKey isEqualToString:@"ナイ形容詞"] &&
                            [[node pronunciation] isEqualToString:@"ナイ"] == NO)
                        {
                            inhibitNai = YES;
                            DEBUG_LOG(@"条件を満たさない「ナイ形容詞」はマージしない。[%@] -> [%@]", lastNode.surface, node.surface);
                        } else if ([[lastNode partOfSpeech] isEqualToString:@"名詞"] &&
                                   [lastSubType1 isEqualToString:@"形容動詞語幹"] &&
                                   [[node pronunciation] isEqualToString:@"ラシイ"])
                        {
                            inhibitRashii = YES;
                            DEBUG_LOG(@"形容動詞語幹に連なる「らしい」はマージしない。[%@] -> [%@]", lastNode.surface, node.surface);
                        }
                        
                        // 【例外1】ナイ形容詞
                        // 【例外2】形容動詞語幹に連なる「らしい」
                        if (inhibitNai == NO && inhibitRashii == NO) {
                            lastNode.visible = NO;
                            
                            // マージする。
                            [node setPartOfSpeech:jointKey];
                            
                            [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                            [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                            [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                            [node setInflection:[@"™" stringByAppendingString:[node inflection]]];
                            DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
                            
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

#pragma mark - Patch (パッチ)

// 【助動詞化】体言＋助詞「で、」→助動詞「だ」（連用形）
// ※後端の「、」が必須
- (void) patch_TAIGEN_DA {
    Node *lastNode = nil;
    Node *nextNode = nil;
    
    for (NSInteger i = 0; i < [_nodes count]; i++) {
        Node *node = _nodes[i];
        
        if (i + 1 < [_nodes count]) {
            nextNode = _nodes[i + 1];
        } else {
            nextNode = nil;
        }
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
                DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
            }
        }
        lastNode = node;
    }
}

// 【準体助詞】「なのだ」の「の」が名詞ではおかしい。
- (void) patch_NANODA_NO {
    
    for (Node *node in _nodes) {
        if ([node.surface isEqualToString:@"の"] &&
            [[node partOfSpeech] isEqualToString:@"名詞"])
        {
            if ([[node partOfSpeechSubtype1] isEqualToString:@"非自立"])
            {// 準体助詞である。
                [node setPartOfSpeech:@"助詞"];
                [node setPartOfSpeechSubtype1:@"準体助詞"];
                [node setPartOfSpeechSubtype2:@""];
                DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
            }
        }
    }
}

// 【感動詞】「そう」がいつも副詞ではおかしい。
- (void) patch_KANDOSHI_SOU {
    
    if ([_nodes count] == 1) {
        Node *node = _nodes[0];
        
        if ([node.surface isEqualToString:@"そう"] &&
            [[node partOfSpeech] isEqualToString:@"副詞"] &&
            [[node partOfSpeechSubtype1] isEqualToString:@"助詞類接続"])
        {
            [node setPartOfSpeech:@"感動詞"];
            [node setPartOfSpeechSubtype1:@""];
            [node setPartOfSpeechSubtype2:@""];
            DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
        }
    } else if ([_nodes count] > 1) {
        for (NSUInteger i = 0; i < [_nodes count]; i++) {
            Node *node = _nodes[i];
            
            if ([node.surface isEqualToString:@"そう"] &&
                [[node partOfSpeech] isEqualToString:@"副詞"] &&
                [[node partOfSpeechSubtype1] isEqualToString:@"助詞類接続"])
            {// 副詞である。
                if (i < [_nodes count] - 1) {
                    Node *nextNode = _nodes[i+1];
                    
                    if ([self isYougen:[nextNode partOfSpeech]] == NO) {
                        [node setPartOfSpeech:@"感動詞"];
                        [node setPartOfSpeechSubtype1:@""];
                        [node setPartOfSpeechSubtype2:@""];
                        DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
                    }
                } else {
                    [node setPartOfSpeech:@"感動詞"];
                    [node setPartOfSpeechSubtype1:@""];
                    [node setPartOfSpeechSubtype2:@""];
                    DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
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
        if (lastNode) {
            if ([[node partOfSpeech] isEqualToString:@"助動詞"] &&
                [node.surface isEqualToString:@"ない"])
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
                    DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
                }
            }
        }
        lastNode = node;
    }
}

// 【形容詞化】体言＋助動詞「らしい」＋体言→形容詞（連体形）
// eg.「人間らしい」
- (void) patch_TAIGEN_RASHII {
    Node *lastNode = nil;
    Node *nextNode = nil;
    
    for (NSInteger i = 0; i < [_nodes count]; i++) {
        Node *node = _nodes[i];
        
        if (i + 1 < [_nodes count]) {
            nextNode = _nodes[i + 1];
        } else {
            nextNode = nil;
        }
        if (lastNode && [self isTaigen:[lastNode partOfSpeech]] &&
            nextNode && [self isTaigen:[nextNode partOfSpeech]])
        {
            if ([[node partOfSpeech] isEqualToString:@"助動詞"] &&
                [node.surface isEqualToString:@"らしい"] &&
                [[[node inflection] substringToIndex:3] isEqualToString:@"形容詞"])
            {
                lastNode.visible = NO;
                
                // マージする。
                [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                
                [node setPartOfSpeech:@"形容詞"];
                [node setPartOfSpeechSubtype1:@""];
                [node setPartOfSpeechSubtype2:@""];
                [node setUseOfType:@"連体形"];
                [node setInflection:[@"™" stringByAppendingString:[node inflection]]];
                DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
            }
        }
        lastNode = node;
    }
}

// 【終助詞化】末端の接続助詞「とも」は強調を示す終助詞。
- (void) patch_TOMO {
    
    for (NSUInteger i = 0; i < [_nodes count]; i++) {
        Node *node = _nodes[i];
        
        if ([[node partOfSpeechSubtype1] isEqualToString:@"接続助詞"] &&
            [node.surface isEqualToString:@"とも"])
        {
            if ([self isEndOfSentence:i + 1]) {
                [node setPartOfSpeechSubtype1:@"終助詞"];
                [node setInflection:@"™強調"];
                DEBUG_LOG(@"%s %@:%@", __func__, node.surface, [node partOfSpeech]);
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
        
        if (i + 1 < [_nodes count]) {
            nextNode = _nodes[i + 1];
        } else {
            nextNode = nil;
        }
        if (lastNode && [lastNode.surface isEqualToString:@"と"] && [[lastNode partOfSpeechSubtype1] isEqualToString:@"格助詞"] &&
            nextNode && [nextNode.surface isEqualToString:@"。"])
        {
            if ([node.surface isEqualToString:@"も"] && [[node partOfSpeechSubtype1] isEqualToString:@"係助詞"])
            {
                lastNode.visible = NO;
                
                // マージする。
                [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                
                [node setPartOfSpeechSubtype1:@"終助詞"];
                [node setPartOfSpeechSubtype2:@""];
                [node setInflection:[@"™" stringByAppendingString:@"強調"]];
                [node setInflection:[@"™" stringByAppendingString:[node inflection]]];
                DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
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
        
        if (i + 1 < [_nodes count]) {
            nextNode = _nodes[i + 1];
        } else {
            nextNode = nil;
        }
        if (i + 2 < [_nodes count]) {
            nextNextNode = _nodes[i + 2];
        } else {
            nextNextNode = nil;
        }
        if (lastNode && [[lastNode inflection] length] >= 2 && [[[lastNode inflection] substringToIndex:2] isEqualToString:@"五段"] &&
            [node.surface isEqualToString:@"で"] && [[node partOfSpeechSubtype1] isEqualToString:@"接続助詞"] &&
            nextNode && [nextNode.surface isEqualToString:@"も"] && [[nextNode partOfSpeechSubtype1] isEqualToString:@"係助詞"] &&
            [self isYougen:[nextNextNode partOfSpeech]] == NO)
        {
            nextNode.visible = NO;
            
            // マージする。
            [node setSurface:[[node surface]             stringByAppendingString:[nextNode surface]]];
            [node setPronunciation:[[node pronunciation] stringByAppendingString:[nextNode pronunciation]]];
            [node setOriginalForm:[[node originalForm]   stringByAppendingString:[nextNode originalForm]]];
            
            [node setPartOfSpeechSubtype1:@"接続助詞"];
            [node setPartOfSpeechSubtype2:@""];
            [node setOriginalForm:@"ても"];
            [node setInflection:[@"™" stringByAppendingString:[node inflection]]];
            DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
        }
        lastNode = node;
    }
}

// 【副助詞の分割】「こちらでも、」の副助詞「でも」→格助詞「で」と副助詞「も」
- (void) patch_DEMO {
    Node *lastNode = nil;
    
    for (NSUInteger index = 0; index < [_nodes count]; index++) {
        Node *node = _nodes[index];
        
        if (lastNode) {
            if (index < [_nodes count] - 1) {
                Node *nextNode = _nodes[index + 1];
                
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
                    DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
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
        
        if (i + 1 < [_nodes count]) {
            nextNode = _nodes[i + 1];
        } else {
            nextNode = nil;
        }
        if (lastNode && [lastNode.surface isEqualToString:@"で"] && [[lastNode partOfSpeechSubtype1] isEqualToString:@"格助詞"] &&
            node && [node.surface isEqualToString:@"も"] && [[node partOfSpeechSubtype1] isEqualToString:@"係助詞"] &&
            nextNode && [[nextNode partOfSpeech] isEqualToString:@"動詞"])
        {
            lastNode.visible = NO;
            
            // マージする。
            [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
            [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
            [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
            
            [node setPartOfSpeechSubtype1:@"係助詞"];
            [node setPartOfSpeechSubtype2:@""];
            [node setOriginalForm:@"でも"];
            [node setInflection:[@"™" stringByAppendingString:[node inflection]]];
            DEBUG_LOG(@"%s %@:%@", __func__, lastNode.surface, [lastNode partOfSpeech]);
        }
        lastNode = node;
    }
    return asked;
}

#pragma mark - Patch (単なる用語の置換)
// 【終止形／連体形／連用形】
- (void) patch_YOUGO {
    
    for (Node *node in _nodes) {
        NSString *useOfType = [node useOfType];
        NSString *partOfSpeechSubtype1 = [node partOfSpeechSubtype1];
        NSString *inflection = [node inflection];
        
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
        if (lastNode) {
            if ([[node partOfSpeech] isEqualToString:@"助動詞"])
            {
                if ([[lastNode partOfSpeech] isEqualToString:@"名詞"] &&
                    [lastNode.surface isEqualToString:@"そう"])
                {// 伝聞の「そうです」は助動詞
                    lastNode.visible = NO;
                    
                    // マージする。
                    [node setSurface:[[lastNode surface] stringByAppendingString:[node surface]]];
                    [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                    [node setOriginalForm:@"そうだ"];
                    [node setInflection:@"™伝聞"];
                }
                if ([[lastNode partOfSpeech] isEqualToString:@"副詞"] &&
                    [lastNode.surface isEqualToString:@"そう"])
                {// 様相の「そうです」は助動詞
                    lastNode.visible = NO;
                    
                    // マージする。
                    [node setSurface:[[lastNode surface] stringByAppendingString:[node surface]]];
                    [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
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
        if (lastNode) {
            if ([[node partOfSpeech] isEqualToString:@"助詞"])
            {
                if ([[lastNode partOfSpeech] isEqualToString:@"名詞"] &&
                    [[lastNode partOfSpeechSubtype1] isEqualToString:@"形容動詞語幹"])
                {// 形容動詞＋助詞（に）は形容動詞
                    BOOL isRenyou = [node.surface isEqualToString:@"に"];
                    lastNode.visible = NO;
                    
                    // マージする。
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
