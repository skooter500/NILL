import de.voidplus.leapmotion.*;

import net.java.games.input.*;
import org.gamecontrolplus.*;
import org.gamecontrolplus.gui.*;

// Uses the following Processing libraries:
// https://github.com/voidplus/leap-motion-processing

import ddf.minim.*;

ArrayList<GameObject> children = new ArrayList<GameObject>();
ArrayList<KittyBox> boxes = new ArrayList<KittyBox>();

Ship lander = new Ship();
GameObject[] splashPowerups = {new Ship(false), new KittyBox(), new FuelPowerup(), new Asteroid()};  
String[] splashPowerupText = {"Lander", "Pod", "Fuel", "Asteroid"};

boolean[] keys = new boolean[526];

Landscape landscape;
Explosion playerExplosion;
Minim minim;//audio context
LeapMotion leap;
ControlDevice device;

boolean overLandSite;

int gameState = 0;
int winState = 0;
int CENTRED = -1;
PFont[] fonts = new PFont[3];

float safeAngle = 0.2f;
float safeSpeed = 30.0f;
float timeDelta = 0;

ControlIO control;


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
 
/*boolean sketchFullScreen() {
  return ! devMode;
}
*/

void setup()
{
  size(800, 800);
  //fullScreen();
  smooth();
  noCursor();
  
  minim = new Minim(this);  
  leap = new LeapMotion(this);
  
  explosionSound = minim.loadFile("explosion.wav");
  pickupSound = minim.loadFile("pickup.wav");
  blipSound = minim.loadFile("blip.wav");
  rescueSound = minim.loadFile("rescue.wav");
  soundtrack =  minim.loadFile("LunarLanding.mp3");
  thrustSound = minim.loadFile("thrust.mp3");
  
  fonts[0] = createFont("Hyperspace Bold.otf", 24);
  fonts[1] = createFont("Hyperspace Bold.otf", 32);
  fonts[2] = createFont("Hyperspace Bold.otf", 48);
  
  control = ControlIO.getInstance(this);

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
  lander = new Ship();
  lander.device = device;
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
  
  printText("NILL - NILLs not Luner Lander", font_size.large, CENTRED, 100);  
  printText("Programmed by Bryan Duggan, Music by Kevin Doyle", font_size.medium, CENTRED, 200);  
  printText("Land safely to retrieve all the pods", font_size.small, CENTRED, 300);  
  printText("Avoid the asteroids and don't crash", font_size.small, CENTRED, 350);
  printText("Collect more fuel so you dont run out", font_size.small, CENTRED, 400);
  printText("Keys: LEFT And RIGHT to steer, space to thrust", font_size.small, CENTRED, 450);
  printText("XBOX Controller: Left stick to steer, Trigger to thrust", font_size.small, CENTRED, 500);
  printText("Leap motion: Rotate hand to steer, press down to thrust", font_size.small, CENTRED, 550);
  
  for(int i = 0 ; i < splashPowerups.length ; i ++)
  {
    int x = (width / 2) - 80;
    int y = 650 + (i * 50);
    splashPowerups[i].position.x = x;
    splashPowerups[i].position.y = y; 
    splashPowerups[i].update();
    splashPowerups[i].display();
    stroke(255);  
    printText(splashPowerupText[i], font_size.small, x + 50, y + 10);
  }
  
  stroke(255);  
  if (frameCount / 60 % 2 == 0)
  {
    printText("Press START or SPACE to play", font_size.large, CENTRED, height - 100);  
  }
  if (checkForNewControlers() || checkKey(' '))
  {
    reset();
    gameState = 1;
  }
}

void gameOver()
{
  fill(255);
  stroke(255);  
  printText("NILL", font_size.large, CENTRED, 300);  
  if (frameCount / 60 % 2 == 0)
  {
    if (winState == 0)
    {
      fill(255, 0, 0);
      printText("You crashed - Game Over", font_size.large, CENTRED, 400);
    }    
    else if (winState == 1)
    {
      fill(255, 0, 0);
      printText("You ran out of fuel - Game Over", font_size.large, CENTRED, 400);      
    }
    else
    {
      fill(0, 255, 255);
      printText("All Pods collected - Game Over", font_size.large, CENTRED, 400);
    }
  }
  fill(255);  
  stroke(255); 
  printText("Press START or SPACE to play again", font_size.large, CENTRED, 500);
  
  if (checkForNewControlers() || checkKey(' '))
  {
    reset();
    gameState = 1;
  }
}

boolean playBlip = false;

void printText(String text, font_size size, float x, float y)
{
  textFont(fonts[size.index]);
  /*
  if (x == CENTRED)
  {
    x = (width / 2) - (int) (size.size * (float) text.length() / 2.5f);
  }
  letters[size.index].text(text, x, y);
  */
  
  if (x == CENTRED)
  {
    x = (width / 2) - (textWidth(text) / 2);
  }  
    
  text(text, x, y);
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

boolean checkForNewControlers()
{
  // Add all the xbox controllers
  for(int i = 0; i < control.getNumberOfDevices(); i++){
    ControlDevice device = control.getDevice(i);
    if (device.getName().toUpperCase().indexOf("XBOX 360") != -1)
    {
      if (device.getButton(7).pressed())
      {
        println("New player joined");
        this.device = device;
        return true;
      }        
    }    
  }
  return false;
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
    fill(255, 51, 255);
    printText("Over land site", font_size.small, 10, 170);
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
long last = 0;

void draw()
{  
  background(0);
  strokeWeight(2);
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
  
  long now = millis();
  timeDelta = (now - last) / 1000.0f;
  last = now;
}

void drawHud()
{
  fill(0, 255, 255);
  stroke(0, 255, 255);
  if (overLandSite && lander.velocity.mag() > safeSpeed)
  {
    if (flipColour)
    {
      fill(255, 0, 0);
      stroke(255, 0, 0);
    }
  }
  float linesWidth = width / 4;
  float barHeight = 16;
  float barStart = 100;
  printText("Speed: ", font_size.small, 10, 25);
  line(barStart, 10 + barHeight, barStart + map(lander.velocity.mag(), 0, lander.maxSpeed, 0, linesWidth), 10 + barHeight);
  line(barStart, 10 + barHeight, barStart, 10);
  fill(255, 204, 204);
  stroke(255, 204, 204);
  if (overLandSite && abs(lander.theta) > safeAngle)
  {
    if (flipColour)
    { 
      stroke(255, 0, 0);
      fill(255, 0, 0);
    }
  }
  float halfLineWidth = linesWidth / 2;
  float mapTo = map(lander.theta, -PI, PI, -halfLineWidth, halfLineWidth);  
  printText("Angle: ", font_size.small, 10, 55);  
  line(barStart + halfLineWidth, 40 + barHeight, barStart + halfLineWidth + mapTo, 40 + barHeight);  
  line(barStart + halfLineWidth, 40, barStart + halfLineWidth, 40  + barHeight);  
  stroke(0, 255, 0);  
  fill(0, 255, 0);  
  if (lander.fuel <= 100)
  {
    playBlip = true;
    if (flipColour)
    {
      stroke(255, 0, 0);
      fill(255, 0, 0);
    }
  }
  printText("Fuel:", font_size.small, 10, 85);
  line(barStart, 70+ barHeight, barStart + map(lander.fuel, 0, lander.maxFuel, 0, linesWidth), 70 + barHeight);  
  line(barStart, 70, barStart, 70 + barHeight);
  stroke(255, 255, 102);    
  fill(255, 255, 102);    
  printText("PODS:", font_size.small, 10, 115);
  
  line(barStart, 100 + barHeight, barStart + map(lander.kitties, totalKitties, 0, 0, linesWidth), 100 + barHeight);  
  line(barStart, 100, barStart, 100 + barHeight);  
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
  
void keyPressed()
{ 
  keys[keyCode] = true;
}
 
void keyReleased()
{
  keys[keyCode] = false; 
}