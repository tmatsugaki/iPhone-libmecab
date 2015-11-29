//
//  Mecab.m
//
//  Created by Watanabe Toshinori on 10/12/22.
//  Copyright 2010 FLCL.jp. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iconv.h>
#import "Mecab.h"
#import "Node.h"


@implementation Mecab

- (NSArray *)parseToNodeWithString:(NSString *)string {

	if (mecab == NULL) {
		
#if TARGET_IPHONE_SIMULATOR
		// Homebrew mecab path
		NSString *path = @"/usr/local/Cellar/mecab/0.98/lib/mecab/dic/ipadic";
#else
		NSString *path = [[NSBundle mainBundle] resourcePath];
#endif
		
		mecab = mecab_new2([[@"-d " stringByAppendingString:path] UTF8String]);

		if (mecab == NULL) {
			fprintf(stderr, "error in mecab_new2: %s\n", mecab_strerror(NULL));
			
			return nil;
		}
	}

	const mecab_node_t *node;
	const char *buf= [string cStringUsingEncoding:NSUTF8StringEncoding];
	NSUInteger l= [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

	node = mecab_sparse_tonode2(mecab, buf, l);
	if (node == NULL) {
		fprintf(stderr, "error\n");

		return nil;
	}
	
	NSMutableArray *newNodes = [NSMutableArray array];
	node = node->next;
	for (; node->next != NULL; node = node->next) {

		Node *newNode = [Node new];
		newNode.surface = [[[NSString alloc] initWithBytes:node->surface length:node->length encoding:NSUTF8StringEncoding] autorelease];
		newNode.feature = [NSString stringWithCString:node->feature encoding:NSUTF8StringEncoding];
		[newNodes addObject:newNode];
		[newNode release];
	}
	
	return [NSArray arrayWithArray:newNodes];
}

- (void)dealloc {
	if (mecab != NULL) {
		mecab_destroy(mecab);
	}

	[super dealloc];
}

@end
