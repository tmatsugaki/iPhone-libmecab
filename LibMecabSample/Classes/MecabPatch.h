//
//  MecabPatch.h
//  LibMecabSample
//
//  Created by matsu on 2015/12/16.
//
//

#import <Foundation/Foundation.h>

@interface MecabPatch : NSObject {

    NSSet *_upperSet;
    NSSet *_lowerSet;
    NSMutableArray *_nodes;
    BOOL _modified;
}
@property (nonatomic, retain) NSSet *upperSet;
@property (nonatomic, retain) NSSet *lowerSet;
@property (nonatomic, retain) NSMutableArray *nodes;
@property (nonatomic, assign) BOOL modified;

+ (MecabPatch *) sharedManager;

- (void) preProcess;
- (void) patch_merge_FUKUGO_DOSHI;
- (void) patch_merge_FUKUGO_DOSHI_SAHEN;
- (void) patch_before_merge_GOKAN;
- (void) patch_merge_GOKAN;
- (void) patch_merge_MEISHI;
- (void) patch_TAIGEN_DA;
- (void) patch_NANODA_NO;
- (void) patch_KANDOSHI_SOU;
- (void) patch_HOJO_KEIYOUSHI_NAI;
- (void) patch_TAIGEN_RASHII;
- (void) patch_TOMO;
- (void) patch_TOMO_KUTEN;
- (void) patch_DE_MO;
- (void) patch_DEMO;
- (BOOL) patch_DATTE;
- (void) postProcess;
// 以下は未使用
- (void) patch_OLD_FUKUSHI_SO;
- (void) patch_OLD_SOU;
- (void) patch_OLD_FUKUSHI_KA;

@end
