//
//  FileSpec.h
//  HinshiMaster
//
//  Created by matsu on 10/11/11.
//  Copyright 2010 家事手伝い. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FileSpec : NSObject <NSCoding, NSCopying> {

	NSString *_title;						// タグ（fileName/symbolから生成する）（表示用）
	NSString *_scheme;						// スキーム名（@"file"）
	NSString *_host;						// ホスト名（@""）
	NSString *_path;						// ファイルのフルパス名
	NSString *_dir;							// 親ディレクトリ名
	NSString *_fileName;					// ファイル名
	BOOL _isNormalized;						// 正規化されているか
	NSString *_extension;					// 拡張子
	NSString *_resourceType;				// MIMEリソースタイプ
	unsigned long long _contentLength;		// データ長
	NSDate *_creationDate;					// 作成日時
	NSDate *_modificationDate;				// 修正日時
	BOOL _isDir;							// ディレクトリか否か
	BOOL _isSymbolicLink;					// シンボリックリンクか否か
	NSMutableArray *_symbols;				// シンボリックリンク名（アレイのメンバーはコピーしない）
	NSSet *_children;						// FileSpec の Set（未使用）
	NSString *_zipPath;						// ZIPファイルのフルパス名
	NSStringEncoding _zipInnerPathEncoding;	// ZIPアーカイブ内部のパスエンコーディング
	NSStringEncoding _dataEncoding;			// データのエンコーディング（テキストの場合のみ）
	BOOL _selected;							// 選択フラグ
	BOOL _isDeleted;						// 論理削除フラグ
    // 
    BOOL _is_Sandbox;
    BOOL _is_iCloudStored;
    BOOL _is_iCloudDownloaded;
    BOOL _is_iCloudUploaded;
    BOOL _is_iCloudDownloading;
    BOOL _is_iCloudUploading;
    CGFloat _iCloudPercent;
	unsigned long long _iCloudContentLength;
	NSDate *_iCloudCreationDate;
	NSDate *_iCloudModificationDate;
    // 
    NSUInteger _flags;                      // 各種フラグ（FileAttribute）
}

@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) NSString *scheme;
@property (nonatomic,copy) NSString *host;
@property (nonatomic,copy) NSString *path;
@property (nonatomic,copy) NSString *dir;
@property (nonatomic,copy) NSString *fileName;
@property (nonatomic,assign) BOOL isNormalized;
@property (nonatomic,copy) NSString *extension;
@property (nonatomic,copy) NSString *resourceType;
@property (nonatomic,assign) unsigned long long contentLength;
@property (nonatomic,copy) NSDate *creationDate;
@property (nonatomic,copy) NSDate *modificationDate;
@property (nonatomic,assign) BOOL isDir;
@property (nonatomic,assign) BOOL isSymbolicLink;
@property (nonatomic,retain) NSMutableArray *symbols;
@property (nonatomic,copy) NSSet *children;
@property (nonatomic,copy) NSString *zipPath;
@property (nonatomic,assign) NSStringEncoding zipInnerPathEncoding;
@property (nonatomic,assign) NSStringEncoding dataEncoding;
@property (nonatomic,assign) BOOL selected;
@property (nonatomic,assign) BOOL isDeleted;
@property (nonatomic,assign) BOOL is_Sandbox;
@property (nonatomic,assign) BOOL is_iCloudStored;
@property (nonatomic,assign) BOOL is_iCloudDownloaded;
@property (nonatomic,assign) BOOL is_iCloudUploaded;
@property (nonatomic,assign) BOOL is_iCloudDownloading;
@property (nonatomic,assign) BOOL is_iCloudUploading;
@property (nonatomic,assign) CGFloat iCloudPercent;
@property (nonatomic,assign) unsigned long long iCloudContentLength;
@property (nonatomic,copy) NSDate *iCloudCreationDate;
@property (nonatomic,copy) NSDate *iCloudModificationDate;
@property (nonatomic,assign) NSUInteger flags;

- (id) copyWithZone:(NSZone*)zone;

@end
