//+------------------------------------------------------------------+
//|                                             TestMACross_main.mq4 |
//|                                                        Haruyoshi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict

//+------------------------------------------------------------------+
//| 変数定義                                                           |
//+------------------------------------------------------------------+
input double Lots         = *;
input double limit_offset = *;                  // リミット用オフセット価格
input double stop_offset  = *;                  // ストップ用オフセット価格

double get_value_rci_s;
double get_value_rci_m;
double get_value_rci_l;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //if ( IsDemo() == false ) {                         // デモ口座以外の場合
    //    Print("デモ口座でのみ動作します");
    //    return INIT_FAILED;                            // 処理終了
    //}

    // モジュールの初期化処理
    Init_DispObject();
    Init_JudgeTrade();
    Init_TradeOrder();

    return( INIT_SUCCEEDED );      // 戻り値：初期化成功
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //モジュールのアンロード処理
   Deinit_DispObject(reason);
   Deinit_JudgeTrade(reason);
   Deinit_TradeOrder(reason);
  }
//+------------------------------------------------------------------+
//| tick受信イベント
//| EA専用のイベント関数
//+------------------------------------------------------------------+
void OnTick()
{

    get_value_rci_s = CalRCI(Close, _InputCalPeriod_S, 0);
    get_value_rci_m = CalRCI(Close, _InputCalPeriod_M, 0);
    get_value_rci_l = CalRCI(Close, _InputCalPeriod_L, 0);
    TaskPeriod();                   // ローソク足確定時の処理
    TaskSetMinPeriod();             // 指定時間足確定時の処理
    JUDGE_TRADE_MAIN();             // トレード判定
    DispDebugInfo(_StPositionInfoData);                   //デバッグ情報出力

}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ローソク足確定時の処理
//+------------------------------------------------------------------+
void TaskPeriod() {
    static    datetime s_lasttime;                      // 最後に記録した時間軸時間
                                                        // staticはこの関数が終了してもデータは保持される

    datetime temptime    = iTime( Symbol(), Period() ,0 );  // 現在の時間軸の時間取得

    if ( temptime == s_lasttime ) {                     // 時間に変化が無い場合
        return;                                         // 処理終了
    }
    s_lasttime = temptime;                              // 最後に記録した時間軸時間を保存

    // ----- 処理はこれ以降に追加 -----------
   
    //printf( "[%d]ローソク足確定%s" , __LINE__ , TimeToStr( Time[0] ));
}

//+------------------------------------------------------------------+
//| 指定時間足確定時の処理
//+------------------------------------------------------------------+
void TaskSetMinPeriod() {
    static    datetime s_lastset_mintime;                        // 最後に記録した時間軸時間
                                                                 // staticはこの関数が終了してもデータは保持される

    datetime temptime    = iTime( Symbol(), PERIOD_M1 ,0 );     // 現在の時間軸の時間取得

    if ( temptime == s_lastset_mintime ) {                       // 時間に変化が無い場合
        return;                                                  // 処理終了
    }
    s_lastset_mintime = temptime;                                // 最後に記録した時間軸時間を保存

    // ----- 処理はこれ以降に追加 -----------
    ClearPosiInfo(_StPositionInfoData);                          // ポジション情報クリア(決済済みの場合)
    JudgeLimitStop(_StPositionInfoData);                         // リミット・ストップ判定処理

    // printf( "[%d]指定時間足確定%s" , __LINE__ , TimeToStr( Time[0] ) );

}
