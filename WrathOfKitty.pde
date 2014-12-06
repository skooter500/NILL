import procontroll.*;
import net.java.games.input.*;

// Uses the following Processing libraries:
// http://www.foobarquarium.de/blog/processing/MovingLetters/
// http://creativecomputing.cc/p5libs/procontroll/


import ddf.minim.*;
import procontroll.*;
import de.ilu.movingletters.*;

ArrayList<GameObject> children = new ArrayList<GameObject>();
ArrayList<KittyBox> boxes = new ArrayList<KittyBox>();

boolean[] keys = new boolean[526];
KittyLander lander;
Landscape landscape;
Explosion explosion;
ControllIO controll;
Minim minim;//audio context

int gameState = 0;
int CENTRED = -1;
MovingLetters[] letters = new MovingLetters[3];

float safeAngle = 0.1f;
float safeSpeed = 20.0f;

AudioPlayer explosionSound;
AudioPlayer pickupSound;

void reset()
{
  lander.reset();
  if (explosion != null)
  {
    explosion.alive = false;
  }
}

void splash()
{
  background(0);
  stroke(255);
  
  printText("Kitty Rescue", font_size.large, CENTRED, 100);  
  printText("Programmed by Bryan Duggan", font_size.large, CENTRED, 300);
  if (frameCount / 60 % 2 == 0)
  {
    printText("Press SPACE to play", font_size.large, CENTRED, height - 100);  
  }
  if (checkKey(' '))
  {
    reset();
    gameState = 1;
  }
}

void gameOver()
{
  fill(255);
  stroke(255);  
  printText("Kitty Rescue", font_size.large, CENTRED, 100);  
  if (frameCount / 60 % 2 == 0)
  {
  printText("Game Over", font_size.large, CENTRED, 200);
  }
  stroke(255);  
  printText("Press SPACE to play", font_size.large, CENTRED, height - 100);  
  if (checkKey(' '))
  {
    gameState = 0;
  }
}



void setup()
{
  size(800, 600);
  smooth();
  minim = new Minim(this);
  noCursor();
  
  explosionSound = minim.loadFile("explosion.wav");
  pickupSound = minim.loadFile("pickup.wav");
  
  for (font_size size:font_size.values())  
  {
    letters[size.index] = new MovingLetters(this, size.size, 1, 0);
  }
 
  minim = new Minim(this);  
  controll = ControllIO.getInstance(this);

  landscape = new Landscape(5, .03f, -10000, 10000);
  addGameObject(landscape);
  lander = new KittyLander(getController());
  addGameObject(lander);
}

void printText(String text, font_size size, int x, int y)
{
  if (x == CENTRED)
  {
    x = (width / 2) - (int) (size.size * (float) text.length() / 2.5f);
  }
  letters[size.index].text(text, x, y);  
}

void game(boolean update)
{    
  for (int i = children.size()-1; i >= 0; i--) 
  {
    GameObject entity = children.get(i);
    if (update)
    {      
      entity.update();      
      landscape.position.x = (width / 2) - (lander.position.x);
    }
    entity.display();
    landscape.playerVertex = landscape.findPlayerVertex(lander);    
    if (! entity.alive) 
    {
      children.remove(i);
    }
  }
  checkCollisions();
  stroke(0, 255, 255);
  printText("Speed: " + (int) lander.velocity.mag(), font_size.small, 10, 10);
  printText("Fuel: " + (int) lander.fuel, font_size.small, 10, 35);
  printText("Kitties: " + (int) lander.kitties, font_size.small, 10, 60);
}

KittyBox findKittyBox()
{
  // Binary search
    int lo = 0;
    int hi = boxes.size() - 1;
    PVector pos = lander.position.get();
    for(KittyBox box:boxes)
    {
      if (PVector.dist(box.position, pos) < 50)
      {
        return box;
      }
    }
    return null;
}


void checkCollisions()
{
  if (explosion != null && explosion.alive)
  {
    explosion = null;
    gameState = 2;
  }
  
  
  
  /*
  if (!lander.exploding)
  {
      Explosion explosion = new Explosion(lander.vertices, new PVector(width / 2, lander.position.y));
      lander.exploding = true;
      addGameObject(explosion);
      
  }
  */
  // Check player landed
  if (lander.exploding)
  {
    return;
  }
  int l = landscape.findPlayerVertex(lander);
  if (landscape.isLandSite(l))
  {
    stroke(255, 153, 255);
    printText("Over land site!", font_size.small, 10, 85);
    float py = lander.position.y + lander.h;
    if (py  >= landscape.vertices.get(l).y)
    {
      lander.velocity.x = lander.velocity.y = 0;
      if (abs(lander.theta) > safeAngle || lander.velocity.mag() > safeSpeed)
      {
        explosion = new Explosion(lander.vertices, new PVector(width / 2, lander.position.y));
        explosion.theta = lander.theta;
        addGameObject(explosion);
        playSound(explosionSound);
        lander.exploding = true;
        //gameState = 3;
      } 
      else
      {
        lander.theta = 0;
        lander.velocity.x = lander.velocity.y = 0;
        lander.landed = true;
        printText("Landed", font_size.small, 10, 110);
        KittyBox box = findKittyBox();
        if (box != null)
        {
          lander.kitties += box.kitties;
          
          
          children.remove(box);
          
        }
      }
    }    
  }
  else
  {
    float py = lander.position.y + lander.h + 10;    
    if (py  >= landscape.vertices.get(l).y)
    {
      explosion = new Explosion(lander.vertices, new PVector(width / 2, lander.position.y));
        explosion.theta = lander.theta;
        addGameObject(explosion);
        lander.exploding = true;
                playSound(explosionSound);

    }
  }
}

void draw()
{
  background(0);
  
  switch (gameState)
  {
    case 0:
      splash();
      break;
    case 1:
      game(true);
      break;
    case 2:
      game(true);
      gameOver();
      break;  
  }
}


void addGameObject(GameObject o)
{
  children.add(o);
}

void playSound(AudioPlayer sound)
{
  if (sound == null)
  {
    return;
  }
  sound.rewind();
  sound.play(); 
}

boolean checkKey(int k)
{
  if (keys.length >= k) 
  {
    return keys[k] || keys[Character.toUpperCase(k)];  
  }
  return false;
}

boolean sketchFullScreen() {
  return true;
}

ControllDevice getController()
{
  // Add all the xbox controllers
  for(int i = 0; i < controll.getNumberOfDevices(); i++){
    ControllDevice device = controll.getDevice(i);
    if (device.getName().toUpperCase().indexOf("XBOX 360") != -1)
    {
      return device;
    }    
  }
  return null;
}


void keyPressed()
{ 
  keys[keyCode] = true;
}
 
void keyReleased()
{
  keys[keyCode] = false; 
}

