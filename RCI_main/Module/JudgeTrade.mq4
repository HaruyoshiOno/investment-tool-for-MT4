//+------------------------------------------------------------------+
//|                                                   JudgeTrade.mq4 |
//+------------------------------------------------------------------+
#property strict // strictは絶対に削除しない事

// ヘッダインクルード
#include  "../MagicNo.mqh"     // マジックナンバーインクルード

//________型宣言_________________________________________________
struct struct_PositionInfo {     //ポジション情報構造体型
   int         ticket_no;        //チケットNo
   int         entry_dir;        //エントリーオーダータイプ
   double      set_limit;        //リミットレート
   double      set_stop;         //ストップレート
};

//enum列挙型宣言
enum ENUM_IND_SIGNAL {    //移動平均クロス列挙
   IND_NO = 0,          //無し
   IND_UP_CHANGE_L,       //長期RCIインジケーター上抜け
   IND_UP_CHANGE_M,       //中期RCIインジケーター上抜け
   IND_DOWN_CHANGE_L,      //長期インジケーター下抜け
   IND_DOWN_CHANGE_M      //中期インジケーター下抜け
};

//静的グローバル変数
static struct_PositionInfo _StPositionInfoData;    //ポジション情報構造体データ

//+------------------------------------------------------------------+
//| 初期化処理
//+------------------------------------------------------------------+
int Init_JudgeTrade()
{


    return( INIT_SUCCEEDED );      // 戻り値：初期化成功
}

//+------------------------------------------------------------------+
//| アンロード処理
//+------------------------------------------------------------------+
void Deinit_JudgeTrade( const int reason ) {


}

//+------------------------------------------------------------------+

void JUDGE_TRADE_MAIN(void)
{

//+------------------------------------------------------------------+
//| 任意の指標の判定                                                 |
//+------------------------------------------------------------------+
   ENUM_IND_SIGNAL ret = IND_NO;
   
  if(         get_value_rci_l > * && get_value_rci_m > * && get_value_rci_s > *
  ){
   ret = IND_UP_CHANGE_L;
  }
  else if(    get_value_rci_m > *
  ){
   ret = IND_UP_CHANGE_M;
  }else if(   get_value_rci_l < * && get_value_rci_m < * && get_value_rci_s < *
  ){
   ret = IND_DOWN_CHANGE_L;
  }else if(   get_value_rci_m < *
  ){
   ret = IND_DOWN_CHANGE_M;
  }
  
//  if(ret == IND_UP_CHANGE || ret == IND_DOWN_CHANGE){
//   TestDispObject(1);//テスト用オブジェクトを描画
//  }

//+------------------------------------------------------------------+
//| エントリーオーダー判定   　　　                                             |
//+------------------------------------------------------------------+
   bool entry_bool = false;   //エントリー判定
   bool entry_long = false;   //ロングエントリー判定
   
   if(ret == IND_DOWN_CHANGE_L){          //RCIが-90でBUYエントリー
      entry_bool = true;
      entry_long = true;
   } else if(ret == IND_UP_CHANGE_L){   //RCIが90でSELLエントリー
      entry_bool = true;
      entry_long = false;
   }
   
   GetPosiInfo(_StPositionInfoData);            //ポジション情報を取得
   
   if(_StPositionInfoData.ticket_no > 0){       //ポジション保有中の場合
      entry_bool = false;                       //エントリー禁止
   }
   
   if(entry_bool == true){
      EA_EntryOrder(entry_long);                //新規エントリー
   }

//+------------------------------------------------------------------+
//| 決済オーダー判定　　　　　　　　　                                            |
//+------------------------------------------------------------------+
   bool close_bool = false;   //決済判定
   
   if(_StPositionInfoData.ticket_no > 0){                   //ポジション保有中の場合
      if(_StPositionInfoData.entry_dir == OP_SELL){         //売りポジ保有中の場合
         if(ret == IND_DOWN_CHANGE_M){                          //インジケーター上抜け
            close_bool = true;
         }
      }  else if(_StPositionInfoData.entry_dir == OP_BUY){  //買いポジ保有中の場合
         if(ret == IND_UP_CHANGE_M){                        //インジケーター下抜け
            close_bool = true;
         }
      }
      
   }
   
   if(close_bool == true){
      bool close_done = false;
      close_done = EA_Close_Order(_StPositionInfoData.ticket_no);        //決済処理
      
      if(close_done == true){
         ClearPosiInfo(_StPositionInfoData);
      }
   }
}

//+------------------------------------------------------------------+
//| リミット・ストップ判定処理
//+------------------------------------------------------------------+

void JudgeLimitStop(struct_PositionInfo &in_st) {

    if ( in_st.ticket_no > 0 ) {        // ポジション保有中の場合
        if ( in_st.set_limit == 0 ||    // リミットまたはストップが未設定の場合
             in_st.set_stop  == 0
        ) {

            bool modify_ret = false;
            modify_ret = EA_Modify_Order(in_st.ticket_no); // リミット・ストップ設定
            
            if ( modify_ret == true ) { // 変更完了
                GetPosiInfo(in_st);     // ポジション情報を更新
            }
        }
    }
}

//+------------------------------------------------------------------+
//| ポジション情報取得　　　　　　　                                             |
//+------------------------------------------------------------------+
bool GetPosiInfo(struct_PositionInfo &in_st){
   
   bool ret = false;
   int position_total = OrdersTotal();                      //保有しているポジション数取得
   
   //全ポジション分ループ
   for(int icount = 0; icount < position_total; icount++){
      
      if(OrderSelect(icount, SELECT_BY_POS) == true){           //インデックス指定でポジション選択
         
         if(OrderMagicNumber() != MAGIC_NO){                   //マジックナンバー不一致判定
            continue;                                          //次のループ処理へ
         }
         
         if(OrderSymbol() != Symbol()){                        //通貨ペア不一致
            continue;                                          //次のループ処理へ
         }
         
         in_st.ticket_no      =OrderTicket();                  //チケット番号を取得
         in_st.entry_dir      =OrderType();                    //オーダータイプを取得
         in_st.set_limit      =OrderTakeProfit();              //リミットを取得
         in_st.set_stop       =OrderStopLoss();                //ストップを取得
         
         ret = true;
         
         break;                                                //ループ処理を中断
       }
   }
   return ret;
}

//+------------------------------------------------------------------+
//| ポジション情報をクリア（決済済みの場合）                                       |
//+------------------------------------------------------------------+
void ClearPosiInfo(struct_PositionInfo &in_st){
   if(in_st.ticket_no > 0){//ポジション保有中の場合
      bool select_bool;    //ポジション選択結果
   
      //ポジションを選択
      select_bool = OrderSelect(
                  in_st.ticket_no,  //チケットNo
                  SELECT_BY_TICKET  //チケット指定で注文選択
               );
               
      //ポジション選択失敗時
      if(select_bool == false){
         printf("[%d]不明なチケットNo = %d", __LINE__, in_st.ticket_no);
         return;
      }
      
      //ポジションがクローズ済の場合
      if(OrderCloseTime() > 0){
         ZeroMemory(in_st);      //ゼロクリア
      }
   }
}

//+------------------------------------------------------------------+
//| デバッグ用コメント表示                                                   |
//+------------------------------------------------------------------+
void DispDebugInfo(struct_PositionInfo &in_st){

   string temp_str = "";                        //表示する文字列
   
   // ¥nは改行コード
   temp_str += StringFormat("チケットNo    :%d\n", in_st.ticket_no);
   temp_str += StringFormat("オーダータイプ  :%d\n", in_st.entry_dir);
   temp_str += StringFormat("リミット      :%s\n",  DoubleToStr(in_st.set_limit,Digits));
   temp_str += StringFormat("ストップ      :%s\n",  DoubleToStr(in_st.set_stop,Digits));
   
   Comment(temp_str);   //コメント表示
}
