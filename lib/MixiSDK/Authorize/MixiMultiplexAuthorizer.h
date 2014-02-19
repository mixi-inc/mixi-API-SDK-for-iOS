/**
 * \file MixiMultiplexAuthorizer.h
 * \brief 認可処理を実行するクラスのプロキシクラスを定義します。
 *
 * Created by Platform Service Department on 12/06/13.
 * Copyright 2012 mixi Inc. All rights reserved.
 */

#import "MixiAuthorizer.h"

@class MixiAppAuthorizer;
@class MixiSDKAuthorizer;

/** \brief どの認可オブジェクトを使用するか */
typedef enum _MixiMultiplexAuthorizerType {
    /** \brief 公式アプリの有無で切り替え */
    kMixiMultiplexAuthorizerAuto,

    /** \brief mixi公式iPhoneアプリ使用 */
    kMixiMultiplexAuthorizerApp,

    /** \brief SDK付属の認可画面を使用 */
    kMixiMultiplexAuthorizerSDK,
} MixiMultiplexAuthrorizerType;

/**
 * \brief mixi公式iPhoneアプリがインストールされているかどうかで認可処理を担当するオブジェクトを切り替えるクラス。iOS7以降ではSDK付属の認可画面を使用します。
 */
@interface MixiMultiplexAuthorizer : MixiAuthorizer {
    /** \brief mixi公式iPhoneアプリを使用するAuthorizer */
    MixiAppAuthorizer *appAuthorizer_;
    
    /** \brief SDK付属の認可画面を使用するAuthorizer */
    MixiSDKAuthorizer *sdkAuthorizer_;
    
    /** \brief どの認可オブジェクトを使用するか */
    MixiMultiplexAuthrorizerType authorizerType_;
}

@property (nonatomic, retain) MixiAppAuthorizer *appAuthorizer;
@property (nonatomic, retain) MixiSDKAuthorizer *sdkAuthorizer;

/**
 * \brief インスタンスを取得
 *
 * \return インスタンス
 */
+ (id)authorizer;

/**
 * \brief sdkAuthorizerの親ビューコントローラを指定してインスタンスを取得
 *
 * \param parentViewController 認可画面を表示するウェブビューコントローラの親ビューコントローラ
 * \return インスタンス
 */
+ (id)authorizerWithParentViewController:(UIViewController*)parentViewController;

/**
 * \brief sdkAuthorizerのリダイレクトURLを指定してインスタンスを取得
 *
 * \param redirectUrl sap.mixi.jpでアプリケーションに設定したリダイレクトURL
 * \return インスタンス
 */
+ (id)authorizerWithRedirectUrl:(NSString*)redirectUrl;

/**
 * \brief sdkAuthorizerのリダイレクトURLと親ビューコントローラを指定してインスタンスを取得
 *
 * \param redirectUrl sap.mixi.jpでアプリケーションに設定したリダイレクトURL
 * \param parentViewController 認可画面を表示するウェブビューコントローラの親ビューコントローラ
 * \return インスタンス
 */
+ (id)authorizerWithRedirectUrl:(NSString*)redirectUrl parentViewController:(UIViewController*)parentViewController;

/**
 * \brief 初期化
 *
 * \return インスタンス
 */
- (id)init;

/**
 * \brief sdkAuthorizerの親ビューコントローラを指定して初期化
 *
 * \param parentViewController 認可画面を表示するウェブビューコントローラの親ビューコントローラ
 * \return インスタンス
 */
- (id)initWithParentViewController:(UIViewController*)parentViewController;

/**
 * \brief sdkAuthorizerのリダイレクトURLを指定して初期化
 *
 * \param redirectUrl sap.mixi.jpでアプリケーションに設定したリダイレクトURL
 * \return インスタンス
 */
- (id)initWithRedirectUrl:(NSString*)redirectUrl;

/**
 * \brief sdkAuthorizerのリダイレクトURLと親ビューコントローラを指定して初期化
 *
 * \param redirectUrl sap.mixi.jpでアプリケーションに設定したリダイレクトURL
 * \param parentViewController 認可画面を表示するウェブビューコントローラの親ビューコントローラ
 * \return インスタンス
 */
- (id)initWithRedirectUrl:(NSString*)redirectUrl parentViewController:(UIViewController*)parentViewController;

/**
 * \brief 必ずmixi公式iPhoneアプリを使用して認可する
 */
- (void)shouldUseAppAuthorizer;

/**
 * \brief 必ずSDKの認証画面を使用して認可する
 */
- (void)shouldUseSDKAuthorizer;

/**
 * \brief mixi公式iPhoneアプリの有無に応じて認可オブジェクトを切り替えて使用する
 */
- (void)shouldChooseAuthorizer;
@end
