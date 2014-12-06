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
ControllIO controll;
Minim minim;//audio context

int gameState = 1;
int CENTRED = -1;
MovingLetters[] letters = new MovingLetters[3];

float safeAngle = 0.1f;
float safeSpeed = 10.0f;

void setup()
{
  size(800, 600);
  smooth();
  
  noCursor();
  
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
    println(landscape.playerVertex);
    
    if (! entity.alive) 
    {
      children.remove(i);
    }
  }
  checkCollisions();
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
  // Check player landed
  int l = landscape.findPlayerVertex(lander);
  if (landscape.isLandSite(l))
  {
    printText("Over land site", font_size.small, 10, 85);
    float py = lander.position.y + lander.h;
    if (py  >= landscape.vertices.get(l).y)
    {
      if (abs(lander.theta) > safeAngle || lander.velocity.mag() > safeSpeed)
      {
        lander.explode = true;
        gameState = 3;
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
}

void draw()
{
  background(0);
  
  switch (gameState)
  {
    case 0:
      //splash();
      break;
    case 1:
      game(true);
      break;
    case 2:
      game(false);
      //gameOver();
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
  return false;
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

