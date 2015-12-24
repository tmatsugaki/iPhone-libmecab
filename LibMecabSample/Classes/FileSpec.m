//
//  FileSpec.m
//  HinshiMaster
//
//  Created by matsu on 10/11/11.
//  Copyright 2010 家事手伝い. All rights reserved.
//

#import "FileSpec.h"

@interface FileSpec ()
@end

@implementation FileSpec

@synthesize title=_title;								// タグ（fileName/symbolから生成する）（表示用）
@synthesize scheme=_scheme;								// スキーム名
@synthesize host=_host;									// ホスト名
@synthesize path=_path;									// ファイルのフルパス名
@synthesize dir=_dir;									// 親ディレクトリ名
@synthesize fileName=_fileName;							// ファイル名
@synthesize isNormalized=_isNormalized;					// 正規化されているか
@synthesize extension=_extension;						// 拡張子
@synthesize resourceType=_resourceType;					// MIMEリソースタイプ
@synthesize contentLength=_contentLength;				// データ長
@synthesize creationDate=_creationDate;					// 作成日時
@synthesize modificationDate=_modificationDate;			// 修正日時
@synthesize isDir=_isDir;								// ディレクトリか否か
@synthesize isSymbolicLink=_isSymbolicLink;				// シンボリックリンクか否か
@synthesize symbols=_symbols;							// シンボリックリンク名
@synthesize children=_children;							// 
@synthesize zipPath=_zipPath;							// 仮想のフルパス名（ZIPファイルなどの表示用）
@synthesize zipInnerPathEncoding=_zipInnerPathEncoding;	// 
@synthesize dataEncoding=_dataEncoding;					// 
@synthesize selected=_selected;							// 選択フラグ
@synthesize isDeleted=_isDeleted;						// 論理削除フラグ
// 
@synthesize is_Sandbox=_is_Sandbox;
@synthesize is_iCloudStored=_is_iCloudStored;
@synthesize is_iCloudDownloaded=_is_iCloudDownloaded;
@synthesize is_iCloudUploaded=_is_iCloudUploaded;
@synthesize is_iCloudDownloading=_is_iCloudDownloading;
@synthesize is_iCloudUploading=_is_iCloudUploading;
@synthesize iCloudPercent=_iCloudPercent;
@synthesize iCloudContentLength=_iCloudContentLength;
@synthesize iCloudCreationDate=_iCloudCreationDate;
@synthesize iCloudModificationDate=_iCloudModificationDate;
@synthesize flags=_flags;                               // 各種フラグ

- (id) initWithCoder:(NSCoder *)coder {
	self = [super init];
	if (self != nil) {
		self.title					= [coder decodeObjectForKey:@"title"];
		self.scheme					= [coder decodeObjectForKey:@"scheme"];
		self.host					= [coder decodeObjectForKey:@"host"];
		self.path					= [coder decodeObjectForKey:@"path"];
		self.dir					= [coder decodeObjectForKey:@"dir"];
		self.fileName				= [coder decodeObjectForKey:@"fileName"];
		self.isNormalized			= [coder decodeBoolForKey:@"isNormalized"];
		self.extension				= [coder decodeObjectForKey:@"extension"];
		self.resourceType			= [coder decodeObjectForKey:@"resourceType"];
		self.contentLength			= [coder decodeInt64ForKey:@"contentLength"];
		self.creationDate			= [coder decodeObjectForKey:@"creationDate"];
		self.modificationDate		= [coder decodeObjectForKey:@"modificationDate"];
		self.isDir					= [coder decodeBoolForKey:@"isDir"];
		self.isSymbolicLink			= [coder decodeBoolForKey:@"isSymbolicLink"];
		self.symbols				= [coder decodeObjectForKey:@"symbols"];
		self.children				= [coder decodeObjectForKey:@"children"];
		self.zipPath				= [coder decodeObjectForKey:@"zipPath"];
		self.zipInnerPathEncoding	= [coder decodeIntForKey:@"zipInnerPathEncoding"];
		self.dataEncoding			= [coder decodeIntForKey:@"dataEncoding"];
		self.selected				= [coder decodeBoolForKey:@"selected"];
		self.isDeleted				= [coder decodeBoolForKey:@"isDeleted"];
		self.is_Sandbox      = [coder decodeIntForKey:@"is_Sandbox"];
		self.is_iCloudStored        = [coder decodeIntForKey:@"is_iCloudStored"];
		self.is_iCloudDownloaded    = [coder decodeIntForKey:@"is_iCloudDownloaded"];
		self.is_iCloudUploaded      = [coder decodeIntForKey:@"is_iCloudUploaded"];
		self.is_iCloudDownloading   = [coder decodeIntForKey:@"is_iCloudDownloading"];
		self.is_iCloudUploading     = [coder decodeIntForKey:@"is_iCloudUploading"];
		self.iCloudPercent          = [coder decodeFloatForKey:@"iCloudPercent"];
		self.iCloudContentLength	= [coder decodeInt64ForKey:@"iCloudContentLength"];
		self.iCloudCreationDate		= [coder decodeObjectForKey:@"iCloudCreationDate"];
		self.iCloudModificationDate	= [coder decodeObjectForKey:@"iCloudModificationDate"];
		self.flags                  = [coder decodeIntForKey:@"flags"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:_title				forKey:@"title"];
	[coder encodeObject:_scheme				forKey:@"scheme"];
	[coder encodeObject:_host				forKey:@"host"];
	[coder encodeObject:_path				forKey:@"path"];
	[coder encodeObject:_dir				forKey:@"dir"];
	[coder encodeObject:_fileName			forKey:@"fileName"];
	[coder encodeBool:_isNormalized			forKey:@"isNormalized"];
	[coder encodeObject:_extension			forKey:@"extension"];
	[coder encodeObject:_resourceType		forKey:@"resourceType"];
	[coder encodeInt64:_contentLength		forKey:@"contentLength"];
	[coder encodeObject:_creationDate		forKey:@"creationDate"];
	[coder encodeObject:_modificationDate	forKey:@"modificationDate"];
	[coder encodeBool:_isDir				forKey:@"isDir"];
	[coder encodeBool:_isSymbolicLink		forKey:@"isSymbolicLink"];
	[coder encodeObject:_symbols			forKey:@"symbols"];
	[coder encodeObject:_children			forKey:@"children"];
	[coder encodeObject:_zipPath			forKey:@"zipPath"];
	[coder encodeInt:_zipInnerPathEncoding	forKey:@"zipInnerPathEncoding"];
	[coder encodeInt:_dataEncoding			forKey:@"dataEncoding"];
	[coder encodeBool:_selected				forKey:@"selected"];
	[coder encodeBool:_isDeleted			forKey:@"isDeleted"];
	[coder encodeInt:_is_Sandbox     forKey:@"is_Sandbox"];
	[coder encodeInt:_is_iCloudStored       forKey:@"is_iCloudStored"];
	[coder encodeInt:_is_iCloudDownloaded   forKey:@"is_iCloudDownloaded"];
	[coder encodeInt:_is_iCloudUploaded     forKey:@"is_iCloudUploaded"];
	[coder encodeInt:_is_iCloudDownloading  forKey:@"is_iCloudDownloading"];
	[coder encodeInt:_is_iCloudUploading    forKey:@"is_iCloudUploading"];
	[coder encodeInt:_iCloudPercent         forKey:@"iCloudPercent"];
	[coder encodeInt64:_iCloudContentLength		forKey:@"iCloudContentLength"];
	[coder encodeObject:_iCloudCreationDate		forKey:@"iCloudCreationDate"];
	[coder encodeObject:_iCloudModificationDate	forKey:@"iCloudModificationDate"];
	[coder encodeInt:_flags                 forKey:@"flags"];
}

- (id) copyWithZone:(NSZone *)zone {

    FileSpec *clone = [[FileSpec allocWithZone:zone] init];

    clone.title					= _title;
    clone.scheme				= _scheme;
    clone.host					= _host;
    clone.path					= _path;
    clone.dir					= _dir;
    clone.fileName				= _fileName;
    clone.isNormalized			= _isNormalized;
    clone.extension				= _extension;
    clone.resourceType			= _resourceType;
    clone.contentLength			= _contentLength;
    clone.creationDate			= _creationDate;
    clone.modificationDate		= _modificationDate;
    clone.isDir					= _isDir;
    clone.isSymbolicLink		= _isSymbolicLink;
    clone.symbols				= _symbols;
    clone.children				= _children;
    clone.zipPath				= _zipPath;
    clone.zipInnerPathEncoding	= _zipInnerPathEncoding;
    clone.dataEncoding			= _dataEncoding;
    clone.selected				= _selected;
    clone.isDeleted             = _isDeleted;	
    clone.is_Sandbox     = _is_Sandbox;	
    clone.is_iCloudStored       = _is_iCloudStored;	
    clone.is_iCloudDownloaded   = _is_iCloudDownloaded;	
    clone.is_iCloudUploaded     = _is_iCloudUploaded;	
    clone.is_iCloudDownloading  = _is_iCloudDownloading;	
    clone.is_iCloudUploading    = _is_iCloudUploading;	
    clone.iCloudPercent         = _iCloudPercent;	
    clone.iCloudContentLength		= _iCloudContentLength;
    clone.iCloudCreationDate		= _iCloudCreationDate;
    clone.iCloudModificationDate	= _iCloudModificationDate;
    clone.flags                 = _flags;	
    return clone;
}

- (void) dealloc {
}

@end
