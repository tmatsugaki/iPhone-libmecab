//
//  LibMecabSampleViewController.m
//  LibMecabSample
//
//  Created by Watanabe Toshinori on 10/12/27.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#import "LibMecabSampleViewController.h"
#import "TokensViewController.h"
#import "Mecab.h"
#import "Node.h"

@implementation LibMecabSampleViewController

NSSet *upperSet = nil;
NSSet *lowerSet = nil;

@synthesize textField;
@synthesize tableView_;
@synthesize nodeCell;
@synthesize explore;
@synthesize patch;
@synthesize mecab;
@synthesize nodes;
@synthesize tokens;

#pragma mark - Patch

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
    
    if (nextIndex < [nodes count]) {
        Node *node = nodes[nextIndex];
        
        if ([node.surface isEqualToString:@"、"] || [node.surface isEqualToString:@"。"]) {
            rc = YES;
        }
    } else {
        rc = YES;
    }
    return rc;
}

- (NSString *) ichidanString:(NSString *)pronunciation {
    
    NSString *str = @"";
    
    if ([pronunciation length]) {
        NSString *lastChar = [pronunciation substringFromIndex:[pronunciation length] - 1];
        if ([upperSet member:lastChar]) {
            str = @"上一段";
        } else if ([lowerSet member:lastChar]) {
            str = @"下一段";
        }
    }
    return str;
}

- (void) preProcess {
    NSUInteger count = 0;
    for (Node *node in nodes) {
        NSString *subType1 = [node partOfSpeechSubtype1];
        NSString *subType2 = [node partOfSpeechSubtype2];
        NSString *subType3 = [node partOfSpeechSubtype3];
        NSString *baseToken = @"語幹";
        NSUInteger baseTokenLength = [baseToken length];

        if (([subType1 length] > baseTokenLength && [[subType1 substringFromIndex:[subType1 length] - baseTokenLength] isEqualToString:baseToken]) ||
            ([subType2 length] > baseTokenLength && [[subType2 substringFromIndex:[subType2 length] - baseTokenLength] isEqualToString:baseToken]) ||
            ([subType3 length] > baseTokenLength && [[subType3 substringFromIndex:[subType3 length] - baseTokenLength] isEqualToString:baseToken])) {
            NSLog(@">>[%02d]%@:%@", ++count, node.surface, [node partOfSpeech]);
        }
        node.attribute = @"";
        node.visible = YES;
    }
}

// 【名詞のマージ】
- (void) patch_merge_MEISHI {
    NSUInteger count = 0;
    Node *lastNode = nil;
    
    for (Node *node in nodes) {
        if (lastNode) {
            if ([[lastNode partOfSpeech] isEqualToString:@"名詞"] &&
                [[node partOfSpeech] isEqualToString:@"名詞"])
            {// 名詞が連なっている。
                if ([[node partOfSpeechSubtype1] isEqualToString:@"接尾"])
                {// 接尾辞
                    lastNode.visible = NO;

                    // マージする。
                    [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                    @try {
                        [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                    }
                    @catch (NSException *exception) {
                        [node setPronunciation:@"例外!!"];
                    }
                    [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                    
                    [node setPartOfSpeechSubtype1:[lastNode partOfSpeechSubtype1]];
//                    [node setPartOfSpeechSubtype2:[lastNode partOfSpeechSubtype2]]; // 元の属性を保全する。
//                    [node setPartOfSpeechSubtype3:[lastNode partOfSpeechSubtype3]]; // 元の属性を保全する。
                    NSLog(@"<<%@:%@", lastNode.surface, [lastNode partOfSpeech]);
                    count++;
                }
            }
        }
        lastNode = node;
    }
}

// 【助動詞／形容動詞】
- (void) patch_merge_FUZOKUGO {
    NSUInteger count = 0;
    Node *lastNode = nil;
    
    for (NSUInteger index = 0; index < [nodes count]; index++) {
        Node *node = nodes[index];
start:
        if (lastNode) {
            if ([self isFuzokugo:[node partOfSpeech]])
            {// 付属語（助詞、助動詞）
#if 0
                if ([[lastNode partOfSpeechSubtype2] isEqualToString:@"助動詞語幹"])
                {// 助動詞語幹
                    lastNode.visible = NO;
                    
                    // マージする。
                    [node setPartOfSpeech:@"助動詞"];

                    [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                    [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                    [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                    NSLog(@"<<%@:%@", lastNode.surface, [lastNode partOfSpeech]);
                    count++;
                }
                if ([[lastNode partOfSpeechSubtype1] isEqualToString:@"形容動詞語幹"])
                {// 形容動詞語幹
                    lastNode.visible = NO;
                    
                    // マージする。
                    [node setPartOfSpeech:@"形容動詞"];

                    [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                    [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                    [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                    NSLog(@"<<%@:%@", lastNode.surface, [lastNode partOfSpeech]);
                    count++;
                }
#else
                NSString *subType1 = [lastNode partOfSpeechSubtype1];
                NSString *subType2 = [lastNode partOfSpeechSubtype2];
                NSString *subType3 = [lastNode partOfSpeechSubtype3];
                NSString *baseToken = @"語幹";
                NSString *contentToken = nil;
                NSUInteger baseTokenLength = [baseToken length];
                
                if ([subType1 length] > baseTokenLength &&
                    [[subType1 substringFromIndex:[subType1 length] - baseTokenLength] isEqualToString:baseToken])
                {
                    contentToken = [subType1 substringToIndex:[subType1 length] - baseTokenLength];
                } else if ([subType2 length] > baseTokenLength &&
                           [[subType2 substringFromIndex:[subType2 length] - baseTokenLength] isEqualToString:baseToken])
                {
                    contentToken = [subType2 substringToIndex:[subType2 length] - baseTokenLength];
                } else if ([subType3 length] > baseTokenLength &&
                           [[subType3 substringFromIndex:[subType3 length] - baseTokenLength] isEqualToString:baseToken])
                {
                    contentToken = [subType3 substringToIndex:[subType3 length] - baseTokenLength];
                }
                if ([contentToken length]) {
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
                        [nodes replaceObjectAtIndex:index withObject:node];

                        [newNode setSurface:@"も"];
                        [newNode setPronunciation:@"モ"];
                        [newNode setOriginalForm:@"も"];
                        [newNode setPartOfSpeech:@"助詞"];
                        [newNode setPartOfSpeechSubtype1:@"係助詞"];
                        [newNode setInflection:@"™"];
                        newNode.visible = YES;
                        [nodes insertObject:newNode atIndex:index+1];
                        [newNode release];
                        goto start;
                    } else {
                        lastNode.visible = NO;
                        
                        // マージする。
                        [node setPartOfSpeech:contentToken];

                        [node setSurface:[[lastNode surface]             stringByAppendingString:[node surface]]];
                        [node setPronunciation:[[lastNode pronunciation] stringByAppendingString:[node pronunciation]]];
                        [node setOriginalForm:[[lastNode originalForm]   stringByAppendingString:[node originalForm]]];
                        [node setInflection:[@"™" stringByAppendingString:[node inflection]]];
                        NSLog(@"<<%@:%@", lastNode.surface, [lastNode partOfSpeech]);
                        
                        // ゴミ処理
                        if ([[node partOfSpeech] isEqualToString:@"形容動詞"] &&
                            [[node partOfSpeechSubtype1] isEqualToString:@"格助詞"])
                        {
                            [node setPartOfSpeechSubtype1:@""];
                        }
                        count++;
                    }
                }
#endif
            }
        }
        lastNode = node;
    }
}

// 【複合動詞】
- (void) patch_merge_FUKUGO_DOSHI {
    NSUInteger count = 0;
    Node *lastNode = nil;
    
    for (NSUInteger index = 0; index < [nodes count]; index++) {
        Node *node = nodes[index];

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
                NSLog(@"<<%@:%@", lastNode.surface, [lastNode partOfSpeech]);
                count++;
            }
        }
        lastNode = node;
    }
}

// 【複合動詞（サ変接続など）】
- (void) patch_merge_FUKUGO_DOSHI_SAHEN {
    NSUInteger count = 0;
    Node *lastNode = nil;
    
    for (NSUInteger index = 0; index < [nodes count]; index++) {
        Node *node = nodes[index];
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
                    NSLog(@"<<%@:%@", lastNode.surface, [lastNode partOfSpeech]);
                    count++;
                }
            }
        }
        lastNode = node;
    }
}

// 【副詞】用言に連なる「そう」は全て副詞だが、mecab は名詞を返す。
- (void) patchAdverbSou {
    NSUInteger count = 0;
    Node *lastNode = nil;
    
    for (Node *node in nodes) {
        if (lastNode) {
            if ([self isYougen:[lastNode partOfSpeech]] &&
                [node.surface isEqualToString:@"そう"])
            {// 用言に連なる「そう」は全て副詞。
                [node setPartOfSpeech:@"副詞"];
                [node setPartOfSpeechSubtype1:@""];
                [node setPartOfSpeechSubtype2:@""];
                [node setPartOfSpeechSubtype3:@""];
                count++;
            }
        }
        lastNode = node;
    }
}

// 【伝聞、様相の助動詞】伝聞、様相の「そうです」は助動詞だが、mecab は名詞+助動詞を返す。
- (void) patch1b {
    NSUInteger count = 0;
    Node *lastNode = nil;
    
    for (Node *node in nodes) {
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
                    count++;
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
                    count++;
                }
            }
        }
        lastNode = node;
    }
}

// 【副詞化】形容動詞＋助詞（に）で副詞化はすべきだが、mecab は名詞+助動詞を返す。
- (void) patch2 {
    NSUInteger count = 0;
    Node *lastNode = nil;
    
    for (Node *node in nodes) {
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
                    count++;
                }
            }
        }
        lastNode = node;
    }
}

// 【副詞化】体言＋助詞（で）＋「、」は断定を表す助動詞「だ」の連用形。
- (void) patch_TAIGEN_DA {
    NSUInteger count = 0;
    Node *lastNode = nil;
    Node *nextNode = nil;
    
    for (NSUInteger i = 0; i < [nodes count]; i++) {
        Node *node = nodes[i];
        
        if (i < [nodes count] - 1) {
            nextNode = nodes[i + 1];
        } else {
            nextNode = nil;
        }
        if (lastNode && [self isTaigen:[lastNode partOfSpeech]] &&
            nextNode && [[nextNode partOfSpeechSubtype1] isEqualToString:@"読点"])
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
                count++;
            }
        }
        lastNode = node;
    }
}

// 【準体助詞】「なのだ」の「の」が名詞ではおかしい。
- (void) patch_NANODA_NO {
    NSUInteger count = 0;
    
    for (Node *node in nodes) {
        if ([node.surface isEqualToString:@"の"] &&
            [[node partOfSpeech] isEqualToString:@"名詞"])
        {
            if ([[node partOfSpeechSubtype1] isEqualToString:@"非自立"])
            {// 準体助詞である。
                [node setPartOfSpeech:@"助詞"];
                [node setPartOfSpeechSubtype1:@"準体助詞"];
                [node setPartOfSpeechSubtype2:@""];
                count++;
            }
        }
    }
}

// 【感動詞】「そう」がいつも副詞ではおかしい。
- (void) patch_KANDOSHI_SOU {
    NSUInteger count = 0;
    
    if ([nodes count] == 1) {
        Node *node = nodes[0];

        if ([node.surface isEqualToString:@"そう"] &&
            [[node partOfSpeech] isEqualToString:@"副詞"] &&
            [[node partOfSpeechSubtype1] isEqualToString:@"助詞類接続"])
        {
            [node setPartOfSpeech:@"感動詞"];
            [node setPartOfSpeechSubtype1:@""];
            [node setPartOfSpeechSubtype2:@""];
            count++;
        }
    } else if ([nodes count] > 1) {
        for (NSUInteger i = 0; i < [nodes count]; i++) {
            Node *node = nodes[i];
            
            if ([node.surface isEqualToString:@"そう"] &&
                [[node partOfSpeech] isEqualToString:@"副詞"] &&
                [[node partOfSpeechSubtype1] isEqualToString:@"助詞類接続"])
            {// 副詞である。
                if (i < [nodes count] - 1) {
                    Node *nextNode = nodes[i+1];

                    if ([self isYougen:[nextNode partOfSpeech]] == NO) {
                        [node setPartOfSpeech:@"感動詞"];
                        [node setPartOfSpeechSubtype1:@""];
                        [node setPartOfSpeechSubtype2:@""];
                        count++;
                    }
                } else {
                    [node setPartOfSpeech:@"感動詞"];
                    [node setPartOfSpeechSubtype1:@""];
                    [node setPartOfSpeechSubtype2:@""];
                    count++;
                }
            }
        }
    }
}

// 【補助形容詞】事前のトークンが形容詞の場合の「ない」は補助形容詞。
//
// ※動詞・形容詞に導かれる、補助形容詞「ほしい」「ない」の現状は下記。
// ○動詞+ほしい
// ○形容詞+ほしい
// ○動詞+ない（助動詞）
// ×形容詞+ない
//
- (void) patch_KEIYOUSHI_NAI {
    NSUInteger count = 0;
    Node *lastNode = nil;
    
    for (Node *node in nodes) {
        if (lastNode) {
            if ([[node partOfSpeech] isEqualToString:@"助動詞"] &&
                [node.surface isEqualToString:@"ない"])
            {
//                if ([self isYougen:[lastNode partOfSpeech]])
                if ([[lastNode partOfSpeech] isEqualToString:@"形容詞"])
                {// 動詞／形容詞＋形容詞（ない）
                    [node setPartOfSpeech:@"形容詞"];
                    [node setPartOfSpeechSubtype1:@"補助形容詞"];
                    [node setInflection:@"™○:ほしい、×:ない"];
                    count++;
                }
            }
        }
        lastNode = node;
    }
}

// 【形容詞化】体言＋助動詞（らしい）＋体言は連体形の形容詞。
- (void) patch_TAIGEN_RASHII {
    NSUInteger count = 0;
    Node *lastNode = nil;
    Node *nextNode = nil;
    
    for (NSUInteger i = 0; i < [nodes count]; i++) {
        Node *node = nodes[i];
        
        if (i < [nodes count] - 1) {
            nextNode = nodes[i + 1];
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
                count++;
            }
        }
        lastNode = node;
    }
}

// 【終助詞化】末端の接続助詞「とも」は強調を示す終助詞。
- (void) patch_TOMO {
    
    for (NSUInteger i = 0; i < [nodes count]; i++) {
        Node *node = nodes[i];

        if ([[node partOfSpeechSubtype1] isEqualToString:@"接続助詞"] &&
            [node.surface isEqualToString:@"とも"])
        {
            if ([self isEndOfSentence:i + 1]) {
                [node setPartOfSpeechSubtype1:@"終助詞"];
                [node setInflection:@"™強調"];
            }
        }
    }
}

// 【終助詞化】句点を従えた接続助詞「とも」は強調を示す終助詞。
- (void) patch_TOMO_KUTEN {
    NSUInteger count = 0;
    Node *lastNode = nil;
    Node *nextNode = nil;
    
    for (NSUInteger i = 0; i < [nodes count]; i++) {
        Node *node = nodes[i];
        
        if (i < [nodes count] - 1) {
            nextNode = nodes[i + 1];
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
                count++;
            }
        }
        lastNode = node;
    }
}

// 【接続助詞化】「呼んでも」の「で・も」は動詞が五段活用の場合は連結する。
- (void) patch_DE_MO {
    NSUInteger count = 0;
    Node *lastNode = nil;
    Node *nextNode = nil;
    Node *nextNextNode = nil;
    
    for (NSUInteger i = 0; i < [nodes count]; i++) {
        Node *node = nodes[i];
        
        if (i < [nodes count] - 1) {
            nextNode = nodes[i + 1];
        } else {
            nextNode = nil;
        }
        if (i < [nodes count] - 2) {
            nextNextNode = nodes[i + 2];
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
            count++;
        }
        lastNode = node;
    }
}

// 【接続助詞化】「こちらでも、」の副助詞「でも」は、格助詞「で」と副助詞「も」に分割する。
- (void) patch_DEMO {
    NSUInteger count = 0;
    Node *lastNode = nil;
    
    for (NSUInteger index = 0; index < [nodes count]; index++) {
        Node *node = nodes[index];

        if (lastNode) {
            if (index < [nodes count] - 1) {
                Node *nextNode = nodes[index + 1];

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
                    [nodes replaceObjectAtIndex:index withObject:node];
                    
                    [newNode setSurface:@"も"];
                    [newNode setPronunciation:@"モ"];
                    [newNode setOriginalForm:@"も"];
                    [newNode setPartOfSpeech:@"助詞"];
                    [newNode setPartOfSpeechSubtype1:@"係助詞"];
                    [newNode setInflection:@"™"];
                    newNode.visible = YES;
                    [nodes insertObject:newNode atIndex:index+1];
                    [newNode release];
                    count++;
                }
            }
        }
        lastNode = node;
    }
}

// 【副助詞化】「子供でも」の「でも」＋動詞の場合は、副助詞「でも」にする。
- (BOOL) patch_DATTE {
    NSUInteger count = 0;
    Node *lastNode = nil;
    Node *nextNode = nil;
    BOOL asked = NO;
    
    for (NSUInteger i = 0; i < [nodes count]; i++) {
        Node *node = nodes[i];
        
        if (i < [nodes count] - 1) {
            nextNode = nodes[i + 1];
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
            count++;
        }
        lastNode = node;
    }
    return asked;
}

// 【終止形／連体形／連用形】
- (void) patch_YOUGO {
    
    NSUInteger count = 0;
    
    for (Node *node in nodes) {
        NSString *useOfType = [node useOfType];
        NSString *partOfSpeechSubtype1 = [node partOfSpeechSubtype1];
        NSString *inflection = [node inflection];

        // 【補助動詞】partOfSpeech
        if ([[node partOfSpeech] isEqualToString:@"動詞"])
        {
            if ([partOfSpeechSubtype1 isEqualToString:@"自立"])
            {// 本動詞である。
                [node setPartOfSpeechSubtype1:@"本動詞"];
                count++;
            }
            if ([partOfSpeechSubtype1 isEqualToString:@"非自立"])
            {// 補助動詞である。
                [node setPartOfSpeechSubtype1:@"補助動詞"];
                count++;
            }
        }
        // 【係助詞→副助詞】partOfSpeechSubtype1
        if ([partOfSpeechSubtype1 isEqualToString:@"係助詞"])
        {
            [node setPartOfSpeechSubtype1:@"副助詞"];
            count++;
        }
        // 【終止形／連体形／連用形】useOfType
        if ([useOfType isEqualToString:@"基本形"])
        {
            [node setUseOfType:@"終止形"];
            count++;
        } else if ([useOfType isEqualToString:@"体言接続"])
        {
            [node setUseOfType:@"連体形"];
            count++;
        } else if ([useOfType isEqualToString:@"用言接続"])
        {
            [node setUseOfType:@"連用形"];
            count++;
        }
        // 一段
        if ([inflection isEqualToString:@"一段"]) {
            NSString *str = [self ichidanString:[node pronunciation]];
            
            if ([str length]) {
                [node setInflection:str];
            }
        }
    }
}

#pragma mark - IBAction

- (IBAction)parse:(id)sender {
    [textField resignFirstResponder];
    
    NSString *string = textField.text;
    
    self.nodes = [NSMutableArray arrayWithArray:[mecab parseToNodeWithString:string]];
    [self preProcess];
    
    if (patch.on) {
        [self patch_merge_FUKUGO_DOSHI];
        [self patch_merge_FUKUGO_DOSHI_SAHEN];
        [self patch_merge_MEISHI];
#if 1
        [self patch_merge_FUZOKUGO];
#else
        [self patchAdverbSou];
        [self patch1b];
        [self patch2];
#endif
        [self patch_TAIGEN_DA];
        [self patch_NANODA_NO];
        [self patch_KANDOSHI_SOU];
        [self patch_KEIYOUSHI_NAI];
        [self patch_TAIGEN_RASHII];
        [self patch_TOMO];
        [self patch_TOMO_KUTEN];
        [self patch_DE_MO];
        [self patch_DEMO];
        [self patch_DATTE];

        [self patch_YOUGO];
    }
    [tableView_ reloadData];
    
    if ([string length]) {
        NSUInteger index = [tokens indexOfObject:string];
        
        if (index == NSNotFound) {
            [tokens addObject:string];
        }
        [tokens writeToFile:kTokesXMLPath atomically:YES];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:kDefaultsToken];
    }
}

- (IBAction) setPatchDefaults:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:patch.on forKey:kDefaultsPatch];
}

- (IBAction) openTokensView:(id)sender {
    
    [textField resignFirstResponder];

    if ([tokens count])
    {// トークンリストのモーダルダイアログを表示する。
        TokensViewController *viewController = [[TokensViewController alloc] initWithNibName:@"TokensViewController"
                                                                                      bundle:nil
                                                                                 tokensArray:tokens];
        
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
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [textField resignFirstResponder];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
    upperSet = [[NSSet setWithObjects:@"イ", @"キ", @"ギ", @"シ", @"ジ", @"チ", @"ヂ", @"ニ", @"ヒ", @"ビ", @"ミ", @"リ", nil] retain];
    lowerSet = [[NSSet setWithObjects:@"エ", @"ケ", @"ゲ", @"セ", @"ゼ", @"テ", @"デ", @"ネ", @"ヘ", @"ベ", @"メ", @"レ", nil] retain];

    [tableView_ becomeFirstResponder];
    
    self.tokens = [NSMutableArray arrayWithArray:[NSArray arrayWithContentsOfFile:kTokesXMLPath]];

    self.mecab = [[Mecab new] autorelease];
    explore.layer.cornerRadius = 5.0;
    [patch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kDefaultsPatch]];
    
    textField.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSString *string = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsToken];
    
    if ([string length]) {
        [textField setText:string];
        
        [self parse:self];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (nodes) {
		return [nodes count];
	}
	
	return 0;
}

// セパレータの設定
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"NodeCell";
    
    NodeCell *cell = (NodeCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"NodeCell" owner:self options:nil];
		cell = nodeCell;
		self.nodeCell = nil;
    }
    
	Node *node = [nodes objectAtIndex:indexPath.row];

    if ([node reading] && ! [[node reading] isEqualToString:@"(null)"]) {
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
    [inflection replaceOccurrencesOfString:@"™" withString:@""
                               options:NSLiteralSearch
                                 range:NSMakeRange(0, [inflection length])];
    if ([inflection isEqualToString:[node inflection]] == NO) {
        cell.inflectionLabel.textColor = [UIColor brownColor];
    } else {
        cell.inflectionLabel.textColor = [UIColor blackColor];
    }
    cell.inflectionLabel.text = inflection;
    // 活用型
    cell.useOfTypeLabel.text = [node useOfType];
/*
 - (NSString *)partOfSpeech;
 // 品詞細分類1
 - (NSString *)partOfSpeechSubtype1;
 // 品詞細分類2
 - (NSString *)partOfSpeechSubtype2;
 // 品詞細分類3
 - (NSString *)partOfSpeechSubtype3;
 // 活用形
 - (NSString *)inflection;
 // 活用型
 - (NSString *)useOfType;
 // 原形
 - (NSString *)originalForm;
 // 読み
 - (NSString *)reading;
 // 発音
 - (NSString *)pronunciation;
 */
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Node *node = [nodes objectAtIndex:indexPath.row];

    if (node.visible) {
        return 82.0;
    } else {
        return 0.0;
    }
}

- (void)dealloc {
	self.mecab = nil;
	self.nodes = nil;
	
	self.textField = nil;
	self.tableView_ = nil;
	self.nodeCell = nil;
    [super dealloc];
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)textFld {
    [textField resignFirstResponder];
    return NO;
}

@end
