/**
 * \file Mixi.h
 * \brief API呼び出しの土台になるクラスを定義します。
 *
 * Created by Platform Service Department on 11/06/29.
 * Copyright 2011 mixi Inc. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "MixiApiType.h"

@class MixiADBannerView;
@class MixiAuthorizer;
@class MixiConfig;
@class MixiReporter;
@class MixiRequest;
@class MixiViewController;
@class MixiURLRequestConstructor;
@protocol MixiDelegate;

/**
 * \brief SDKのメインクラス
 * 
 * APIのほとんどは本クラスを通じて実行されます。ただし、実行されるAPIの内容はパラメータとして受け取る<code>MixiRequest</code>で保持されています。
 *
 * \subsection ヘッダファイルの追加
 * 
 * SDKを利用する場合は次のヘッダファイルをインポートしてください。
 *
 * <code>#import "MixiSDK.h"</code>
 *
 * \section API呼び出し準備
 *
 * 本クラスはシングルトンクラスです。インスタンスは次のようにして取得できます。
 * 
 * <code>[Mixi sharedMixi]</code>
 *
 * ただし、APIを実行する前に一度シングルトンオブジェクトを初期化しておく必要があります。
 * 例えばGraph APIを使用する場合、
 * UIApplicationDelegate#application:didFinishLaunchingWithOptions:
 * メソッド内で次のように記述するといいでしょう。
 * （全ての引数はアプリケーションの設定に合わせて変更してください）
 *
 * <pre><code>Mixi *mixi = [[Mixi sharedMixi] setupWithType:kMixiApiTypeSelectorGraphApi 
 *                                     clientId:@"ab12c345de6789f12345" 
 *                                       secret:@"a1b2c3456d789ef0123ghi4567jklmn89op01qrs"
 *                                  redirectUrl:@"mixi-connect://success"];
 * [mixi restore];
 * [mixi reportOncePerDay];
 * </code></pre>
 *
 * mixiアプリの場合、 redirectUrl は不要です。
 * 
 * <pre><code>Mixi *mixi = [[Mixi sharedMixi] setupWithType:kMixiApiTypeSelectorMixiApp
 *                                     clientId:@"ab12c345de6789f12345" 
 *                                       secret:@"a1b2c3456d789ef0123ghi4567jklmn89op01qrs"];
 * [mixi restore];
 * [mixi reportOncePerDay];
 * </code></pre>
 *
 * なお、上記のMixi#reportOncePerDayはアプリの起動をmixiに通知するものです。
 * このコードの追記は任意ですが、サービスの改善のために協力していただけると幸いです。
 * アプリケーションの情報は一切送信されません。
 *
 * \sa MixiReporter#pingWithMixi:
 *
 * \subsection 認可

 * mixiアプリのAPIを利用するためには、ユーザにAPI利用のための認可を行なってもらう必要があります。そのための画面を表示するのが authorize: メソッドです。
 * 
 * <code>[mixi authorize:@"r_profile", @"w_diary", nil];</code>
 * 
 * このメソッドを呼び出すことで、ユーザーの認可を促す画面が表示されます。
 * 
 * デフォルトではmixi公式iPhoneアプリ（以下、公式アプリ）の有無によって認可画面の表示に異なるオブジェクトが利用されるため、公式アプリを使用した認可、およびSDK単体での認可に対応した2つの処理を記述してください。
 * 
 * \subsubsection 公式アプリを使用した認可
 * 
 * 端末に公式アプリがインストールされている場合は、認可／認可解除は公式アプリを利用して行われます。
 * 公式アプリを利用して認可するとログイン情報が公式アプリと共有されるため、公式アプリですでにログイン済みであればユーザーIDとパスワードの入力を省略できます。
 * 
 * 公式アプリから認可結果（アクセストークンなど）を受け取るために
 * UIApplicationDelegate#application:openURL:sourceApplication:annotation:
 * メソッドに次のような処理を追加してください。
 * 
 * <pre><code>NSError *error = nil;
 * NSString *apiType = [[Mixi sharedMixi] application:application openURL:url sourceApplication:sourceApplication annotation:annotation error:&error];
 * if (error) {
 *     // エラーが発生しました
 * }
 * else if ([apiType isEqualToString:kMixiAppApiTypeToken]) {
 *     // 認可処理に成功しました
 * }
 * else if ([apiType isEqualToString:kMixiAppApiTypeRevoke]) {
 *     // 認可解除処理に成功しました
 * }
 * else if ([apiType isEqualToString:kMixiAppApiTypeReceiveRequest]) {
 *     // リクエストAPIによるリクエスト受け取り
 * }
 * </code></pre>
 * 
 * \subsubsection SDK単体での認可
 * 
 * SDKの持つウェブビューコントローラを使用して認可画面を表示するには、そのビューコントローラの親になるビューコントローラを設定します。
 * 
 * APIを呼び出すビューコントローラのUIViewController#viewDidAppear:に次のようなコードを追加してください。（MixiAuthorizer#setParentViewControllerに設定する値は適宜変更してください）
 * 
 * <code><pre> - (void)viewDidAppear:(BOOL)animated
 * {
 *     [super viewDidAppear:animated];
 *     Mixi *mixi = [Mixi sharedMixi];
 *     mixi.authorizer.parentViewController = [self navigationController];
 * }
 * </pre></code>
 * 
 * 認可が完了するとその結果はSDK内に保持され、事前設定されたparentViewControllerに処理が戻されます。
 * 認可完了時にそれら以外の処理を実行する必要がある場合は認可オブジェクトにデリゲートを設定してください。
 * 
 * <code><pre> mixi.authorizer.delegte = [[YourDelegate alloc] init];
 * </pre></code>
 * 
 * \sa MixiSDKAuthorizerDelegate#authorizer:didSuccessWithEndpoint:
 * \sa MixiSDKAuthorizerDelegate#authorizer:didCancelWithEndpoint:
 * \sa MixiSDKAuthorizerDelegate#authorizer:didFailWithEndpoint:error:
 *
 * なお、認可画面のツールバーはデフォルトでは標準のくすんだ青色になっています。
 * アプリケーションのイメージカラーに合わせてツールバーの色を変更したい場合はtoolbarColorプロパティを設定してください。
 *
 * <code><pre> MixiMultiplexAuthorizer *authorizer = (MixiMultiplexAuthorizer*)mixi.authorizer;
 * authorizer.sdkAuthorizer.toolbarColor = [UIColor blackColor];
 * </pre></code>
 * 
 * \subsection 公式アプリの有無に関わらず認可手段を固定する
 * 
 * 認可手段を固定するには
 * UIApplicationDelegate#application:didFinishLaunchingWithOptions:
 * メソッド内で
 * Mixi#setupWithType:clientId:secret:
 * を呼び出した後に mixi.authorizer を直接設定してください。
 * 
 * \subsubsection 公式アプリを使用した認可に固定する
 * 
 * 認可に公式アプリを必ず使用するには次のように記述します。
 * （ただし、アプリケーションの実行に公式アプリが必須となってしまうためApple社の審査に通らない可能性があります）
 * 
 * <pre><code>mixi.authorizer = [MixiAppAuthorizer authorizer];</code></pre>
 * 
 * 公式アプリでの認可だけを使用する場合は先に説明したSDK単体認可用のコードは不要です。
 * 
 * \subsubsection SDK単体での認可に固定する
 * 
 * SDKの持つ認可画面を必ず使用するには次のように記述します。
 * （ただし、mixiアプリの場合は公式アプリがインストールされているときには必ずそちらを使用して認可を行うように実装してください）
 * 
 * <pre><code>mixi.authorizer = [MixiSDKAuthorizer authorizerWithRedirectUrl:mixi.config.redirectUrl];</code></pre>
 * 
 * 何らかの理由でmixiアプリでSDK単体での認可に固定したい場合はリダイレクトURLは設定しなくても構いません。
 * 
 * <pre><code>mixi.authorizer = [MixiSDKAuthorizer authorizer];</code></pre>
 * 
 * SDK単体での認可だけを使用する場合は先に説明した公式アプリを利用した認可用のコードは不要です。
 *
 * \section 友人一覧取得API呼び出し
 *
 * APIはエンドポイントとパラメーターを設定した<code>MixiRequest</code>インスタンスを、<code>Mixi#sendRequest:delegate:</code>メソッドに渡すことで実行します。
 * API実行前に認可が完了しているかどうかを確認して、未認可の場合は先に認可しておきます。認可に失敗した場合はmixi公式アプリがインストールされていないか、最新版ではない可能性があるので、必要に応じてAppStoreのmixi公式アプリダウンロードを提案する画面を開きます。
 *
 * <pre><code>if ([mixi isAuthorized]) {
 *     MixiRequest *request = [MixiRequest requestWithEndpoint:＠"/people/＠me/＠friends"];
 *     [mixi sendRequest:request delegate:mixiDelegate];
 * }
 * else if (![mixi authorizeForPermission:＠"r_profile"]) {
 *     MixiWebViewController *vc = MixiUtilDownloadViewController(self, @selector(closeDownloadView:));
 *     vc.orientationDelegate = self;
 *     [self presentModalViewController:vc animated:YES];
 * }
 * </code></pre>
 * 
 * 公式アプリダウンロード画面で「キャンセル」ボタンをクリックされた場合の処理はSDK利用者が自分で実装しなければいけません。
 * 上記の例であれば、呼び出し元のコントローラで次のようなメソッドを定義します。
 *
 * - (void)closeDownloadView:(id)sender {
 *     [self dismissModalViewControllerAnimated:YES];
 * }
 *
 * \section 画像付きボイス投稿API呼び出し
 *
 * パラメーター付きの<code>MixiRequest</code>は次のようにして作成できます。サンプルのとおり、<code>UIImage</code>インスタンスを渡すと画像を添付できます。
 *
 * <pre><code>if ([mixi isAuthorized]) {
 *     NSString *path = [[NSBundle mainBundle] pathForResource:＠"yoichiro" ofType:＠"png"];
 *     UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
 *     MixiRequest *request = [MixiRequest postRequestWithEndpoint:＠"/voice/statuses/update" 
 *                                                   paramsAndKeys:＠"こんにちはこんにちは", ＠"status",
 *                                                                 image, @"photo", nil];
 *     [mixi sendRequest:request delegate:mixiDelegate];
 * }
 * else if (![mixi authorizeForPermission:＠"w_voice"]) {
 *     MixiUtilShowErrorMessage(@"公式アプリが入っていないか古いです");
 * }
 * </code></pre>
 *
 * \section 日記投稿API呼び出し
 *
 * 複雑なオブジェクトは<code>NSMutableDictionary</code>インスタンスで指定します。
 *
 * <pre><code>if ([mixi isAuthorized]) {
 *     NSMutableDictionary *diary = [NSMutableDictionary dictionary];
 *     [diary setValue:@"今日のなんとか" forKey:＠"title"];
 *     [diary setValue:@"今日はあれとかこれとか" forKey:＠"body"];
 *     NSMutableDictionary *privacy = [NSMutableDictionary dictionary];
 *     [privacy setValue:@"self" forKey:＠"visibility"];
 *     [diary setValue:privacy forKey:@"privacy"];
 * 
 *     MixiRequest *request = [MixiRequest postRequestWithEndpoint:＠"/diary/articles/＠me/＠self" 
 *                                                   paramsAndKeys:diary, ＠"request", nil];
 *     [mixi sendRequest:request delegate:mixiDelegate];
 * }
 * else {
 *     [mixi authorizeForPermission:＠"w_diary"];
 * }
 * </code></pre>
 *
 * \section 写真投稿API呼び出し
 *
 * 画像オブジェクトをparamsプロパティの値に設定すると画像が一つしか指定されていない場合でもマルチパートで送信されます。
 * 写真投稿APIのように画像をリクエストボディに設定する必要がある場合は、bodyプロパティに画像オブジェクトを設定してください。
 * （なお、paramsとbodyを同時に指定した場合はリクエストボディはbodyプロパティの値になり、パラメーターはエンドポイントにクエリパラメーターとして追加されます）
 *
 * <pre><code>if ([mixi isAuthorized]) {
 *     NSString *path = [[NSBundle mainBundle] pathForResource:@"yoichiro" ofType:@"png"];
 *     UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
 *     MixiRequest *request = [MixiRequest postRequestWithEndpoint:@"/photo/mediaItems/@me/@self/123456"
 *                                                            body:image
 *                                                   paramsAndKeys:@"写真タイトル", @"title", nil];
 *     [mixi sendRequest:request delegate:self];
 * }
 * else {
 *     [mixi authorizeForPermission:@"w_photo"];
 * }
 * </code></pre>
 *
 * \section リクエストAPI呼び出し
 *
 * リクエストAPI呼び出しは確認ダイアログを表示するため、<code>buildViewControllerWithRequest:delegate:</code>メソッドを使用して呼び出します。
 * 
 * <pre><code>if ([mixi isAuthorized]) {
 *     NSString *message = ＠"こんにちはこんにちは";
 *     NSString *recipients = ＠"abcdefghijklm";
 *     NSString *url = ＠"http://mixi.jp/run_appli.pl?id=xxxxx";
 *     NSString *mobileUrl = ＠"http://ma.mixi.net/xxxxx/";
 *     NSString *image = ＠"http://profile.img.mixi.jp/photo/user/mlkjihgfedcba_12345678901.jpg,image/jpeg";
 *
 *     MixiRequest *request = [MixiRequest requestWithEndpoint:＠"/dialog/requests"
 *                                               paramsAndKeys:message, ＠"message",
 *                                                             recipients, ＠"recipients",
 *                                                             url, ＠"url",
 *                                                             mobileUrl, ＠"mobile_url",
 *                                                             image, ＠"image", 
 *                                                             nil];
 *     UIViewController *viewController = [mixi buildViewControllerWithRequest:request delegate:mixiDelegate];
 *     [self presentModalViewController:viewController animated:YES];
 * }
 * else {
 *     [mixi authorizeForPermission:＠"mixi_apps"];
 * }
 * </code></pre>
 *
 * \section リクエスト削除API呼び出し
 *
 * リクエストAPIで送信されたリクエストをアプリケーションで受け取った場合は、処理が完了したら明示的にリクエストを削除しなければいけません。
 * アプリケーションの起動に使用されたURLのクエリパラメータとしてリクエストIDが付加されています。
 * リクエストの処理完了後に、そのIDを利用してリクエストを削除してください。
 *
 * <pre><code>NSString *requestId = MixiUtilGetRequestIdFromURL(url);
 * MixiRequest *request = [MixiRequest deleteRequestWithEndpoint:@"/apps/requests/＠me/＠self" 
 *                                                 paramsAndKeys:requestId, ＠"requestIds", nil];
 * [[Mixi sharedMixi] sendRequest:request delegate:self];
 * </code></pre>
 *
 * \section APIの実行結果を処理
 *
 * API実行結果はsendメソッド群の引数に与えていた<code>MixiDelegate</code>プロトコルを実装したデリゲートで処理します。
 * 例えば、APIの実行結果をAlertViewで表示するには次のようなデリゲートメソッドを定義したクラスのインスタンスをsendメソッド群の引数に与えます。
 * 
 * <pre><code>- (void)mixi:(Mixi*)mixi didFinishLoading:(NSString*)data {
 *     MixiUtilShowMessageTitle(data, ＠"実行結果");
 * }
 * </code></pre>
 *
 * 上記以外のデリゲートメソッドについては<code>MixiDelegate</code>のドキュメントを参照してください。
 *
 * \section APIを同期呼び出し
 *
 * Mixi#sendSynchronousRequest:error: メソッドを使用してAPIを同期的に実行することもできます。
 * ただし、同期的に実行した場合、APIの呼び出しが完了するまでアプリケーションの動作が停止するため、どうしても必要な場合を除き、非同期呼び出しを使用してください。
 *
 * <pre><code>NSError *error = nil;
 * MixiRequest *request = [MixiRequest requestWithEndpoint:＠"/people/＠me/＠friends"];
 * NSDictionary *result = [mixi sendSynchronousRequest:request error:&error];
 * // 呼び出しが完了するまで停止します
 * if (error) {
 *     // エラー
 * }
 * else {
 *     NSArray *friends = [result objectForKey:＠"entry"];
 *     // 友人一覧を利用
 * }
 * </code></pre>
 *
 * \section API呼び出しをキャンセル
 *
 * Mixi#sendRequest:delegate メソッドは呼び出しの結果として NSURLConnection オブジェクトを返します。
 * リクエストをキャンセルする場合はこの NSURLConnection オブジェクトを使用してください。
 *
 * 例えばAPI呼び出しを0.5秒後にキャンセルする場合は次のようになります。
 *
 * <pre><code>Mixi *mixi = [Mixi sharedMixi];
 * MixiRequest *request = [MixiRequest requestWithEndpoint:＠"/people/＠me/＠friends"];
 * NSURLConnection *conn = [mixi sendRequest:request delegate:self];
 * [conn performSelector:＠selector(cancel) withObject:nil delay:0.5];
 * </code></pre>
 *
 * \section アクセストークンの自動リフレッシュを使用しない
 *
 * デフォルトの状態では、アクセストークンが期限切れの場合、自動的にリフレッシュされ新しいトークンを使用してAPIリクエストが実行されます。
 * ただしこのリフレッシュは同期的に行われます。
 * もし非同期にトークンをリフレッシュしたい場合は、次の例を参考にしてください。
 * （エラー処理などは省略しています）
 *
 * <pre><code>― (void)doMyRequest {
 *     Mixi *mixi = [Mixi sharedMixi];
 *     mixi.autoRefreshToken = NO;
 *     MixiRequest *request = [MixiRequest requestWithEndpoint:＠"/people/＠me/＠friends"];
 *     request.openMixiAppToAuthorizeIfNeeded = NO;
 *     [mixi sendRequest:request delegate:self];
 * }
 *
 * // トークンが期限切れの場合に非同期にリフレッシュ（API呼び出しの結果を処理しています）
 * ― (void)mixi:(Mixi*)mixi didFailWithError:(NSError*)error {
 *     if (error.code == kMixiTokenErrorExpired) {
 *         [mixi refreshAccessTokenWithDelegate:self];
 *     }
 * }
 *
 * // トークンリフレッシュに成功したのでトークンを保持してリクエストを再送（トークンリフレッシュの結果を処理しています）
 * ― (void)mixi:(Mixi*)mixi didSuccessWithJson:(NSDictionary*)data {
 *     [mixi setPropertiesFromDictionary:data];
 *     [self doMyRequest];
 * }
 * </code></pre>
 */
@interface Mixi : NSObject {
@private
    
    /** \brief SDKの設定 */
    MixiConfig *config_;
    
    /** パーミッション */
    NSArray *permissions_;
    
    /** \brief 自動的にアクセストークンをリフレッシュするかどうか。デフォルトはYES */
    BOOL autoRefreshToken_;
    
    /** \brief オープン中のViewController */
    MixiViewController *mixiViewController_;
    
    /** \brief 認可 */
    MixiAuthorizer *authorizer_;
    
    /** \brief UUレポーター */
    MixiReporter *uuReporter_;
    
    /** \brief mAPビュー */
    MixiADBannerView *adView_;
}

@property (nonatomic, retain) MixiConfig *config;
@property (nonatomic, readonly) NSArray *permissions;
@property (nonatomic, assign) BOOL autoRefreshToken;
@property (nonatomic, retain) MixiViewController *mixiViewController;
@property (nonatomic, retain) MixiAuthorizer *authorizer;
@property (nonatomic, retain) MixiReporter *uuReporter;

/**
 * \brief OAuthクライアントIDとシークレットを指定してインスタンスを初期化。APIタイプはGraphAPI。
 *
 * \param clientId OAuthコンシューマーキー
 * \param secret OAuthコンシューマーシークレット
 * \return 指定された値で設定されたMixiインスタンス
 */
- (id)setupWithClientId:(NSString*)clientId secret:(NSString*)secret;

/** \cond DEPRECATED */
/**
 * \brief OAuthクライアントIDとシークレットを指定してインスタンスを初期化。APIタイプはGraphAPI。
 *
 * \param clientId OAuthコンシューマーキー
 * \param secret OAuthコンシューマーシークレット
 * \param appId キーチェーンにアクセストークンを保存するために使用するApp ID
 * \return 指定された値で設定されたMixiインスタンス
 */
- (id)setupWithClientId:(NSString*)clientId secret:(NSString*)secret appId:(NSString*)appId;
/** \endcond */

/**
 * \brief タイプとOAuthクライアントIDとシークレットを指定してインスタンスを初期化
 *
 * \param type kMixiApiTypeSelectorMixiAppまたはkMixiApiTypeSelectorGraphApi
 * \param clientId OAuthコンシューマーキー
 * \param secret OAuthコンシューマーシークレット
 * \return 指定された値で設定されたMixiインスタンス
 */
- (id)setupWithType:(MixiApiType)type clientId:(NSString*)clientId secret:(NSString*)secret;

/** \cond DEPRECATED */
/**
 * \brief タイプとOAuthクライアントIDとシークレットを指定してインスタンスを初期化
 *
 * \param type kMixiApiTypeSelectorMixiAppまたはkMixiApiTypeSelectorGraphApi
 * \param clientId OAuthコンシューマーキー
 * \param secret OAuthコンシューマーシークレット
 * \param appId キーチェーンにアクセストークンを保存するために使用するApp ID
 * \return 指定された値で設定されたMixiインスタンス
 */
- (id)setupWithType:(MixiApiType)type clientId:(NSString*)clientId secret:(NSString*)secret appId:(NSString*)appId;
/** \endcond */

/**
 * \brief タイプとOAuthクライアントIDとシークレットとリダイレクトURLを指定してインスタンスを初期化
 *
 * \param type kMixiApiTypeSelectorMixiAppまたはkMixiApiTypeSelectorGraphApi
 * \param clientId OAuthコンシューマーキー
 * \param secret OAuthコンシューマーシークレット
 * \param redirectUrl リダイレクトURL
 * \return 指定された値で設定されたMixiインスタンス
 */
- (id)setupWithType:(MixiApiType)type clientId:(NSString*)clientId secret:(NSString*)secret redirectUrl:(NSString*)redirectUrl;

/**
 * \brief 設定を指定してインスタンスを初期化
 *
 * \param config 設定
 * \return 指定された値で設定されたMixiインスタンス
 */
- (id)setupWithConfig:(MixiConfig*)config;

/**
 * \brief UUカウントのためにpingを実行
 *
 * 複数回送信されたとしても一日に一度しかカウントされません。
 */
- (void)reportOncePerDay;

/**
 * \brief 共有されたインスタンスを取得
 *
 * \return 共有されたインスタンス
 */
+ (Mixi*)sharedMixi;

/**
 * \brief 辞書オブジェクトでプロパティをまとめて設定
 *
 * \param dict 有効なキーは"access_token"、"refresh_token"、"expires_in"、"state"
 */
- (void)setPropertiesFromDictionary:(NSDictionary*)dict;

/**
 * \brief 公式アプリからの戻り値を処理
 *
 * アプリケーションのURLスキームで呼び出された場合を処理するためのユーテリィティメソッドです。
 * UIApplicationDelegate#application:openURL:sourceApplication:annotation
 * 内で呼び出してください。
 * 独自の制御が必要な場合は当メソッドの実装をアプリケーションデリゲートの同名メソッドにコピーして自由に修正して構いません。
 *
 * \param application 呼び出されたアプリケーション
 * \param url 呼び出しに使用されたURL
 * \param sourceApplication 呼び出し元アプリケーション
 * \param annotation 付加情報
 * \param error エラー
 * \return 実行されたAPIの種類。認可:kMixiAppApiTypeToken（"token"）。認可解除:kMixiAppApiTypeRevoke（"revoke"）。
 */
- (NSString*)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation error:(NSError**)error;

/**
 * \brief mixi公式iPhoneアプリがインストールされているかどうか
 *
 * \return mixi公式iPhoneアプリがインストールされているかどうか
 */
- (BOOL)isMixiAppInstalled;

/**
 * \brief SDK単体で認可を実行しているかどうか
 *
 * \return SDK単体で認可を実行しているかどうか 
 */
- (BOOL)isUsingSDKAuthorizer;

/**
 * \brief mixi公式iPhoneアプリで認可を実行しているかどうか
 *
 * \return mixi公式iPhoneアプリで認可を実行しているかどうか 
 */
- (BOOL)isUsingAppAuthorizer;

/**
 * \brief アクセストークンを取得済みかどうか
 * 
 * \return アクセストークンを取得済みかどうか
 */
- (BOOL)isAuthorized;

/**
 * \brief アクセストークンが期限切れかどうか
 * 
 * \return アクセストークンが期限切れかどうか
 */
- (BOOL)isAccessTokenExpired;

/**
 * \brief リフレッシュトークンが期限切れかどうか
 * 
 * \return リフレッシュトークンが期限切れかどうか
 */
- (BOOL)isRefreshTokenExpired;

/**
 * \brief リフレッシュトークンを使用してアクセストークンを同期的にリフレッシュ
 * 
 * \return 成功したらYES、そうでなければNOを返します
 */
- (BOOL)refreshAccessToken;

/**
 * \brief リフレッシュトークンを使用してアクセストークンを同期的にリフレッシュ
 *
 * \param error エラー
 * \return 成功したらYES、そうでなければNOを返します
 */
- (BOOL)refreshAccessTokenWithError:(NSError**)error;

/**
 * リフレッシュトークンを使用してアクセストークンを非同期にリフレッシュ
 * 
 * \param delegate 結果を受け取るデリゲート
 * \return コネクション。nilの場合は接続に失敗しています。
 */
- (NSURLConnection*)refreshAccessTokenWithDelegate:(id<MixiDelegate>)delegate;

/**
 * \brief 公式アプリを呼び出して認証を実行
 *
 * \param permission 要求するパーミッション。可変長。最後の引数は必ずnilにすること
 * \return 公式アプリの起動に成功したらYESを返します。公式アプリが古いか、インストールされていない場合にはNOを返します。
 */
- (BOOL)authorize:(NSString*)permission, ...;

/**
 * \brief 公式アプリを呼び出して認証を実行
 *
 * \param permission 要求するパーミッション
 * \return 公式アプリの起動に成功したらYESを返します。公式アプリが古いか、インストールされていない場合にはNOを返します。
 */
- (BOOL)authorizeForPermission:(NSString*)permission;

/**
 * \brief 公式アプリを呼び出して認証を実行
 *
 * \param permissions 要求するパーミッション
 * \return 公式アプリの起動に成功したらYESを返します。公式アプリが古いか、インストールされていない場合にはNOを返します。
 */
- (BOOL)authorizeForPermissions:(NSArray*)permissions;

/**
 * \brief ログアウト
 *
 * SDKが端末上に保持している情報をクリアします。
 */
- (void)logout;

/**
 * \brief 認可状態を解除
 *
 * \return 認可解除呼び出しに成功したらYESを返します。公式アプリ経由で処理を実行する場合はYESを返しても解除が成功しているとは限りません。
 */
- (BOOL)revoke;

/**
 * \brief 認可状態を解除
 *
 * \param error エラー
 * \return 認可解除呼び出しに成功したらYESを返します。公式アプリ経由で処理を実行する場合はYESを返しても解除が成功しているとは限りません。
 */
- (BOOL)revokeWithError:(NSError**)error;

/**
 * \brief 認可状態を解除してログアウト
 *
 * SDKが端末上に保持している情報をクリアした後でサーバー上の認可状態を解除します。
 *
 * \return 認可解除呼び出しに成功したらYESを返します。公式アプリ経由で処理を実行する場合はYESを返しても解除が成功しているとは限りません。
 */
- (BOOL)revokeAndLogout;

/** \cond DEPRECATED */
/**
 * \brief 認可状態を解除してログアウト
 *
 * SDKが端末上に保持している情報をクリアした後でサーバー上の認可状態を解除します。
 *
 * \return 認可解除呼び出しに成功したらYESを返します。公式アプリ経由で処理を実行する場合はYESを返しても解除が成功しているとは限りません。
 */
- (BOOL)logoutAndRevoke;
/** \endcond */

/**
 * \brief 認可状態を解除してログアウト
 *
 * \param error エラー
 * \return 認可解除呼び出しに成功したらYESを返します。公式アプリ経由で処理を実行する場合はYESを返しても解除が成功しているとは限りません。
 */
- (BOOL)revokeAndLogoutWithError:(NSError**)error;

/** \cond DEPRECATED */
/**
 * \brief 認可状態を解除してログアウト
 *
 * \param error エラー
 * \return 認可解除呼び出しに成功したらYESを返します。公式アプリ経由で処理を実行する場合はYESを返しても解除が成功しているとは限りません。
 */
- (BOOL)logoutAndRevokeWithError:(NSError**)error;
/** \endcond */

/**
 * \brief 公式アプリからの戻りURLからaccess token、refresh tokenなどを抽出.
 *
 * \param url アプリ起動に使用されたURL
 * \param sourceApplication 呼び出し元アプリケーション。現在未使用。将来的に検証に使用したい。
 * \param error エラー
 * \return トークン
 */
- (NSString*)retrieveTokensFromURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication error:(NSError**)error;

/**
 * \brief 公式アプリの戻りURLからエラーを抽出
 *
 * エラーコードは次の通り。
 *  - kMixiAuthErrorConnectionFailed 公式アプリで接続エラーでログイン画面を開けない場合
 *  - kMixiAuthErrorOAuthFailed 公式アプリで認証エラーでログイン画面を開けない場合
 *  - kMixiAuthErrorInvalidOAuthParameters 公式アプリでOAuth不正パラメータでログイン画面を開けない場合
 *
 * \param url アプリ起動に使用されたURL
 * \return エラー
 */
- (NSError*)retrieveErrorFromURL:(NSURL*)url;

/**
 * \brief インスタンスの情報を保持
 */
- (void)store;

/**
 * \brief インスタンスの情報を復帰
 *
 * \return 成功したらYES、そうでなければNOを返します
 */
- (BOOL)restore;

/**
 * \brief APIを実行（非同期）
 *
 * アクセストークンの自動更新があり、処理がやや込み入っているので以下に簡単に説明します。
 * アクセストークンの更新に関係するものは次の5つです。
 *
 * - 引数forceの値
 * - アクセストークンの期限
 * - リフレッシュトークンの期限
 * - autoRefreshTokenプロパティの値
 * - MixiRequest#openMixiAppToAuthorizeIfNeededの値
 *
 * それらを次の順でチェックしてAPIを呼び出します。
 *
 * -# 引数forceがYESの場合にはアクセストークンの期限を無視して強制的にAPIを実行します。
 * -# forceがNOの場合にアクセストークンが期限切れなら、リフレッシュトークンの期限を確認します。
 * -# リフレッシュトークンの期限が切れていた場合はトークンをリフレッシュできないので8.に進みます。
 * -# リフレッシュトークンが有効なら、プロパティautoRefreshTokenの値を確認します。
 * -# autoRefreshTokenがNOの場合はトークンをリフレッシュしないので8.に進みます。
 * -# autoRefreshTokenがYESの場合はトークンをリフレッシュします。
 * -# トークンのリフレッシュに成功したら、そのトークンを使用してAPIを実行します。
 * -# トークンのリフレッシュに失敗したら、MixiRequest#openMixiAppToAuthorizeIfNeededの値を確認します。
 * -# openMixiAppToAuthorizeIfNeededがYESの場合は、公式アプリの認可画面を開きます。
 * -# openMixiAppToAuthorizeIfNeededがNOの場合は、エラーを返します。
 *
 * \param request リクエスト
 * \param delegate リクエスト結果を処理するデリゲート
 * \param forced アクセストークンの期限切れを気にせずとにかく実行するか、そうではないか
 * \return コネクション。nilの場合は接続に失敗しています。
 */
- (NSURLConnection*)sendRequest:(MixiURLRequestConstructor*)request delegate:(id<MixiDelegate>)delegate forced:(BOOL)forced;

/**
 * \brief APIを実行（非同期）
 *
 * アクセストークンのリフレッシュが必要な場合は、リフレッシュしてからAPIを実行します。
 *
 * \param request リクエスト
 * \param delegate リクエスト結果を処理するデリゲート
 * \return コネクション。nilの場合は接続に失敗しています。
 */
- (NSURLConnection*)sendRequest:(MixiURLRequestConstructor*)request delegate:(id<MixiDelegate>)delegate;

/**
 * \brief APIを実行して結果を文字列で取得（同期）
 *
 * （リダイレクト先で結果を返すAPIがあるため）リダイレクトされた場合は、リダイレクト先を返します。
 *
 * \param request リクエスト
 * \param error　エラー
 * \return リクエスト結果
 */
- (NSString*)rawSendSynchronousRequest:(MixiURLRequestConstructor*)request error:(NSError**)error;

/**
 * \brief APIを実行して結果を辞書型で取得（同期）
 *
 * \param request リクエスト
 * \param error　エラー
 * \return リクエスト結果
 */
- (NSDictionary*)sendSynchronousRequest:(MixiURLRequestConstructor*)request error:(NSError**)error;

/**
 * \brief 画面を伴うAPIを実行するための画面を取得
 *
 * \param request リクエスト
 * \param delegate リクエスト結果を処理するデリゲート 
 * \return APIを実行する画面のコントローラー
 */
- (MixiViewController*)buildViewControllerWithRequest:(MixiRequest*)request delegate:(id<MixiDelegate>)delegate;

@end
