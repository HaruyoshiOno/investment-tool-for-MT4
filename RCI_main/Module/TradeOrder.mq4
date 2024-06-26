//+------------------------------------------------------------------+
//|                                                   TradeOrder.mq4 |
//+------------------------------------------------------------------+
#property strict // strictは絶対に削除しない事

// ヘッダインクルード
#include <stdlib.mqh>          // ライブラリインクルード
#include  "../MagicNo.mqh"     // マジックナンバーインクルード

//マクロ定義
//#define  MAGIC_NO       20240119                   //EA識別用マジックナンバー(他EAと被らない任意の値)

//静的グローバル変数
static double _MinLot = 0.01;                        //最小ロット

//+------------------------------------------------------------------+
//| 初期化処理
//+------------------------------------------------------------------+
int Init_TradeOrder()
{


    return( INIT_SUCCEEDED );      // 戻り値：初期化成功
}

//+------------------------------------------------------------------+
//| アンロード処理
//+------------------------------------------------------------------+
void Deinit_TradeOrder( const int reason ) {


}

//+------------------------------------------------------------------+
//| 新規エントリー                                                        |
//+------------------------------------------------------------------+
bool EA_EntryOrder(
  bool in_long // true:Long false:short
){
  bool   ret         = false;  //戻り値
  int    order_type  = OP_BUY; //注文タイプ
  double order_lot   = _MinLot * Lots;//ロット
  double order_rate  = Ask;    //オーダープライスレート
  
  if(in_long == true){     //Longエントリー
    order_type = OP_BUY;
    order_rate = Ask;
  } else{                  //Shortエントリー
    order_type = OP_SELL;
    order_rate = Bid;
  }
  
  int ea_ticket_res = -1; //チケットNo
  
  ea_ticket_res = OrderSend(              //新規エントリー注文
                            Symbol(),     //通貨ペア
                            order_type,   //オーダータイプ[OP_BUY / OP_SELL]
                            order_lot,    //ロット[0.01単位]
                            order_rate,   //オーダープライスレート
                            100,          //スリップ上限(int)[分解能 0.1pips]
                            0,            //ストップレート
                            0,            //リミットレート
                            "RCI判定EA",  //オーダーコメント
                            MAGIC_NO      //マジックナンバー(識別用)
                           );
  
  if(ea_ticket_res != -1) { //オーダー正常完了
      ret = true;   
  } else {                       // オーダーエラーの場合

        int    get_error_code   = GetLastError();                   // エラーコード取得
        string error_detail_str = ErrorDescription(get_error_code); // エラー詳細取得

        // エラーログ出力
        printf( "[%d]エントリーオーダーエラー。 エラーコード=%d エラー内容=%s" 
            , __LINE__ ,  get_error_code , error_detail_str
         );        
    }
   return ret;
 }

//+------------------------------------------------------------------+
//| 注文決済
//+------------------------------------------------------------------+
bool EA_Close_Order( int in_ticket ){

    bool select_bool;                // ポジション選択結果
    bool ret = false;                // 結果

    // ポジションを選択
    select_bool = OrderSelect(
                    in_ticket ,      // チケットNo
                    SELECT_BY_TICKET // チケット指定で注文選択
                ); 

    // ポジション選択失敗時
    if ( select_bool == false ) {
        printf( "[%d]不明なチケットNo = %d" , __LINE__ , in_ticket);
        return ret;    // 処理終了
    }

    // ポジションがクローズ済みの場合
    if ( OrderCloseTime() > 0 ) {
        printf( "[%d]ポジションクローズ済み チケットNo = %d" , __LINE__ , in_ticket );
        return true;   // 処理終了
    }

    bool   close_bool;                  // 注文結果
    int    get_order_type;               // エントリー方向
    double close_rate = 0 ;              // 決済価格
    double close_lot  = 0;               // 決済数量

    get_order_type = OrderType();        // 注文タイプ取得
    close_lot      = OrderLots();        // ロット数


    if ( get_order_type == OP_BUY ) {            // 買いの場合
        close_rate = Bid;

    } else if ( get_order_type == OP_SELL ) {    // 売りの場合
        close_rate = Ask;

    } else {                                      // エントリー指値注文の場合
        return ret;                              // 処理終了
    }

    close_bool = OrderClose(              // 決済オーダー
                    in_ticket,              // チケットNo
                    close_lot,              // ロット数
                    close_rate,             // クローズ価格
                    20,                     // スリップ上限    (int)[分解能 0.1pips]
                    clrWhite              // 色
                  );

    if ( close_bool == false) {    // 失敗

        int    get_error_code   = GetLastError();                   // エラーコード取得
        string error_detail_str = ErrorDescription(get_error_code); // エラー詳細取得

        // エラーログ出力
        printf( "[%d]決済オーダーエラー。 エラーコード=%d エラー内容=%s" 
            , __LINE__ ,  get_error_code , error_detail_str
         );        
    } else {
        ret = true; // 戻り値設定：成功
    }

    return ret; // 戻り値を返す

}

//+------------------------------------------------------------------+
//| 注文変更
//+------------------------------------------------------------------+
bool EA_Modify_Order( int in_ticket ){

    bool ret = false;                // 戻り値
    bool select_bool;                // ポジション選択結果

    // ポジションを選択
    select_bool = OrderSelect(
                    in_ticket ,      // チケットNo
                    SELECT_BY_TICKET // チケット指定で注文選択
                ); 

    // ポジション選択失敗時
    if ( select_bool == false ) {
        return ret;    // 処理終了
    }

    bool   modify_bool;                  // 注文変更結果
    int    get_order_type;               // エントリー方向
    double set_limit_rate = 0 ;          // リミット価格
    double set_stop_rate = 0 ;          // ストップ価格
    double entry_rate;                   // エントリー価格
    //double limit_offset;                 // リミット用オフセット価格
    //double stop_offset;                  // ストップ用オフセット価格


    entry_rate     = OrderOpenPrice();   // エントリー価格取得
    get_order_type = OrderType();        // 注文タイプ取得

    //limit_offset     = entry_rate * 0.2; // リミットオフセット設定
    //stop_offset      = entry_rate * 0.1; // ストップオフセット設定

    if ( get_order_type == OP_BUY ) {            // 買いの場合
        set_limit_rate = entry_rate + limit_offset; // リミット価格設定
        set_stop_rate  = entry_rate - stop_offset;  // ストップ価格設定

    } else if ( get_order_type == OP_SELL ) {    // 売りの場合
    
        set_limit_rate = entry_rate - limit_offset; // リミット価格設定
        set_stop_rate  = entry_rate + stop_offset;  // ストップ価格設定
        
    } else {                                      // エントリー指値注文の場合
        return ret;                              // 処理終了
    }
    
    set_limit_rate = NormalizeDouble(set_limit_rate, Digits);  //リミットレートを正規化
    set_stop_rate  = NormalizeDouble(set_stop_rate,  Digits);  //ストップレートを正規化

    double limit_diff;                  // リミット価格差
    double stop_diff;                  // ストップ価格差
    limit_diff = MathAbs( set_limit_rate - OrderTakeProfit() );
    stop_diff = MathAbs( set_stop_rate   - OrderStopLoss() );

    if ( limit_diff < Point() && stop_diff < Point() ) {       // 0.1pips未満の変化の場合
        return ret;                      // 処理終了
    }

    modify_bool = OrderModify(            // オーダー変更
                        in_ticket,        // チケットNo
                        0,                // エントリー価格(保留中の注文のみ)
                        set_stop_rate,    // ストップロス
                        set_limit_rate,   // リミット
                        0,                // 有効期限
                        clrYellow         // ストップリミットラインの色
                  );

    if ( modify_bool == false) {    // 変更失敗

        int    get_error_code   = GetLastError();                   // エラーコード取得
        string error_detail_str = ErrorDescription(get_error_code); // エラー詳細取得

        // エラーログ出力
        printf( "[%d]オーダー変更エラー。 エラーコード=%d エラー内容=%s" 
            , __LINE__ ,  get_error_code , error_detail_str
         );        
    } else {
        // 変更成功
        ret = true;
    }

    return ret;    // 戻り値を返す
}