/**
 * \file MixiBatchRequest.h
 * \brief 特殊なAPI呼び出しに必要な情報を保持するクラスを定義します。
 *
 * Created by Platform Service Department on 11/08/03.
 * Copyright 2013 mixi Inc. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "MixiURLRequestConstructor.h"

@class Mixi;

/**
 * \brief 特殊なAPIのリクエストに必要な情報を保持するクラス
 */
@interface MixiBatchRequest : MixiURLRequestConstructor {
@private
    /** \brief 複数のリクエスト */
    NSMutableArray *requests_;
}

@property (nonatomic, retain) NSMutableArray *requests;

/**
 * \brief リクエストを追加
 *
 * \param request リクエスト
 */
- (void)addRequest:(NSDictionary*)request;

/**
 * \brief リクエストをすべてクリア
 */
- (void)clearRequests;

@end
