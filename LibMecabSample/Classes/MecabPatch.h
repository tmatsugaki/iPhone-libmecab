//
//  MecabPatch.h
//  LibMecabSample
//
//  Created by matsu on 2015/12/16.
//
//

#import <Foundation/Foundation.h>
#import "LibMecabSampleAppDelegate.h"

@interface MecabPatch : NSObject {

    NSSet *_upperSet;
    NSSet *_lowerSet;
    NSString *_sentence;
    NSMutableArray *_nodes;
    BOOL _modified;
    LibMecabSampleAppDelegate *_appDelegate;
}
@property (nonatomic, retain) NSSet *upperSet;
@property (nonatomic, retain) NSSet *lowerSet;
@property (nonatomic, retain) NSString *sentence;
@property (nonatomic, retain) NSMutableArray *nodes;
@property (nonatomic, assign) BOOL modified;
@property (nonatomic, assign) LibMecabSampleAppDelegate *appDelegate;

+ (MecabPatch *) sharedManager;
+ (BOOL) isTaigen:(NSString *)hinshi;
+ (BOOL) isYougen:(NSString *)hinshi;
+ (BOOL) isKeiyoushi:(NSString *)hinshi;
+ (BOOL) isFuzokugo:(NSString *)hinshi;

- (void) preProcess;                        // 語幹のマージに先立つこと！！
- (void) patch_fix_KEIYODOSHI;              // 語幹のマージに先立つこと！！
- (void) patch_fix_RARERU;                  // 語幹のマージに先立つこと！！
- (void) patch_merge_HIJIRITSU_MEISHI;      // 語幹のマージに先立つこと！！
- (void) patch_merge_DOSHI;                 // 語幹のマージに先立つこと！！
- (void) patch_merge_FUKUGO_DOSHI;          // 語幹のマージに先立つこと！！
- (void) patch_merge_FUKUGO_DOSHI_SAHEN;    // 語幹のマージに先立つこと！！
- (void) patch_before_merge_GOKAN;          // 語幹のマージに先立つこと！！
- (void) patch_merge_GACHI_GIMI_YASUI;      // 語幹のマージに先立つこと！！
- (void) patch_merge_N;                     // 語幹のマージに先立つこと！！
- (void) patch_merge_JIMI;                  // 語幹のマージに先立つこと！！
//
- (void) patch_merge_GOKAN;                 // 語幹のマージをする最も重要な処理！！
//
- (BOOL) patch_FUKUGO_KEIYO_SHI;            // 語幹のマージ後、名詞マージの前！！
- (BOOL) patch_HASEI_KEIYO_SHI;             // 語幹のマージ後、名詞マージの前！！
//
- (void) patch_merge_MEISHI;                // 語幹のマージ実施後に実施すること！！
- (void) patch_detect_FUKUSHI;              // 語幹のマージ実施後に実施すること！！
- (void) patch_TAIGEN_DA;                   // 語幹のマージ実施後に実施すること！！
- (void) patch_NANODA_NO;                   // 語幹のマージ実施後に実施すること！！
- (void) patch_KANDOSHI_SOU;                // 語幹のマージ実施後に実施すること！！
- (void) patch_HOJO_KEIYOUSHI;              // 語幹のマージ実施後に実施すること！！
- (void) patch_TAIGEN_RASHII;               // 語幹のマージ実施後に実施すること！！
- (void) patch_TOMO;                        // 語幹のマージ実施後に実施すること！！
- (void) patch_TOMO_KUTEN;                  // 語幹のマージ実施後に実施すること！！
- (void) patch_MERGE_YOUGEN_DEMO;           // 語幹のマージ実施後に実施すること！！
- (void) patch_DIVIDE_TAIGEN_DEMO;          // 語幹のマージ実施後に実施すること！！
- (BOOL) patch_MERGE_TAIGEN_DEMO;           // 語幹のマージ実施後に実施すること！！
- (BOOL) patch_DONNA;                       // 語幹のマージ実施後に実施すること！！
- (BOOL) patch_TATOEBA;                     // 語幹のマージ実施後に実施すること！！
- (void) postProcess;                       // 語幹のマージ実施後に実施すること！！
@end
