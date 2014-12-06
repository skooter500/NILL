// Uses the following Processing libraries:
// http://www.foobarquarium.de/blog/processing/MovingLetters/
// http://creativecomputing.cc/p5libs/procontroll/


import ddf.minim.*;
import procontroll.*;
import de.ilu.movingletters.*;

ArrayList<GameObject> children = new ArrayList<GameObject>();

boolean[] keys = new boolean[526];

int gameState = 1;

void setup()
{
  size(800, 600);
  smooth();
  addGameObject(new Landscape(5, .03f, -10000, 10000));
  addGameObject(new KittyLander());
}

void game(boolean update)
{    
  for (int i = children.size()-1; i >= 0; i--) 
  {
    GameObject entity = children.get(i);
    if (update)
    {
      entity.update();
    }
    entity.display();
    if (! entity.alive) 
    {
      children.remove(i);
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
void mousePressed()
{
}

void keyPressed()
{ 
  keys[keyCode] = true;
}
 
void keyReleased()
{
  keys[keyCode] = false; 
}

