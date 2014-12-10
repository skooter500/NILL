class Asteroid extends GameObject implements Powerup
{
  Asteroid()
  {
    w = random(20, 50);
    h = w;
    halfWidth = w / 2;
    halfHeight = h / 2;
    position = randomOffscreenPoint(w);        
    theta = 0.0f;
    colour = color(255);
    mass = 10.0f;
    velocity = new PVector(random(-100, 100), random(0, 1));
    
    int sides = 5;
    float radius = w / 2.0f;
    float thetaInc = TWO_PI / (float) sides;
    float lastX = 0, lastY = - radius;
    float x, y;
    for (int i = 1 ; i <= sides ; i ++)
    {
      float theta1 = (float) i  * thetaInc;
      if ((int)random(0,3) == 0)
      {
        x = sin(theta1) * (radius / 2.0f);
        y = -cos(theta1) * (radius / 2.0f);
      } 
      else
      {
        x = sin(theta1) * radius;
        y = -cos(theta1) * radius;
      }    
      vertices.add(new PVector(lastX, lastY));  
      vertices.add(new PVector(x, y));  
      lastX = x;
      lastY = y; 
    } 
    
  }  
  
  ArrayList<PVector> vertices = new ArrayList<PVector>();
  
  void applyTo(Ship ship)
  {
    ship.fuel += (int) random(100, 500);
    if (ship.fuel > ship.maxFuel)
    {
      ship.fuel = ship.maxFuel;
    }
  }
  
  void update()
  { 
   theta += timeDelta;   
   velocity.add(PVector.mult(gravity, timeDelta));   
   position.add(PVector.mult(velocity, timeDelta));     
   velocity.mult(damping);   
  }
  
  void display()
  {
    stroke(colour);
    noFill();
    pushMatrix();
    translate(position.x, position.y);
    rotate(theta);    
    for (int i = 1 ; i < vertices.size() ; i += 2)
    {
        PVector from = vertices.get(i - 1);
        PVector to = vertices.get(i);            
        line(from.x, from.y, to.x, to.y);
    }
    popMatrix();
  }  
}
