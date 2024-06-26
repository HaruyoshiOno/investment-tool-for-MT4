//+------------------------------------------------------------------+
//|                                                      CalcRCI.mq4 |
//+------------------------------------------------------------------+
#property strict // strictは絶対に削除しない

//構造体形宣言
struct struct_rci_data {
   datetime date_value;
   double   rate_value;
   int      rank_date;
   int      rank_rate;
   double   rank_adjust_rate;
};

// インプットパラメータ
input  int              _InputCalPeriod_S      = *;                 // 算出期間[短期]
input  int              _InputCalPeriod_M      = *;                // 算出期間[中期]
input  int              _InputCalPeriod_L      = *;                // 算出期間[長期]

double CalRCI(
                const double &in_array[],    //インプット変数配列アドレス
                      int     in_time_period,//算出期間
                      int     in_index       //インデックス
                      )
{  
   double ret = 0;   //戻り値

   int    array_count = ArraySize(in_array);    //配列要素数取得
   int    end_index = in_index + in_time_period;//ループエンド
   
   if(end_index < array_count){
      struct_rci_data temp_st_rci[];
      int arrayst_count = ArrayResize(                   //RCI算出用構造体動的配列
                                       temp_st_rci,      //変更する配列
                                       in_time_period,   //新しい配列サイズ
                                       0                 //予備サイズ
                                       );
                                      
     int temp_rank = 1;
     int arr_count = 0;
     for (int icount = in_index; icount < end_index; icount++) {
         temp_st_rci[arr_count].date_value = Time[icount];        //日付データ設定
         temp_st_rci[arr_count].rate_value = in_array[icount];    //価格データ設定
         temp_st_rci[arr_count].rank_date  = temp_rank;           //日付順位(ランク設定)
         temp_rank++;
         arr_count++;
     }
     
     //価格順ソート
     for(int main_count = 0; main_count < arrayst_count - 1; main_count++){
      for(int sub_count = main_count + 1; sub_count < arrayst_count; sub_count++){
         
         //次の配列メンバと比較して小さい場合
         if(temp_st_rci[main_count].rate_value < temp_st_rci[sub_count].rate_value){
            //構造体配列を入れ替える
            struct_rci_data temp_swap = temp_st_rci[main_count];  //比較元のデータ退避
            temp_st_rci[main_count]   = temp_st_rci[sub_count];   //比較元のデータ入れ替え
            temp_st_rci[sub_count]    = temp_swap;                //比較先に対比データをセット
         }
      }
     }
     
     //価格RANK設定
     for(int main_count = 0; main_count < arrayst_count; main_count++){
         int temp_set_rank = main_count + 1;
         temp_st_rci[main_count].rank_rate         = temp_set_rank;
         temp_st_rci[main_count].rank_adjust_rate  = (double)temp_set_rank;
     }
     
        // 価格RANKの同値調整
        for ( int main_count = 0 ; main_count < arrayst_count - 1 ; main_count++ ) {
            double sum_rank   = (double)temp_st_rci[main_count].rank_rate;      // ランクサマリー
            int    same_count = 0;                                              // 同値検出カウント

            for ( int sub_count = main_count + 1 ; sub_count < arrayst_count ; sub_count++ ) {

                if ( temp_st_rci[main_count].rate_value == temp_st_rci[sub_count].rate_value ) { // 同値の場合
                    sum_rank += (double)temp_st_rci[sub_count].rank_rate;       // ランクサマリーにランクを加算
                    same_count++;                                               // 同値検出カウントをインクリメント
                } else {                                                        // 同値以外の場合
                    break;                                                      // 同値の場合forループから抜ける
                }
            }

            if ( same_count >= 1 ) {                                            // 同値価格が1つ以上ある場合
                double set_adjust_rank = sum_rank / ((double)same_count + 1);   // ランクの中間値を算出

                for( int ad_count = 0 ; ad_count <= same_count; ad_count++ ) {  // 同値検出カウント分ループ
                    // 価格順位(調整後)に中間値を設定
                    temp_st_rci[ad_count + main_count].rank_adjust_rate = set_adjust_rank; 
                }

                main_count += same_count;                         // メインループを同値検出カウント分スキップさせる
            }
        }
        
        double sum_d       =0;
        double temp_diff   =0;
        for(int main_count = 0; main_count < arrayst_count; main_count++){
            temp_diff = (double)temp_st_rci[main_count].rank_date - temp_st_rci[main_count].rank_adjust_rate;
            sum_d += MathPow(temp_diff, 2);
        }
        
        //RCIのn(n^2-1)算出
        int temp_div = in_time_period * ((int)MathPow(in_time_period, 2)-1);
        
        //RCIを算出
        if(temp_div > 0){
            ret = 100 * (1-(6*sum_d / (double)temp_div));
        }

     
   }
   return ret; //戻り値を返す
}