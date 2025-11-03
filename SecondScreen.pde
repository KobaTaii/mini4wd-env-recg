import processing.core.PApplet;
import javax.swing.JFrame;
import processing.serial.Serial;
import controlP5.*;

public class SecondApplet extends PApplet {

  PApplet parent; // 1. メインスケッチ(parent)を保存する変数を追加

  Serial port;
  myTextarea mta1, mta2;

  int state_l_led = 0;  //add
  int state_r_led = 0;  //add

  int[] buf     = new int[100];
  int[] inByte  = new int[100];

  ControlP5 cp5;
  PFont pfont; // 2. 初期化を setup() に移動
  ControlFont font; // 2. 初期化を setup() に移動

  // 3. メインスケッチ(parent)を受け取るコンストラクタを追加
  public SecondApplet(PApplet parent) {
    this.parent = parent;
  }

  // 4. Processing 4.x でウィンドウサイズを設定
  public void settings() {
    size(500, 500); // PFrameで設定していたサイズ
  }

  public void setup() {
    cp5 = new ControlP5(this);

    // 5. フォントの初期化を setup() 内に移動
    pfont = createFont("Arial", 20, true);
    font = new ControlFont(pfont, 241);

    background(0);
    noStroke();

    // 6. メインスケッチのグローバル変数にアクセスする準備
    sketch_RT_AICHIP_logger mainSketch = (sketch_RT_AICHIP_logger) parent;

    // 7. compの初期化 (詳細はステップ3で修正)
    mainSketch.comp  = new ComPortConnection(this, 20, 20, "COM21", cp5);

    mta1  = new myTextarea(20, 230, 200, 200, cp5, "mta1" );
    mta2  = new myTextarea(230, 230, 200, 200, cp5, "mta2" );

    mta1.println("Hello !");
    mta1.println("Here is Aprication console. ");
    mta2.println("Hello !!");
    
    // --- 走行開始ボタン (Duty 50%) ---
    cp5.addButton("START_RUN")
      .setLabel("START (50%)") // ボタンの表示名
      .setPosition(310, 170)   // 元ノブの位置
      .setSize(100, 40);
    cp5.getController("START_RUN").getCaptionLabel().setFont(font).toUpperCase(false).setSize(16);

    // --- 走行停止ボタン (Duty 0%) ---
    cp5.addButton("STOP_RUN")
      .setLabel("STOP (0%)") // ボタンの表示名
      .setPosition(310, 220)  // STARTボタンの下
      .setSize(100, 40);
    cp5.getController("STOP_RUN").getCaptionLabel().setFont(font).toUpperCase(false).setSize(16);
  }

  public void draw() {
    background(0);

    mta1.update();
    mta2.update();

    // 8. メインスケッチのcompを描画
    sketch_RT_AICHIP_logger mainSketch = (sketch_RT_AICHIP_logger) parent;
    if (mainSketch.comp != null) {
      mainSketch.comp.drawUI();
    }
  }

  public void controlEvent(ControlEvent theEvent) {

    // 9. メインスケッチのグローバル変数にアクセス
    sketch_RT_AICHIP_logger mainSketch = (sketch_RT_AICHIP_logger) parent;

    println(theEvent.getController().getName());
    if (theEvent.getController().getName() == "CONNECT"  )
    {
      // 10. すべてのグローバル変数の前に "mainSketch." を追加
      if (mainSketch.flag_CONNECT_button_created == true) {
        mta1.println("Now connecting ...");
        try {
          port = new Serial(this, mainSketch.com_port, 115200);
          mta1.println("Connection is successful");
          mainSketch.comp.changeBoxColor(color(200, 50, 50, 100)); // "mainSketch." を追加
        }
        catch (RuntimeException e) {
          mta1.println("Cannot open COM port.");
          mainSketch.comp.changeBoxColor(color(0, 155, 255, 50)); // "mainSketch." を追加
        }
      }
      if (mainSketch.flag_CONNECT_button_created == false) mainSketch.flag_CONNECT_button_created = true;
    }

    if (theEvent.getController().getName() == "DISCONNECT" )
    {
      if (mainSketch.flag_DISCONNECT_button_created == true) {
        try {
          port.stop();
          mta1.println("Disconnected.");
          mainSketch.comp.changeBoxColor(color(0, 155, 255, 50)); // "mainSketch." を追加
        }
        catch (NullPointerException e) {
          mta1.println("Disconnecting is fail.");
          mainSketch.comp.changeBoxColor(color(0, 155, 255, 50)); // "mainSketch." を追加
        }
      }
      if (mainSketch.flag_DISCONNECT_button_created == false) mainSketch.flag_DISCONNECT_button_created = true;
    }
    
    // --- START_RUNボタンを押したときの処理 ---
    if (theEvent.getController().getName() == "START_RUN" ) {
      if (port != null) {
        // mainSketch.command0 を呼び出し、dutyを 0.5 (50%) に設定
        port.write(mainSketch.command0(1.0)); 
      }
    }

    // --- STOP_RUNボタンを押したときの処理 ---
    if (theEvent.getController().getName() == "STOP_RUN" ) {
      if (port != null) {
        // mainSketch.command0 を呼び出し、dutyを 0.0 (0%) に設定
        port.write(mainSketch.command0(0.0));
      }
    }
  }

  int concatenate2Byte_int(int H_byte, int L_byte) {
    int con;
    con = L_byte + (H_byte<<8);
    if (con > 32767) {
      con -=  65536;
    }
    return con;
  }


  int concatenate2Byte_uint(int H_byte, int L_byte) {
    int con;
    con = L_byte + (H_byte<<8);
    return con;
  }


  int concatenate4Byte_uint(int byte0, int byte1, int byte2, int byte3) {
    return 0;
  }


  void serialEvent(Serial p)
  {
    // 11. メインスケッチの変数にアクセス
    sketch_RT_AICHIP_logger mainSketch = (sketch_RT_AICHIP_logger) parent;

    String str = "d" ;
    if (port.available() != 0)
    {
      for (int i=42; i>=1; i--)
      {
        buf[i] = buf[i-1];
      }

      buf[0] = port.read();
      str = str(char(buf[0]));
      mta2.println(str +"  "+ str(buf[0])+"  "+hex(buf[0], 2)  );
    }


    //受信データの先頭4byteが0xff,0xff,0x52,0x54なのでこのパターンを目印に
    //データをinByteに格納し物理量に変換
    if (
      buf[39] == 0x54
      && buf[40] == 0x52
      && buf[41] == 0xff
      && buf[42] == 0xff )
    {

      for (int i = 0; i <43; i ++) {
        inByte[i] = buf[42-i];
      }
      port.clear();

      // 12. すべてのグローバル変数 (グラフ、ベクトル等) の前に "mainSketch." を追加
      mainSketch.omega_vec[0] = radians(((float)(concatenate2Byte_int(inByte[17], inByte[16]) ) )/16.4);
      mainSketch.omega_vec[1] = radians(((float)(concatenate2Byte_int(inByte[19], inByte[18]) ) )/16.4);
      mainSketch.omega_vec[2] = radians(((float)(concatenate2Byte_int(inByte[21], inByte[20]) ) )/16.4);
      mainSketch.gyro_graph.addPoint( degrees(mainSketch.omega_vec[0])/2000.0, degrees(mainSketch.omega_vec[1])/2000.0, degrees(mainSketch.omega_vec[2])/2000.0 );

      mainSketch.acc_vec[0]   = (float)(concatenate2Byte_int(inByte[9], inByte[8]))/2048.0;
      // ... (以下、acc_vec, acc_graph, temperature, mag_vec, deg, duty, isStop, V_Lipo, acc_norm など、すべてに "mainSketch." を追加) ...

      mainSketch.acc_vec[1]   = (float)(concatenate2Byte_int(inByte[11], inByte[10]))/2048.0;
      mainSketch.acc_vec[2]   = (float)(concatenate2Byte_int(inByte[13], inByte[12]))/2048.0;
      mainSketch.acc_graph.addPoint( mainSketch.acc_vec[0]/4.0, mainSketch.acc_vec[1]/4.0, mainSketch.acc_vec[2]/4.0 );
      mainSketch.temperature = (float)(concatenate2Byte_int(inByte[15], inByte[14]))/340.0 + 35.0;
      mainSketch.temp_graph.addPoint(mainSketch.temperature/80.0);
      mainSketch.mag_vec[0]   = (float)(concatenate2Byte_int(inByte[23], inByte[22])) * 0.3;
      mainSketch.mag_vec[1]   = (float)(concatenate2Byte_int(inByte[25], inByte[24])) * 0.3;
      mainSketch.mag_vec[2]   = (float)(concatenate2Byte_int(inByte[27], inByte[26])) * 0.3;
      mainSketch.mag_graph.addPoint( mainSketch.mag_vec[0]/600.0, mainSketch.mag_vec[1]/600.0, mainSketch.mag_vec[2]/600.0 );
      mainSketch.deg = degrees((float)(concatenate2Byte_int(inByte[29], inByte[28])  ) * 2 *PI / 32767.0 ) ;
      mainSketch.deg_graph.addPoint(mainSketch.deg/180.0);
      mainSketch.duty = (float)(concatenate2Byte_int(inByte[31], inByte[30])/32767.0 * 100.0);
      mainSketch.duty_graph.addPoint(mainSketch.duty/100.0);
      mainSketch.isStop = inByte[32];
      mainSketch.isCurve = inByte[33];
      mainSketch.isSlope = inByte[34];
      mainSketch.state_graph.addPoint( (float)(mainSketch.isStop)/3.5 + 3.0/7.0, (float)(mainSketch.isCurve)/3.5 - 1.0/7.0, (float)(mainSketch.isSlope)/3.5 + -5.0/7.0 );
      mainSketch.V_Lipo = (float)(concatenate2Byte_uint(inByte[40], inByte[39]) / 13107.0 );
      mainSketch.V_Battery = (float)(concatenate2Byte_uint(inByte[42], inByte[41]) / 13107.0 );
      mainSketch.voltage_graph.addPoint(mainSketch.V_Lipo/5.0, mainSketch.V_Battery/5.0);
      mainSketch.acc_norm = sqrt(mainSketch.acc_vec[0]*mainSketch.acc_vec[0]+mainSketch.acc_vec[1]*mainSketch.acc_vec[1]+mainSketch.acc_vec[2]*mainSketch.acc_vec[2]);
      mainSketch.mag_norm = sqrt(mainSketch.mag_vec[0]*mainSketch.mag_vec[0]+mainSketch.mag_vec[1]*mainSketch.mag_vec[1]+mainSketch.mag_vec[2]*mainSketch.mag_vec[2]);
    }

    // ★ 7. メインスケッチのCSV書き込み関数を呼び出す
    mainSketch.writeCsvData();
  }


  /**
   * キーボードを押したときに呼ばれる関数
   * 右キー,左キーでグラフの描画領域をx方向にシフトさせる
   * @param event
   * @return void
   */
  void keyPressed() {
    // 13. メインスケッチのグラフ変数にアクセス
    sketch_RT_AICHIP_logger mainSketch = (sketch_RT_AICHIP_logger) parent;

    println(str(key));
    if (keyCode == LEFT) {
      // 14. すべてのグラフ変数の前に "mainSketch." を追加
      mainSketch.gyro_graph.range_L -= 0.05;
      mainSketch.gyro_graph.range_H -= 0.05;
      mainSketch.acc_graph.range_L -= 0.05;
      // ... (以下、mag_graph, state_graph, deg_graph, duty_graph, voltage_graph, temp_graph にも同様に追加) ...
      mainSketch.acc_graph.range_H -= 0.05;
      mainSketch.mag_graph.range_L -= 0.05;
      mainSketch.mag_graph.range_H -= 0.05;
      mainSketch.state_graph.range_L -= 0.05;
      mainSketch.state_graph.range_H -= 0.05;
      mainSketch.deg_graph.range_L -= 0.05;
      mainSketch.deg_graph.range_H -= 0.05;
      mainSketch.duty_graph.range_L -= 0.05;
      mainSketch.duty_graph.range_H -= 0.05;
      mainSketch.voltage_graph.range_L -= 0.05;
      mainSketch.voltage_graph.range_H -= 0.05;
      mainSketch.temp_graph.range_L -= 0.05;
      mainSketch.temp_graph.range_H -= 0.05;
    }

    if (keyCode == RIGHT) {
      // 15. すべてのグラフ変数の前に "mainSketch." を追加
      mainSketch.gyro_graph.range_L += 0.05;
      mainSketch.gyro_graph.range_H += 0.05;
      // ... (以下同様) ...
      mainSketch.acc_graph.range_L += 0.05;
      mainSketch.acc_graph.range_H += 0.05;
      mainSketch.mag_graph.range_L += 0.05;
      mainSketch.mag_graph.range_H += 0.05;
      mainSketch.state_graph.range_L += 0.05;
      mainSketch.state_graph.range_H += 0.05;
      mainSketch.deg_graph.range_L += 0.05;
      mainSketch.deg_graph.range_H += 0.05;
      mainSketch.duty_graph.range_L += 0.05;
      mainSketch.duty_graph.range_H += 0.05;
      mainSketch.voltage_graph.range_L += 0.05;
      mainSketch.voltage_graph.range_H += 0.05;
      mainSketch.temp_graph.range_L += 0.05;
      mainSketch.temp_graph.range_H += 0.05;
    }
  }
}
