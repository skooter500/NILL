// Uses the following Processing libraries:
// http://www.foobarquarium.de/blog/processing/MovingLetters/
// http://creativecomputing.cc/p5libs/procontroll/
// https://github.com/voidplus/leap-motion-processing

import ddf.minim.*;
import procontroll.*;
import de.ilu.movingletters.*;
import procontroll.*;
import net.java.games.input.*;
import de.voidplus.leapmotion.*;

ArrayList<GameObject> children = new ArrayList<GameObject>();
ArrayList<KittyBox> boxes = new ArrayList<KittyBox>();

boolean[] keys = new boolean[526];
Ship lander;
Landscape landscape;
Explosion playerExplosion;
ControllIO controll;
Minim minim;//audio context
LeapMotion leap;

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
AudioPlayer rescueSound;
PVector gravity = new PVector(0, 20, 0);
float damping = 0.995f;
boolean flipColour;
float worldWidth = 5000;
float landscapeToScreenX;

boolean devMode = false;

// Spawn powerup every 5 seconds
float spawnInterval = 10.0f;
 
boolean sketchFullScreen() {
  return ! devMode;
}

void setup()
{
  if (devMode)
  {
    size(800, 600);
  }
  else
  {
    size(displayWidth, displayHeight);
  }
  smooth();
  noCursor();
  
  minim = new Minim(this);  
  controll = ControllIO.getInstance(this);
  leap = new LeapMotion(this);
  
  explosionSound = minim.loadFile("explosion.wav");
  pickupSound = minim.loadFile("pickup.wav");
  thrustSound = minim.loadFile("thrust.wav");
  blipSound = minim.loadFile("blip.wav");
  rescueSound = minim.loadFile("rescue.wav");
  
  for (font_size size:font_size.values())  
  {
    letters[size.index] = new MovingLetters(this, size.size, 1, 0);
  }  
  reset();      
}

void spawnPowerup()
{
  if (frameCount % ((int) (spawnInterval * 60.0f)) == 0)
  {
    GameObject powerup = new FuelPowerup(); 
    children.add(powerup);
  }
}


void reset()
{
  children.clear();
  boxes.clear();
  landscape = new Landscape(5, .03f, worldWidth);  
  children.add(landscape);  
  lander = new Ship(getController());
  lander.forward = UP;
  lander.left = LEFT;
  lander.right = RIGHT;  
  lander.reset();  
  children.add(lander);
  
  for (int i = 0 ; i < worldWidth / 5 ; i ++)
  {
    children.add(new SmallStar());
  }  
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

boolean isOnScreen(PVector pos)
{
  return (abs(pos.x - lander.position.x) < width / 2); 
}

void game(boolean update)
{    
  float landscapeToScreenX = lander.position.x - (width / 2);
  pushMatrix();
  translate(-landscapeToScreenX, 0);
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
    if (! entity.alive) 
    {
      children.remove(i);
    }
  }
  popMatrix();
  
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
  
  stroke(0, 255, 0);  
  if (lander.fuel <= 0)
  {
    playBlip = true;
    if (flipColour)
    {
      stroke(255, 0, 0);
    }
  }
  printText("Fuel: " + (int) lander.fuel, font_size.small, 10, 60);
  stroke(255, 255, 102);    
  printText("Kitties: " + (int) lander.kitties, font_size.small, 10, 85);
  
  spawnPowerup();
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
}


void checkCollisions()
{
  if (playerExplosion != null && playerExplosion.alive)
  {
    playerExplosion = null;
    gameState = 2;
  }
    
  int l = landscape.findVertex(lander.position.x);  
  if (landscape.isLandSite(l))
  {
    stroke(255, 51, 255);
    printText("Over land site", font_size.small, 10, 110);
    overLandSite = true;
    float py = lander.position.y + lander.halfHeight;
    if (py  >= landscape.vertices.get(l).y && !lander.exploding)
    {      
      if (abs(lander.theta) > safeAngle || lander.velocity.mag() > safeSpeed)
      {
        playerExplosion = new Explosion(lander.vertices, new PVector(width / 2, lander.position.y), lander.colour);
        playerExplosion.theta = lander.theta;
        addGameObject(playerExplosion);        
        lander.exploding = true;
      } 
      else
      {
        lander.theta = 0;
        lander.velocity.x = lander.velocity.y = 0;
        lander.position.y = landscape.vertices.get(l).y - lander.halfHeight;
        lander.landed = true;
        stroke(51, 153, 255);
        printText("Landed", font_size.small, 10, 135);
        KittyBox box = findKittyBox();
        if (box != null)
        {
          playSound(rescueSound);
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
  }
  
  for (int i = 0 ; i < children.size() ; i ++)
  {
    GameObject child = children.get(i);
    if (! (child instanceof Landscape))
    {
      if (child instanceof Ship && !lander.landed && !lander.exploding)
      {  
        // Ship and landscape        
        for(int j = -2 ; j < 3 ; j ++)
        {
          if (PVector.dist(landscape.vertices.get(l + j), lander.position) < lander.halfWidth)
          {
            playerExplosion = new Explosion(lander.vertices, lander.position.get(), lander.colour);
            playerExplosion.theta = lander.theta;
            addGameObject(playerExplosion);
            lander.exploding = true;
          }
        }
        // Ship and powerup
        for (int j = children.size() - 1 ; j >= 0  ; j --)
        {
          GameObject otherChild = children.get(j);
          if (otherChild instanceof Powerup)
          {
            if (PVector.dist(lander.position, otherChild.position) < lander.halfWidth + otherChild.halfWidth)
            {
              ((Powerup)otherChild).applyTo(lander);
              children.remove(otherChild);
              playSound(pickupSound);
            }
          }
        }
      }
      // Powerup and landscape
      if (child instanceof Powerup)
      {        
        float h = landscape.findHeight(child.position.x);
        if (abs(h  - child.position.y) < child.halfHeight)
        {
          FuelPowerup fuel = (FuelPowerup) child;
          Explosion e = new Explosion(fuel.vertices, fuel.position.get(), fuel.colour);
          e.theta = child.theta;
          children.remove(fuel);
          addGameObject(e);
        }
        /*
        l = landscape.findVertex();  
      
        for(int j = -2 ; j < 3 ; j ++)
        {
          if (PVector.dist(landscape.vertices.get(l + j), child.position) < child.halfWidth)
          {
            FuelPowerup fuel = (FuelPowerup) child;
            Explosion e = new Explosion(fuel.vertices, fuel.position.get(), fuel.colour);
            e.theta = child.theta;
            children.remove(fuel);
            addGameObject(e);
          }
        }
        */
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
  
  println(children.size());
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
    if (sound.isPlaying())
    {
      return;
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

