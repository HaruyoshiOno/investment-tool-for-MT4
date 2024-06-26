//+------------------------------------------------------------------+
//|                                                   DispObject.mq4 |
//+------------------------------------------------------------------+
#property strict  //strictは絶対に削除しない事

//マクロ定義
#define  OBJ_HEAD       (__FILE__ + "_")           //オブジェクトヘッダ名

//+------------------------------------------------------------------+
//| 初期化処理                                                         |
//+------------------------------------------------------------------+
int Init_DispObject()
{

   return(INIT_SUCCEEDED);    //戻り値：初期化成功
}

//+------------------------------------------------------------------+
//| アンロード処理                                                        |
//+------------------------------------------------------------------+
void Deinit_DispObject(const int reason){


}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| テスト用オブジェクト描画                                                  |
//+------------------------------------------------------------------+
void TestDispObject(int    in_index){
      //インデックスが範囲外の場合は描画しない
      if(in_index < 0){
         return;
      }
      
      if(in_index >= Bars){
         return;
      }
      
      string obj_name;     //オブジェクト名
      obj_name = StringFormat("%sEATest%s", OBJ_HEAD, TimeToStr(Time[in_index]));
      
      if(ObjectFind(obj_name) >= 0){   //オブジェクト名重複チェック
         ObjectDelete(obj_name);    //重複していたら削除
      }
      
      ObjectCreate(                          //オブジェクト生成
                   obj_name,                 //オブジェクト名
                   OBJ_ARROW_RIGHT_PRICE,    //オブジェクトタイプ
                   0,                        //ウィンドウインデックス
                   Time[in_index],           //1番目の時間のアンカーポイント
                   Close[in_index]           //1番目の価格のアンカーポイント
                  );
                  
      //オブジェクトプロパティ設定
      ObjectSetInteger(0, obj_name, OBJPROP_COLOR, clrYellow);    //ラインの色設定
      ObjectSetInteger(0, obj_name, OBJPROP_WIDTH, 1);            //ラインの幅設定
      ObjectSetInteger(0, obj_name, OBJPROP_BACK, false);         //オブジェクトの背景表示設定
      ObjectSetInteger(0, obj_name, OBJPROP_SELECTABLE, false);   //オブジェクトの選択可否設定
      ObjectSetInteger(0, obj_name, OBJPROP_SELECTED, false);     //オブジェクトの選択状態
      ObjectSetInteger(0, obj_name, OBJPROP_HIDDEN, true);        //オブジェクトリスト表示設定
}