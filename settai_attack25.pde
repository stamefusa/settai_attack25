import ddf.minim.*;

Minim minim;
AudioPlayer se;

int c_width = 0, c_height = 0; // セルの幅と高さ
int c_stroke = 10; // セルの線の太さ

final int MY_STATUS = 1; // 自分のマスを表すステータス
final int ENEMY_STATUS1 = -1; // 相手のマスを表すステータス
final int ENEMY_STATUS2 = -2;
final int ENEMY_STATUS3 = -3;

final int MAX_BOARD_NUM = 1; // 盤面バリエーションの最大数

String[] fontList;//String型のArrayListを用意
PFont font;

int[][] cells = new int[5][5]; // 盤面のマスの状態を格納する配列
int solve_x = 3; // 次に打つマスのx座標
int solve_y = 4; // 次に打つマスのy座標

// マスをひっくり返すときのアニメーション制御用変数
boolean isFlipped = false;
ArrayList targets;
int count = 0;

// 次の盤面に遷移するときの制御用変数
boolean isFinished = false;
int finished_time = 0;
int current_board = 1;

void setup()
{
  load(current_board);

  minim = new Minim(this);
  se = minim.loadFile("se.wav");
  delay(500);
  se.play();
  
  fontList= PFont.list();//PFontに登録されているフォントを代入
  printArray(fontList);//出力
  font = createFont(fontList[2], 120);

  frameRate(10);
  //fullScreen(P3D);
  size(1920, 1200, P3D);
  calcSize();
  //init();  
}

void draw()
{
  if (isFlipped == true) {
    animatedCells();
  }

  /*
  if (isFinished == true) {
    // 3秒経ったら次の盤面へ
    if (millis() - finished_time > 3000) {
      isFinished = false;
      current_board = (current_board == MAX_BOARD_NUM) ? 1 : current_board + 1; // インクリメント、最大に達したら1から
      load(current_board);
      init();
    }
  }
  */

  dispBoard();

}

void load(int num)
{
  println("load number: " + num);

  String[] problem = loadStrings("problems/" + num + ".csv");
  for (int i = 0; i < problem.length; i++) {
    int[] c = int(split(problem[i], ','));
    for (int j = 0; j < c.length; j++) {
      cells[i][j] = c[j];
    }
  }
  String[] answer = loadStrings("answers/" + num + ".csv");
  int[] a = int(split(answer[0], ','));
  solve_x = a[0];
  solve_y = a[1];
  //println("x: " + solve_x + " y: " + solve_y);
}

void init()
{
  isFlipped = false;
}

void calcSize()
{
 c_height = int(height / 5);
 c_width = int(c_height*1.3);
 c_stroke = int(width * 0.004);
}

void dispBoard()
{
  // 背景の描画
  color background_color = color(50, 50, 50);
  background(background_color);

  // マス目の描画
  int cell_count = 1;
  for (int i = -2; i <= 2; i++) {
    for (int j = -2; j <= 2; j++) {
      int x = int((width / 2) + (c_width * j) - (c_width / 2));
      int y = int((height / 2) + (c_height * i) - (c_height / 2));

      color cell_color = getColor(cells[i+2][j+2]);
      fill(cell_color);
      strokeWeight(c_stroke);
      stroke(0);

      pushMatrix();
      
      translate(x, y, 0);
      rect(0, 0, c_width, c_height);

      fill(0);
      textFont(font);
      textSize(120);
      textAlign(CENTER, CENTER);
      text(cell_count, int(c_width/2), int(c_height/2)-10);

      popMatrix();

      cell_count++;
    }
  }
}

color getColor(int status)
{
  if (status == MY_STATUS) {
    return color(204, 204, 204);
  } else if (status == ENEMY_STATUS1) {
    return color(51, 153, 51);
  } else if (status == ENEMY_STATUS2) {
    return color(102, 102, 204);
  } else if (status == ENEMY_STATUS3) {
    return color(204, 102, 102);
  } else {
    return color(102, 102, 102);
  }
}

void animatedCells()
{
  // マスをひっくり返すときの演出

  // ひっくり返すマスがなくなったらスキップ
  if (targets.isEmpty() == true) {
    isFlipped = false;
    isFinished = true;
    finished_time = millis();
    count = 0;
    return;
  }

  // 一定期間ごとにマスをひっくり返す演出を入れる
  if (count == 5) {
    int[] tmp = (int[])targets.get(0);
    cells[tmp[1]][tmp[0]] = MY_STATUS;
    se.play(0);

    targets.remove(0);
    count = 0;
  } else {
    count++;
  }
}

ArrayList search(int x, int y)
{
  ArrayList result = new ArrayList<int[]>();
  // 方向ごとに探索
  for (int j = -1; j <= 1; j++) {
    for (int i = -1; i <= 1; i++) {
      //println("i : " + i + " j : " + j);
      result.addAll(this.searchOneDirection(x, y, i, j));
    }
  }
  return result;
}

ArrayList searchOneDirection(int x, int y, int x_direction, int y_direction)
{
  // 一方向に対して探索
  ArrayList<int[]> result = new ArrayList<int[]>();
  int next_x = x + x_direction;
  int next_y = y + y_direction;
  boolean result_tmp = enableCellFlipped(next_x, next_y);
  while (result_tmp == true) {
    int[] tmp = {next_x, next_y};
    result.add(tmp);
    //print("searched.");
    //printArray(tmp);

    next_x += x_direction;
    next_y += y_direction;
    result_tmp = enableCellFlipped(next_x, next_y);
  }
  return result;
}

boolean enableCellFlipped(int x, int y)
{
  if (x < 0 || x >= 5 || y < 0 || y >= 5) {
    return false;
  }
  //println("x : " + x + " y : " + y);

  return (cells[y][x] < 0) ? true : false; // 指定する座標が敵のであればひっくり返せるのでtrueを返す
}

void mouseReleased()
{
  se.play(0);

  cells[solve_y][solve_x] = MY_STATUS;
  targets = search(solve_x, solve_y);

  isFlipped = true;
}

void keyTyped()
{
  if (key == 'r') {
    load(1);
    init();
  } else if (key == 's') {
    if (isFlipped == true) {
      return;
    }
    se.play(0);

    cells[solve_y][solve_x] = MY_STATUS;
    targets = search(solve_x, solve_y);

    isFlipped = true;
  } else if(key == 'm') {
    current_board = (current_board == MAX_BOARD_NUM) ? 1 : current_board + 1; // インクリメント、最大に達したら1から
    load(current_board);
    init();
  }
}