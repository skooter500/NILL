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

boolean overLandSite;

int gameState = 0;
int CENTRED = -1;
MovingLetters[] letters = new MovingLetters[3];

float safeAngle = 0.2f;
float safeSpeed = 30.0f;

AudioPlayer explosionSound;
AudioPlayer pickupSound;
AudioPlayer blipSound;
AudioPlayer thrustSound;

boolean flipColour;

void setup()
{
  size(displayWidth, displayHeight);
  smooth();
  minim = new Minim(this);
  noCursor();
  
  explosionSound = minim.loadFile("explosion.wav");
  pickupSound = minim.loadFile("pickup.wav");
  thrustSound = minim.loadFile("thrust.wav");
  blipSound = minim.loadFile("blip.wav");
  
  for (font_size size:font_size.values())  
  {
    letters[size.index] = new MovingLetters(this, size.size, 1, 0);
  }
 
  minim = new Minim(this);  
  controll = ControllIO.getInstance(this);

  lander = new KittyLander(getController());
  lander.forward = UP;
  lander.left = LEFT;
  lander.right = RIGHT;
  reset();      
}


void reset()
{
  lander.reset();
  children.clear();
  boxes.clear();
  children.add(lander);
  landscape = new Landscape(5, .03f, -5000, 5000);
  children.add(landscape);  
}

void splash()
{
  background(0);
  stroke(255);
  
  printText("Kitty Lander", font_size.large, CENTRED, 100);  
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
  printText("Kitty Lander", font_size.large, CENTRED, 100);  
  if (frameCount / 60 % 2 == 0)
  {
    printText("Game Over", font_size.large, CENTRED, 200);
  }
  printText("Press SPACE to play", font_size.large, CENTRED, 300);
  
  stroke(255);  
  if (checkKey(' '))
  {
    reset();
    gameState = 1;
  }
}

boolean playBlip = false;

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
  playBlip = false;
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
  if (overLandSite && lander.velocity.mag() > safeSpeed)
  {
    if (flipColour)
    {
      stroke(255, 0, 0);
    }
  }
  printText("Speed: " + (int) lander.velocity.mag(), font_size.small, 10, 10);
  stroke(0, 255, 255);
  if (overLandSite && abs(lander.theta) > safeAngle)
  {
    if (flipColour)
    {
      stroke(255, 0, 0);
    }
  }
  printText("Angle: " + (int) degrees(lander.theta), font_size.small, 10, 35);
  stroke(0, 255, 255);
  
  if (lander.fuel <= 0)
  {
    playBlip = true;
    if (flipColour)
    {
      stroke(255, 0, 0);
    }
  }
  printText("Fuel: " + (int) lander.fuel, font_size.small, 10, 60);
  stroke(0, 255, 255);    
  printText("Kitties: " + (int) lander.kitties, font_size.small, 10, 85);
}

KittyBox findKittyBox()
{
  // Binary search
    int lo = 0;
    int hi = boxes.size() - 1;
    PVector pos = lander.position.get();
   
    while (lo <= hi) 
    {
      int mid = lo + (hi - lo) / 2;      
      if (PVector.dist(boxes.get(mid).position, pos) < landscape.landSiteWidth / 2)
      {
        return boxes.get(mid);
      }
      else
      {
        if (pos.x < boxes.get(mid).position.x) 
        {
            hi = mid - 1;
        }
        else
        {
          lo = mid + 1;
        }
      }
    }    
    return null;
    
    // Binary search
    /*
    PVector pos = lander.position.get();
    for(KittyBox box:boxes)
    {
      if (PVector.dist(box.position, pos) < 50)
      {
        return box;
      }
    }
    return null;
    */
}


void checkCollisions()
{
  if (explosion != null && explosion.alive)
  {
    explosion = null;
    gameState = 2;
  }
    
  
  // Check player landed
  if (lander.exploding)
  {
    return;
  }
  
  int l = landscape.findPlayerVertex(lander);
  float py = lander.position.y + lander.halfHeight;
  if (landscape.isLandSite(l))
  {
    stroke(255, 51, 255);
    printText("Over land site", font_size.small, 10, 110);
    overLandSite = true;
    if (py  >= landscape.vertices.get(l).y)
    {      
      if (abs(lander.theta) > safeAngle || lander.velocity.mag() > safeSpeed)
      {
        explosion = new Explosion(lander.vertices, new PVector(width / 2, lander.position.y));
        explosion.theta = lander.theta;
        addGameObject(explosion);
        playSound(explosionSound);
        lander.exploding = true;
      } 
      else
      {
        lander.theta = 0;
        lander.velocity.x = lander.velocity.y = 0;
        lander.landed = true;
        stroke(51, 153, 255);
        printText("Landed", font_size.small, 10, 135);
        KittyBox box = findKittyBox();
        if (box != null)
        {
          playSound(pickupSound);
          lander.kitties += box.kitties;
          boxes.remove(box);
          children.remove(box);          
        }
      }
    }    
  }
  else
  {
    overLandSite = false;
    
    for(int i = -2 ; i < 3 ; i ++)
    {
      if (PVector.dist(landscape.vertices.get(l + i), lander.position) < lander.halfWidth)
      {
        explosion = new Explosion(lander.vertices, new PVector(width / 2, lander.position.y));
        explosion.theta = lander.theta;
        addGameObject(explosion);
        lander.exploding = true;
        playSound(explosionSound);
      }
    }        
  }
}

void draw()
{
  background(0);
  
  if (frameCount % 10 == 0)
  {
    flipColour = ! flipColour;          
  }
  if (playBlip && gameState == 1 && frameCount % 60 == 0)
  {
    playSound(blipSound);
  }
  
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
  playSound(sound, false);
}


void playSound(AudioPlayer sound, boolean loop)
{
  if (sound == null)
  {
    return;
  }
  if (!loop)
  {
    sound.rewind();
  }
  else
  {
    sound.loop();
    if (!sound.isPlaying())
    {
      
    }
  }    
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

