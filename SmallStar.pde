class SmallStar extends GameObject
{
  SmallStar()
  {
    position.x = random(0, worldWidth);
    
    position.y = random(0, landscape.findHeight(position.x));
    colour = color(random(100, 255));    
  }
 
  void display()
  {
    if (isOnScreen(position))
    {
      stroke(colour);
      point(position.x, position.y);
    }
  }
}
