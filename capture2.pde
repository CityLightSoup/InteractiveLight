import processing.video.*;
import gab.opencv.*;

Capture video;
OpenCV opencv;
ArrayList<PVector> centers;
PShape lightModel;

float averageY = 0;
float exPosY = 480;
//int light = 1;
//int lastTime = 0;
float prePos = 0;
boolean changeRecently = false;
//int changeTime = 0;
//int cooldownTime = 3000;
float time = 0;
float interval = 5000;
int fov = 45;
int direct = -1;
float[] cameraPos = {0, 0, 10};
float[] cameraDir = {0, 0, -1};

void setup() {
  size(720, 480, P3D);
  String[] cams = Capture.list();
  printArray(cams);

  video = new Capture(this, cams[0]);
  opencv = new OpenCV(this, video);

  opencv.startBackgroundSubtraction(5, 3, 0.5);

  video.start();
  centers = new ArrayList<PVector>();
  
  lightModel = loadShape("Polyester Masa Lambası-Free3D.obj");
}

void draw() {
  if (video.available()) {
    background(0);
    video.read();

    image(video, 0, 0);
    opencv.loadImage(video);
    background(80);

    opencv.updateBackground();

    opencv.dilate();
    opencv.erode();


    noFill();

    stroke(255, 255, 0);
    strokeWeight(3);
    centers.clear();

    for (Contour contour : opencv.findContours()) {
      contour.draw();
      PVector center = getContourCenter(contour);
      if (center != null) {
        centers.add(center);
      }
    }

    drawAveragePoint();
    distractAveragePoint();

    detectKey();
    sceneSetting();
    objectSetting();
  }
}

void distractAveragePoint() {
  
  // 秒数のカウント
  int sec = int(millis() - time) / 1000;
  //println(sec);
  
  // 0.5s毎にexPosYに動体検知した物体のy座標の平均値を代入
  /*
  if (millis() % 500 == 0) {
    exPosY =  averageY;
  }
  */

  //if (millis() - time > interval) {
    println("curPos: " + averageY);
    //println("exPosY: " + exPosY + " curPosY: " + averageY);
    if (exPosY - averageY > 350) { // 下から上に動いたとき
      direct = 1;
      println("light: on" + " curPosY: " + averageY + " interval: " + (millis() - time));
      time = millis();
      exPosY = averageY;
      delay(1000);
    } else if(averageY - exPosY > 350) { // 上から下に動いたとき
      direct = -1;
      println("light: off" + " curPosY: " + averageY + " interval: " + (millis() - time));
      time = millis();
      exPosY = averageY;
      delay(1000);
    }
  //}
}

void drawAveragePoint() {
  if (centers.size() > 0) {
    //float totalX = 0;
    float totalY = 0;
    for (PVector center : centers) {
      //totalX += center.x;
      if(center.y > 200) { 
        // ↑動くものが映っていなくてもy = 40 ^ 170辺りが動いていると検出されるので足きりする
        totalY += center.y;
      }
    }
    //float averageX = totalX / centers.size();
    averageY = totalY / centers.size();

    fill(255, 0, 0);
    rect(width /2, averageY - 5, 10, 10);
  }
}

PVector getContourCenter(Contour contour) {
  PVector center = new PVector();
  float sumX = 0;
  float sumY = 0;
  ArrayList<PVector> points = contour.getPoints();
  for (PVector point : points) {
    sumX += point.x;
    sumY += point.y;
  }
  if (points.size() > 0) {
    center.x = sumX / points.size();
    center.y = sumY / points.size();
    return center;
  } else {
    return null;
  }
}

void movieEvent(Movie m) {
  m.read();
}

void objectSetting() {
  //blendMode(BLEND);
  //imageMode(CORNER);

  {
    /*
    pushMatrix();
    //lightSpecular(55, 55, 55);
    //specular(255, 255, 255);
    //emissive(100);
    //shininess(3.0);
    translate(5, 2, 0);
    sphere(0.5);
    popMatrix();
    */
  }
  stroke(0);
  {
    pushMatrix();
    translate(0, -5, 0);
    fill(200);
    box(1000, 5, 1000);
    popMatrix();
  }
  {
    pushMatrix();
    translate(0, 0, 0);
    fill(200, 100, 100);
    box(2, 10, 2);
    popMatrix();
  }
  
  {
    pushMatrix();
    translate(4, 0, 0);
    scale(0.05, 0.05, 0.05);
    shape(lightModel);
    popMatrix();
  }
}

void sceneSetting() {
  // camera setting
  perspective(
    radians(fov), // 視野角
    float(width)/float(height), // アスペクト比
    0.1, 1000.0                   // クリッピング距離
    );

  cameraDir[0] = sin(-radians( (mouseX-width/2.0) / (width/2.0) * 90));
  cameraDir[1] = sin(-radians( (mouseY-height/2.0) / (height/2.0) * 90));
  cameraDir[2] = -(1 - sqrt(cameraDir[0]*cameraDir[0]+cameraDir[1]*cameraDir[1]));

  camera(
    cameraPos[0], cameraPos[1], cameraPos[2], // 視点：カメラの位置
    cameraPos[0]+cameraDir[0], cameraPos[1]+cameraDir[1], cameraPos[2]+cameraDir[2], // 中心点：ここが視界の中心に映るようにする
    0, -1, 0   // 上向き：上向きにしたい軸に「-1」を入れる
    );

  // light setting
  if ( direct > 0) {
    directionalLight(
      150, 150, 150, // 照明光の色
      -1, -1, -1        // 照明の向き
      );
  }
}

void detectKey() {
  if (keyPressed) {
    if (key == 'w' || key == 'W') {
      for (int i = 0; i < 3; i++) {
        cameraPos[i] += cameraDir[i] * 0.1;
      }
    }
    if (key == 's' || key == 'S') {
      for (int i = 0; i < 3; i++) {
        cameraPos[i] -= cameraDir[i] * 0.1;
      }
    }
    if (key == 'a' || key == 'A') {
      float[] up = {0, 1, 0};
      float[] left = normalized(crossProduct(cameraDir, up));
      for (int i = 0; i < 3; i++) {
        cameraPos[i] += left[i] * 0.1;
      }
    }
    if (key == 'd' || key == 'D') {
      float[] up = {0, 1, 0};
      float[] left = normalized(crossProduct(cameraDir, up));
      for (int i = 0; i < 3; i++) {
        cameraPos[i] -= left[i] * 0.1;
      }
    }
    if (key == 'q'|| key == 'Q') {
      fov++;
    }
    if (key == 'e' || key == 'E') {
      fov--;
    }
  }
}

void keyPressed() {
  if (key == 'f' || key == 'F') {
    direct *= -1;
  }
}

float[] crossProduct(float[] a, float[] b) {
  float[] c = new float[3];
  c[0] = a[1]*b[2] - a[2]*b[1];
  c[1] = a[2]*b[0] - a[0]*b[2];
  c[2] = a[0]*b[1] - a[1]*b[0];
  return c;
}

float[] normalized(float[] a) {
  float norm = sqrt(a[0]*a[0] + a[1]*a[1] + a[2]*a[2]);
  float[] c = new float[3];
  c[0] = a[0] / norm;
  c[1] = a[1] / norm;
  c[2] = a[2] / norm;
  return c;
}
