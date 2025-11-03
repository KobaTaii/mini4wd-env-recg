/**
 * @file   sketch_RT_AICHIP_logger.pde
 * @brief  processingのプログラムの本体で, ここではグラフを表示するframeを扱う <br>
 *         アプリの構成としては2画面<br>
 *         <ul>
 *          <li>1画面目(processingに最初からある画面) グラフの表示に利用 </li>
 *          <li>2画面目(SecondScreen.pde) 操作用UIを置くのに利用</li>
 *         </ul>
 *          
 * @author Ryota Takahashi
 */
/////////////////////////////
//各種importファイル
/////////////////////////////
import processing.serial.*;
import processing.opengl.*;
import controlP5.*;           //Sketch >Import Library > AddLibraryから追加が可能
import javax.swing.*;
import java.io.PrintWriter; // ★ 1. この行を追加


///////////////////////////////////////
//1画面目, 2画面目で共用のオブジェクト
///////////////////////////////////////
ComPortConnection comp;
// PFrame f;  // ← 削除
SecondApplet s; // ← SecondAppletを直接保持するように変更
PrintWriter csvWriter; // ★ 2. この行を追加

Range range;

boolean flag_DISCONNECT_button_created = false;
boolean flag_CONNECT_button_created    = false;
String com_port;  

//各種グラフ
GyroGraph    gyro_graph;
AccGraph     acc_graph;
MagGraph     mag_graph;
StateGraph   state_graph;
DegGraph     deg_graph;
DutyGraph    duty_graph;
VoltageGraph voltage_graph;
TempGraph    temp_graph;
//受信データ
float   temperature       = 0.0;                       //センサ温度[度C]
float[] omega_vec         = {0.0, 0.0, 0.0};           //角速度ベクトル (x,y,z)[rad]
float[] acc_vec           = {0.0, 0.0, 0.0};           //加速度ベクトル (x,y,z) [1G]
float[] mag_vec           = {0.0, 0.0, 0.0};           //地磁気ベクトル (x,y,z) [uT]

float   duty              = 0.0;
float   deg               = 0.0;

float   acc_norm          = 0.0;                       //加速度ベクトルのノルム 
float   mag_norm          = 0.0;                       //地磁気ベクトルのノルム

int     isStop            = 0;
int     isCurve           = 0;
int     isSlope           = 0;

float  V_Lipo    = 0.0;
float  V_Battery = 0.0;


///////////////////////////////
//グラフ表示frameで使われる変数
///////////////////////////////
int origin_X = 0;    //描画の原点
int origin_Y = 0;
int pre_mouseX = 0;  //前フレームでのマウスの座標
int pre_mouseY = 0;

float ctrl_scale =1.0;//マウスホイールの回転に対応した画面の表示倍率

float scale_change;  //ディスプレイサイズに収まるように調整するための表示倍率
int default_width  = 1360;
int default_height = 1000;

/**
 * ウィンドウサイズの設定 (Processing 4.x は settings() で行う)
 */
void settings() {
  //frameの大きさをディスプレイの大きさに応じて調整
  scale_change = (displayWidth * 0.9) /default_width;
  int wid = (int)(displayWidth * 0.9);
  int hei = (int)(default_height*scale_change  );
  if(hei < displayHeight *0.9){
    size(wid,hei); 
  }
  else{ 
    scale_change *=(displayHeight*0.9)/hei;
    wid = (int)( (float)default_width  * scale_change);
    hei = (int)( (float)default_height * scale_change);
    size(wid,hei);
  }
}

/**
 * プログラム起動時に一度だけ呼ばれる処理
 *         <ul>
 *          <li>2画面にするための処理</li>
 *          <li>ボタン等のUIを使用するためのクラス </li>
 *          <li>frameの大きさをディスプレイの大きさに応じて調整 </li>
 *          <li>画面等の初期化 </li>
 *          <li>各種グラフをframeに追加 </li>
 *         </ul>
 *
 * @param void
 * @return void
 */
void setup() 
{
  //2画面にするための処理
  // f = new PFrame(500, 500); // ← 削除
  // f.setTitle("control window"); // ← 削除
  
  // ▼▼▼ Processing 4.x のマルチウィンドウ起動処理 ▼▼▼
  s = new SecondApplet(this); // メインスケッチ(this)を渡す
  String[] args = {"SecondApplet"};
  PApplet.runSketch(args, s);
  
  // ★ 3. "data_log.csv" という名前でファイルを作成
  csvWriter = createWriter("data_log.csv"); 
  
  // ★ 4. CSVファイルの1行目にヘッダーを書き込む
  csvWriter.println("timestamp_ms,accX,accY,accZ,omegaX,omegaY,omegaZ,magX,magY,magZ,temp,deg,duty,isStop,isCurve,isSlope,V_Lipo,V_Battery");
  
  //ボタン等のUIを使用するためのクラス
  ControlP5 cp5 = new ControlP5(this);
  
  //画面等の初期化
  background(0);
  frameRate(60);
  PFont  myfont = createFont( "Arial" , 30 );
  textFont( myfont );
  
  //各種グラフをframeに追加
  
  acc_graph      =  new     AccGraph(30 ,  25, 600, 200, 30,  8, color(255,200,0,75)    ,"acc"     , cp5);
  gyro_graph     =  new    GyroGraph(30 , 275, 600, 200, 30,  8, color(0,200,255,75)    ,"gyro"    , cp5);
  mag_graph      =  new     MagGraph(30 , 525, 600, 200, 30,  8, color(255,0,200,75)    ,"mag"     , cp5);
  deg_graph      =  new     DegGraph(700, 275, 600, 200, 30,  8, color(255,255,200,75)  ,"deg"     , cp5);
  duty_graph     =  new    DutyGraph(700, 525, 600, 200, 30,  8, color(255,200,200,75)  ,"duty"    , cp5);
  state_graph    =  new   StateGraph(700, 775, 600, 200, 30,  7, color(200,0,255,75)    ,"state"   , cp5);
  voltage_graph  =  new VoltageGraph(30 , 775, 600, 200, 30,  8, color(200,200,255,75)  ,"voltage" , cp5);
  temp_graph     =  new    TempGraph(700,  25, 600, 200, 30,  8, color(200,200,255,75)  ,"temp"    , cp5);


}

/**
 * frameの描画の度に呼ばれる<br>
 *  <ul>
 *    <li>画面をディスプレイサイズに応じて拡大,縮小</li>
 *    <li>背景を塗りつぶし<li>
 *    <li>画面上をドラッグしたときの処理 </li>
 *    <li>マウスホイールの回転に応じて画面を拡大,縮小 </li>f
 *    <li>各種グラフの描画処理</li>
 *  </ul>
 *
 * @param void
 * @return void
 */
void draw()
{
  //画面をディスプレイサイズに応じて拡大,縮小
  scale(scale_change);
  
  //背景を塗りつぶし
  background(0);
   
  //画面上をドラッグしたときの処理
   translate(origin_X,origin_Y);
  if(mouseButton == LEFT){
    origin_X += mouseX - pre_mouseX;
    origin_Y += mouseY - pre_mouseY;
  }
  pre_mouseX = mouseX;
  pre_mouseY = mouseY;

  //マウスホイールの回転に応じて画面を拡大,縮小　
  scale(ctrl_scale);
  
  //各種グラフの描画処理
  gyro_graph.drawGraph();
  acc_graph.drawGraph();
  mag_graph.drawGraph();
  state_graph.drawGraph();
  deg_graph.drawGraph();
  duty_graph.drawGraph();
  voltage_graph.drawGraph();
  temp_graph.drawGraph();

  //別frameの描画
  // f.s.redraw(); // ← この行をコメントアウト、または削除します

}

/**
 * マウスホイールを回転した際に呼ばれる関数
 * マウスホイールの回転に応じてctrl_scaleを0.2から5.0まで変化させる
 * @param event
 * @return void
 */
void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  ctrl_scale = constrain(ctrl_scale + 0.1*e,1.0,5.0 );
}

/**
 * キーボードを押したときに呼ばれる関数
 * 右キー,左キーでグラフの描画領域をx方向にシフトさせる
 * @param  void
 * @return void
 */
void keyPressed() {
  if (keyCode == LEFT) {
      gyro_graph.range_L -= 0.05; 
      gyro_graph.range_H -= 0.05;
    
      acc_graph.range_L -= 0.05;
      acc_graph.range_H -= 0.05;
  
      mag_graph.range_L -= 0.05;
      mag_graph.range_H -= 0.05;
      
      state_graph.range_L -= 0.05;
      state_graph.range_H -= 0.05;
    
      deg_graph.range_L -= 0.05;
      deg_graph.range_H -= 0.05;
    
      duty_graph.range_L -= 0.05;
      duty_graph.range_H -= 0.05;
    
      voltage_graph.range_L -= 0.05;
      voltage_graph.range_H -= 0.05;
    
      temp_graph.range_L -= 0.05;
      temp_graph.range_H -= 0.05;
  }
 
  if (keyCode == RIGHT) {
     gyro_graph.range_L += 0.05; 
      gyro_graph.range_H += 0.05;
    
      acc_graph.range_L += 0.05;
      acc_graph.range_H += 0.05;
  
      mag_graph.range_L += 0.05;
      mag_graph.range_H += 0.05;
      
      state_graph.range_L += 0.05;
      state_graph.range_H += 0.05;
    
      deg_graph.range_L += 0.05;
      deg_graph.range_H += 0.05;
    
      duty_graph.range_L += 0.05;
      duty_graph.range_H += 0.05;
    
      voltage_graph.range_L += 0.05;
      voltage_graph.range_H += 0.05;
    
      temp_graph.range_L += 0.05;
      temp_graph.range_H += 0.05;
  } 

}

/**
 * ★ 5. CSVファイルにデータ1行を書き込む関数
 */
void writeCsvData() {
  if (csvWriter != null) {
    
    // 書き込むデータを String の配列として準備
    String[] data = {
      str(millis()),      // タイムスタンプ (ミリ秒)
      str(acc_vec[0]),    // 加速度
      str(acc_vec[1]),
      str(acc_vec[2]),
      str(omega_vec[0]),  // 角速度
      str(omega_vec[1]),
      str(omega_vec[2]),
      str(mag_vec[0]),    // 地磁気
      str(mag_vec[1]),
      str(mag_vec[2]),
      str(temperature),   // 温度
      str(deg),           // 角度
      str(duty),          // Duty
      str(isStop),        // 状態
      str(isCurve),       //
      str(isSlope),       //
      str(V_Lipo),        // 電圧
      str(V_Battery)      //
    };
    
    // データをカンマ(,)で連結して1行の文字列にする
    String dataRow = join(data, ",");
    
    // ファイルに書き出す
    csvWriter.println(dataRow);
  }
}

/**
 * ★ 6. スケッチ終了時に呼ばれる処理 (ウィンドウを閉じた時など)
 */
@Override
public void exit() { // ← 角括弧 [ ではなく 中括弧 {
  if (csvWriter != null) {
    csvWriter.flush(); // バッファに残っているデータを強制的に書き出す
    csvWriter.close(); // ファイルを閉じる
    println("CSVファイル (data_log.csv) が保存されました。");
  }
  super.exit();
}
