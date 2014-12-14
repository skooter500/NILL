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
int winState = 0;
int CENTRED = -1;
MovingLetters[] letters = new MovingLetters[3];

float safeAngle = 0.2f;
float safeSpeed = 30.0f;
float timeDelta = 1.0f / 60.0f;

AudioPlayer explosionSound;
AudioPlayer pickupSound;
AudioPlayer blipSound;
AudioPlayer rescueSound;
AudioPlayer soundtrack;
AudioPlayer thrustSound;

PVector gravity = new PVector(0, 20, 0);
float damping = 0.995f;
boolean flipColour;
float worldWidth = 5000;
float landscapeToScreenX;
float totalKitties = 0;

boolean devMode = false;

// Spawn powerup every 5 seconds
float spawnInterval = 5.0f;
 
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
  blipSound = minim.loadFile("blip.wav");
  rescueSound = minim.loadFile("rescue.wav");
  soundtrack =  minim.loadFile("LunarLanding.mp3");
  thrustSound = minim.loadFile("thrust.mp3");
  for (font_size size:font_size.values())  
  {
    letters[size.index] = new MovingLetters(this, size.size, 1, 0);
  }  
 
}

void spawnPowerup()
{
  if (frameCount % ((int) (spawnInterval * 60.0f)) == 0)
  {
    int i = (int) random(0, 2);
    GameObject powerup = null;    
    switch (i)
    {
      case 0:
        powerup = new Asteroid();
        break;        
      default:              
        powerup = new FuelPowerup();
        break;
    }    
    children.add(powerup);
  }
}

PVector randomOffscreenPoint(float border)
{    
  float left = lander.position.x - width / 2;
  return new PVector(random(left, left + width), -border);    
}

void reset()
{
  children.clear();
  boxes.clear();
  totalKitties = 0;
  landscape = new Landscape(5, .03f, worldWidth);  
  children.add(landscape);  
  lander = new Ship(getController());
  lander.forward = UP;
  lander.left = LEFT;
  lander.right = RIGHT;  
  lander.reset();  
  children.add(lander);
  playSound(soundtrack, true);

  for (int i = 0 ; i < worldWidth / 5 ; i ++)
  {
    children.add(new SmallStar());
  }  
}

void splash()
{
  background(0);
  stroke(255);
  
  printText("NILL", font_size.large, CENTRED, 100);  
  printText("Non-Infinite Luner Lander", font_size.large, CENTRED, 200);
  printText("Programmed by Bryan Duggan", font_size.large, CENTRED, 300);
  printText("Soundtrack by Kevin Doyle", font_size.large, CENTRED, 400);
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
  printText("NILL", font_size.large, CENTRED, 100);  
  if (frameCount / 60 % 2 == 0)
  {
    if (winState == 0)
    {
      printText("You crashed - Game Over", font_size.large, CENTRED, 200);
    }    
    else if (winState == 1)
    {
      printText("You ran out of fuel - Game Over", font_size.large, CENTRED, 200);      
    }
    else
    {
      printText("All Pods collected - Game Over", font_size.large, CENTRED, 200);
    }
  }
  printText("Press SPACE to play again", font_size.large, CENTRED, 300);
  
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
  checkWinState();
  drawHud();
  spawnPowerup();
}

void checkWinState()
{
  if (lander.escaping)
  {
    return;
  }
  if (boxes.size() == 0)
  {
    lander.escaping = true;
    playSound(thrustSound);
  }
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
  
  if (lander.landed && lander.fuel == 0)
  {
    gameState = 2;
    winState = 1;
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
        winState = 0;
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
            winState = 0;
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
              if (! (otherChild instanceof Asteroid))
               { 
                playSound(pickupSound);
               }
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
          GameObject powerUp = (GameObject) child;
          Explosion e = new Explosion(powerUp.vertices, powerUp.position.get(), powerUp.colour);
          e.theta = powerUp.theta;
          children.remove(powerUp);
          addGameObject(e);
        }        
      }
    }
  }
}

boolean muteToggle = true;

void draw()
{  
  background(0);
  
  if (checkKey('M') )
  {
    if (muteToggle)
    {
      if (soundtrack.isMuted())
      {
        soundtrack.unmute();
      }
      else
      {
        soundtrack.mute();
      }
    }
    muteToggle = false;
  }
  else
  {
    muteToggle = true;
  }
  
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

void drawHud()
{
  stroke(0, 255, 255);
  if (overLandSite && lander.velocity.mag() > safeSpeed)
  {
    if (flipColour)
    {
      stroke(255, 0, 0);
    }
  }
  float linesWidth = width / 3;
  float barHeight = 18;
  float barStart = 90;
  printText("Speed: ", font_size.small, 10, 10);
  line(barStart, 10 + barHeight, barStart + map(lander.velocity.mag(), 0, lander.maxSpeed, 0, linesWidth), 10 + barHeight);
  line(barStart, 10 + barHeight, barStart, 10);
  stroke(255, 204, 204);
  if (overLandSite && abs(lander.theta) > safeAngle)
  {
    if (flipColour)
    {
      stroke(255, 0, 0);
    }
  }
  float halfLineWidth = linesWidth / 4;
  float mapTo = map(lander.theta, -PI, PI, -halfLineWidth, halfLineWidth);  
  printText("Angle: ", font_size.small, 10, 35);  
  line(barStart + halfLineWidth, 35 + barHeight, barStart + halfLineWidth + mapTo, 35 + barHeight);  
  line(barStart + halfLineWidth, 35, barStart + halfLineWidth, 35 + barHeight);  
  stroke(0, 255, 0);  
  if (lander.fuel <= 100)
  {
    playBlip = true;
    if (flipColour)
    {
      stroke(255, 0, 0);
    }
  }
  printText("Fuel:", font_size.small, 10, 60);
  line(barStart, 60 + barHeight, barStart + map(lander.fuel, 0, lander.maxFuel, 0, linesWidth), 60 + barHeight);  
  line(barStart, 60, barStart, 60 + barHeight);
  stroke(255, 255, 102);    
  printText("PODS:", font_size.small, 10, 85);
  
  line(barStart, 85 + barHeight, barStart + map(lander.kitties, totalKitties, 0, 0, linesWidth), 85 + barHeight);  
  line(barStart, 85, 90, 85 + barHeight);  
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
  sound.setGain(14);
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

