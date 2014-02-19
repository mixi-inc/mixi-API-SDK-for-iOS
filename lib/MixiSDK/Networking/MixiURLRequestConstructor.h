/**
 * \file MixiURLRequestConstructor.h
 * \brief API呼び出しに必要な情報を保持するクラスの親クラスです。
 *
 * Created by Platform Service Department on 11/06/30.
 * Copyright (c) 2013 mixi Inc. All rights reserved.
 */

#import <Foundation/Foundation.h>

@class Mixi;

/**
 * \brief API呼び出しに必要な情報を保持するクラスの親クラス
 */
@interface MixiURLRequestConstructor : NSObject {
    /** \brief エンドポイント */
    NSString *endpoint_;
    
    /** \brief エンドポイントのベースURL */
    NSString *endpointBaseUrl_;

    /**
     * \brief リクエスト送信時にアクセストークンがなかった場合、公式アプリを開くかどうか
     * デフォルトはYES。UU集計APIなど公式アプリに遷移すると困る場合にはNOにしておきます。
     */
    BOOL openMixiAppToAuthorizeIfNeeded_;
}

@property (nonatomic, copy) NSString *endpoint;
@property (nonatomic, copy) NSString *endpointBaseUrl;
@property (nonatomic, assign) BOOL openMixiAppToAuthorizeIfNeeded;

/**
 * \brief エンドポイントを指定してリクエストを初期化
 *
 * \param endpoint APIエンドポイント
 * \return MixiRequestインスタンス
 */
- (id)initWithEndpoint:(NSString*)endpoint;

/**
 * \brief 自身の情報からNSURLConnectionで実際に送信するためのURLリクエストを作成
 *
 * \param mixi mixiオブジェクト
 * \return URLリクエスト
 */
- (NSURLRequest*)constructURLRequest:(Mixi*)mixi;

@end
