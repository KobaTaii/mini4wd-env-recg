class ComPortConnection {
  int x;
  int y;
  color color_box;
  Textfield tf;
  ControlP5 _cp5;
  PApplet p; // 1. 描画対象のPApplet(SecondApplet)を保存する変数を追加

  ComPortConnection(PApplet p_, int x_, int y_, String default_comPort,  ControlP5 contp5) {
    p = p_; // 3. 参照を保存
    x = x_;
    y = y_;
    color_box = color(0, 155, 255, 50);
    _cp5 = contp5;
    PFont pfont = p.createFont("Arial", 20, true); // 2. "p." を追加
    ControlFont font = new ControlFont(pfont, 241);

    _cp5.addButton("CONNECT")
      .setValue(1)
        .setPosition(x+10, y+10)
          .setSize(200, 40)
            ;

    _cp5.getController("CONNECT")
      .getCaptionLabel()
        .setFont(font)
          .toUpperCase(false)
            .setSize(24)
              ;      

  
    _cp5.addButton("DISCONNECT")
      .setValue(100)
        .setPosition(x+10, y+60)
          .setSize(200, 40)
            .updateSize()
              ;
    _cp5.getController("DISCONNECT")
      .getCaptionLabel()
        .setFont(font)
          .toUpperCase(false)
            .setSize(24)
              ;      


    tf = _cp5.addTextfield("COMPORT")
      .setPosition(x+220, y+40)
        .setSize(200, 40)
          .setFont(createFont("arial", 20))
            .setAutoClear(false)
              .setCaptionLabel("");
    ;
    tf.setText(default_comPort);
 
  }


 void drawUI() {

    p.noFill(); // 4. "f.s" を "p" に変更
    p.rectMode(CORNER); // 4. "f.s" を "p" に変更
    p.strokeWeight(5); // 4. "f.s" を "p" に変更
    p.stroke(color_box); // 4. "f.s" を "p" に変更
    p.smooth(); // 4. "f.s" を "p" に変更
    p.rect(x, y, 450, 110); // 4. "f.s" を "p" に変更

    p.fill(255, 255, 255); // 4. "f.s" を "p" に変更
    p.textSize(20); // 4. "f.s" を "p" に変更
    
    com_port = tf.getText();
 }
  
  
  
  void changeBoxColor(color col){
    color_box = col;
  }

}
