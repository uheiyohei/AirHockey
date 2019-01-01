import fisica.*;

FWorld field;
FLine centerLine;

Puck puck;
Mallet player;
Opponent opponent;

FMouseJoint mouseJoint; // Connection between player's mallet and mouse's movement

PFont gameFont;

final float EDGE_WIDTH = 20;

int playerScore = 0;
int opponentScore = 0;

// Goal Scene
boolean isPlayersGoal = true;
boolean isGoalScene = false;
int goalSceneCount = 0; // Count the duration of goal scene

void setup() {
  size(600, 800);
  smooth();
  
  gameFont = loadFont("Monaco-48.vlw");

  Fisica.init(this);

  field = new FWorld();
  field.setGravity(0, 0);

  setupEdges();

  centerLine = new FLine(0, height / 2, width, height / 2);
  centerLine.setStroke(255);
  centerLine.setSensor(true);
  field.add(centerLine);

  puck = new Puck(40);
  puck.setPosition(width / 2, height / 4 * 3);
  field.add(puck);

  player = new Mallet(60);
  player.setFill(255, 100, 100);
  field.add(player);

  opponent = new Opponent(60, 25);
  opponent.setPosition(width / 2, height / 4);
  opponent.setFill(100, 100, 255);
  field.add(opponent);

  mouseJoint = new FMouseJoint(player, 0, 0);
  mouseJoint.setNoStroke();
  field.add(mouseJoint);
}

void draw() {
  background(0);

  field.draw();
  field.step();
  
  textFont(gameFont, 30);
  text(String.valueOf(playerScore), 50, 750);
  text(String.valueOf(opponentScore), 50, 70);
  
  if (mouseY < height / 2 + 30) { // Restrict the range of player's movement
    mouseY = height / 2 + 30;
  }
  mouseJoint.setTarget(mouseX, mouseY); // Join player's mallet to mouse

  if (isGoalScene) {
    if (goalSceneCount > 180) { // 3 sec.
      isGoalScene = false;
      goalSceneCount = 0;
      puck.recreateInWorld();
      puck.setVelocity(0, 0);
      
      if (isPlayersGoal) {
        puck.setPosition(width / 2, height / 4);
      } else {
        puck.setPosition(width / 2, height / 4 * 3);
        
        // Opponent will be back to the original position
        opponent.destinationX = width / 2;
        opponent.destinationY = height / 4;
        opponent.setSpeed();
      }
      
    } else {
      textFont(gameFont, 48);
      if ((goalSceneCount >= 0 && goalSceneCount < 20) || (goalSceneCount >= 40 && goalSceneCount < 60) || (goalSceneCount >= 80 && goalSceneCount < 100) || 
        (goalSceneCount >= 120 && goalSceneCount < 140) || (goalSceneCount >= 160 && goalSceneCount < 180)) { // Text display turns On and off
        if (isPlayersGoal) {
          text("GOAL!!", width / 2 - 85, height / 4 * 3);
        } else {
          text("GOAL!!", width / 2 - 85, height / 4);
        }
      }

      goalSceneCount++;
    }
    return;
  } 
  
  if (puck.y < 0 && puck.x > width / 3 && puck.x < width / 3 * 2) { // Player's goal
    playerScore++;
    isPlayersGoal = true;
    isGoalScene = true;
    return;
  } else if (puck.y > height && puck.x > width / 3 && puck.x < width / 3 * 2) { // Opponent's goal
    opponentScore++;
    isPlayersGoal = false;
    isGoalScene = true;
    return;
  }

  opponent.checkPuckCondition();
  opponent.move();

  // If puck is outside the field
  if (puck.x < EDGE_WIDTH + puck.r) { 
    puck.setPosition(EDGE_WIDTH + puck.r, puck.y);
  } else if (puck.x > width - EDGE_WIDTH - puck.r) {
    puck.setPosition(width - EDGE_WIDTH - puck.r, puck.y);
  }
  if (puck.y < 0 && (puck.x < width / 3 || puck.x > width / 3 * 2)) {
    puck.setPosition(puck.x, EDGE_WIDTH + puck.r);
  }
}

void setupEdges() {
  FBox[] horizontalEdges = {edge(true, 0, 0), edge(true, width * (2.0 / 3.0), 0), edge(true, 0, height - EDGE_WIDTH), edge(true, width * (2.0 / 3.0), height - EDGE_WIDTH)};
  for (int i = 0; i < horizontalEdges.length; i++) {
    field.add(horizontalEdges[i]);
  }

  FBox[] verticalEdges = {edge(false, 0, EDGE_WIDTH), edge(false, width - EDGE_WIDTH, EDGE_WIDTH)};
  for (int i = 0; i < verticalEdges.length; i++) {
    field.add(verticalEdges[i]);
  }
}

void contactEnded(FContact contact) {
  // When player or opponent hit the puck
  if ((contact.getBody1() == player && contact.getBody2() == puck) || (contact.getBody1() == puck && contact.getBody2() == player) || 
    (contact.getBody1() == opponent && contact.getBody2() == puck) || (contact.getBody1() == puck && contact.getBody2() == opponent)) {
    opponent.setDestinationWhenReceiving();
    opponent.setSpeed();
  }
}

FBox edge(boolean isHorizontal, float x, float y) {
  float w = 0;
  float h = 0;

  if (isHorizontal) {
    w = width / 3;
    h = EDGE_WIDTH;
  } else {
    w = EDGE_WIDTH;
    h = height - (EDGE_WIDTH * 2);
  }

  FBox edge = new FBox(w, h);
  edge.setPosition(x + w / 2, y + h / 2); // Calculate center position
  edge.setRestitution(0.5);
  edge.setStatic(true);
  edge.setFill(255);
  edge.setNoStroke();

  return edge;
}

class Puck extends FCircle {
  float x;
  float y;
  float r;
  float speedX;
  float speedY;

  Puck(float size) {
    super(size);
    this.setDensity(1.0);
    this.setGrabbable(false);
    this.setFill(255, 255, 200);
    this.setNoStroke();

    this.x = 0;
    this.y = 0;
    this.r = size / 2;
    this.speedX = 0;
    this.speedY = 0;
  }

  @Override
    void draw(processing.core.PGraphics applet) {
    super.draw(applet);
    this.x = this.getX();
    this.y = this.getY();
    this.speedX = this.getVelocityX();
    this.speedY = this.getVelocityY();
  }
}

class Mallet extends FCircle {
  float x;
  float y;
  float r;

  Mallet(float size) {
    super(size);
    this.setDensity(1.0);
    this.setGrabbable(false);
    this.setNoStroke();

    this.x = 0;
    this.y = 0;
    this.r = size / 2;
  }

  @Override
    void draw(processing.core.PGraphics applet) {
    super.draw(applet);
    this.x = this.getX();
    this.y = this.getY();
  }
}

class Opponent extends Mallet {
  float maxSpeed;
  float speedX;
  float speedY;
  float destinationX;
  float destinationY;

  Opponent(float size, float maxSpeed) {
    super(size);
    this.maxSpeed = maxSpeed;
    this.speedX = 0;
    this.speedY = 0;
    this.destinationX = 0;
    this.destinationY = 0;
    this.setStatic(true);
  }

  void checkPuckCondition() {
    if (puck.y < height / 2 - puck.r && Math.abs(puck.speedY) < 600) { // When puck is in opponent's area and it isn't fast
      if (this.speedX == 0 && this.speedY == 0) {
        setDestinationWhenAttacking();
        setSpeed();
      }
    }
  }

  void move() {
    if (this.speedX != 0 || this.speedY != 0) {
      if ((this.x < this.destinationX + this.maxSpeed && this.x > this.destinationX - this.maxSpeed) &&
        (this.y < this.destinationY + this.maxSpeed && this.y > this.destinationY - this.maxSpeed)) { // Reached at the destination
        this.speedX = 0;
        this.speedY = 0;
        this.destinationX = 0;
        this.destinationY = 0;
      } else {
        this.setVelocity(this.speedX * 60, this.speedY * 60);
        this.setPosition(this.x + this.speedX, this.y + this.speedY);
      }
    }
  }

  void setSpeed() { // Calculate and set the speed of opponent
    if (this.destinationX == 0 && this.destinationY == 0) {
      return;
    }
  
    float xyDifference = (this.destinationX - this.x) / (this.destinationY - this.y);

    if (Float.isNaN(xyDifference)) {
      if (this.destinationX - this.x > 0) {
        xyDifference = 0;
      } else {
        return;
      }
    }

    if (xyDifference > 1.0 || xyDifference < -1.0) {
      if (this.destinationX - this.x > 0) {
        this.speedX = this.maxSpeed;
        this.speedY = this.maxSpeed / xyDifference;
      } else if (this.destinationX - this.x < 0) {
        this.speedX = -1 * this.maxSpeed;
        this.speedY = -1 * (this.maxSpeed / xyDifference);
      }
    } else if (xyDifference == 1) {
      if (this.destinationX - this.x > 0) {
        this.speedX = this.maxSpeed;
        this.speedY = this.maxSpeed;
      } else if (this.destinationX - this.x < 0) {
        this.speedX = -1 * this.maxSpeed;
        this.speedY = -1 * this.maxSpeed;
      }
    } else if (xyDifference < 1 && xyDifference > 0) {
      if (this.destinationX - this.x > 0) {
        this.speedX = this.maxSpeed * xyDifference;
        this.speedY = this.maxSpeed;
      } else if (this.destinationX - this.x < 0) {
        this.speedX = this.maxSpeed * xyDifference * -1;
        this.speedY = this.maxSpeed * -1;
      }
    } else if (xyDifference == 0) {
      if (this.destinationX - this.x == 0) {
        this.speedY = this.maxSpeed;
      } else if (this.destinationY - this.y == 0) {
        this.speedX = this.maxSpeed;
      }
    } else if (xyDifference < 0 && xyDifference > -1) {
      if (this.destinationX - this.x > 0) {
        this.speedX = this.maxSpeed * xyDifference * -1;
        this.speedY = -1 * this.maxSpeed;
      } else if (this.destinationX - this.x < 0) {
        this.speedX = this.maxSpeed * xyDifference;
        this.speedY = this.maxSpeed;
      }
    } else if (xyDifference == -1) {
      if (this.destinationX - this.x > 0) {
        this.speedX = this.maxSpeed;
        this.speedY = -1 * this.maxSpeed;
      } else if (this.destinationX - this.x < 0) {
        this.speedX = -1 * this.maxSpeed;
        this.speedY = this.maxSpeed;
      }
    }
  }

  void setDestinationWhenReceiving() { // Calculate player's hit course and set the destination of opponent's mallet
    // y = ax + b
    float a = puck.speedY / puck.speedX;
    if (puck.speedY > 0) {
      a *= -1;
    }

    float b = puck.y - a * puck.x;
    float puckDestinationY = EDGE_WIDTH + this.r * 3 + puck.r;

    float x = (puckDestinationY - b) / a; // x = (y - b) / a

    while (x < EDGE_WIDTH + puck.r || x > width - EDGE_WIDTH - puck.r) { // Puck will hit the side edge

      if (x < EDGE_WIDTH + puck.r) { // It will hit the left edge
        float y = a * (EDGE_WIDTH + puck.r) + b; // Y when x = EDGE_WIDTH + puck.r
        b = y - (a * -1) * (EDGE_WIDTH + puck.r); // New b
      } else if (x > width - EDGE_WIDTH - puck.r) { // It will hit the right edge
        float y = a * (width - EDGE_WIDTH - puck.r) + b; // Y when x = width - EDGE_WIDTH - puck.r
        b = y - (a * -1) * (width - EDGE_WIDTH - puck.r); //New b
      }

      a *= -1;
      x = (puckDestinationY - b) / a;
    }

    if (x < EDGE_WIDTH + this.r) {
      this.destinationX = EDGE_WIDTH + this.r;
    } else if (x > width - EDGE_WIDTH - this.r) {
      this.destinationX = width - EDGE_WIDTH - this.r;
    } else {
      this.destinationX = x;
    }

    this.destinationY = EDGE_WIDTH + this.r * 2;
  }

  void setDestinationWhenAttacking() { // Calculate the shot course and set the destination of opponent's mallet
    float goalMinX = width / 3.0 + puck.r;
    float goalMaxX = width / 3.0 * 2.0 - puck.r;
    float goalY = height - EDGE_WIDTH;

    // Use rays to search course
    FRaycastResult result = new FRaycastResult(); 

    // y = ax + b
    float a = 0;
    float b = 0;

    float currentGoalX = goalMinX; // A Variable to find proper shot area in the goal
    while (currentGoalX <= goalMaxX) {
      a = (goalY - puck.y) / (currentGoalX - puck.x);
      b = puck.y - a * puck.x;

      float underCenterLineX = (height / 2.0 + 1.0 - b) / a;
      FBody body = field.raycastOne(underCenterLineX, height / 2.0 + 1.0, currentGoalX, goalY, result, true);

      if (body == null) { // Player's mallet doesn't interrupt hit course
        break;
      } else {
        currentGoalX += 10;
      }
    }

    if (currentGoalX > goalMaxX) { // Shot course couldn't be found
      this.destinationX = width / 2;
      this.destinationY = height / 4;
    } else {
      if (puck.y - puck.r < EDGE_WIDTH + this.r) { // If puck is on the upper edge
        this.destinationY = EDGE_WIDTH + this.r;
      } else {
        this.destinationY = puck.y - puck.r;
      }

      if ((this.destinationY - b) / a < EDGE_WIDTH + this.r) { // If puck is on the side edge
        this.destinationX = EDGE_WIDTH + this.r;
      } else if ((this.destinationY - b) / a > width - EDGE_WIDTH - this.r) {
        this.destinationX = width - EDGE_WIDTH - this.r;
      } else {
        this.destinationX = (this.destinationY - b) / a;
      }
    }
  }
}
