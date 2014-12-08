

class KittyLander extends GameObject
{  
  float fireRate = 5.0f;
  float toPass = 1.0f / fireRate;
  float elapsed = toPass;
  
  char forward;
  char left;
  char right;
  char fire;
  color colour;
  AudioPlayer shootSound;
  AudioPlayer hyperDriveSound;
  float halfWidth;
  float halfHeight;
  float fuel;
  float kitties = 0;

  boolean landed = false;
  
  PVector gravity = new PVector(0, 20, 0);            

  ArrayList<PVector> vertices = new ArrayList<PVector>();
  
  ControllDevice device;
  
  boolean jet;
     
  void explode()
  {
    exploding = true;
    
  }
  
  void reset()
  {
    kitties = 0;
    theta = 0;
    force = new PVector(0,0);
    velocity = new PVector(0,0);
    kitties = 0;
    fuel = 500;
    position.x = width / 2;
    position.y = height / 2;
    exploding = false;
    landed = false;    
  }
  
  KittyLander()
  {
    w = 30;
    h = 30;
    halfWidth = w / 2;
    halfHeight = h / 2;
    
    position.x = width / 2;
    position.y = height / 2;

    angularVelocity = 1.0f;
    mass = 0.5f;
    colour = color(0, 255, 255);
    int numSides = 8;
    float thetaInc = TWO_PI / (float) numSides;
    
    float topSection = h * 0.5f;
    float radius = topSection / 2;
    PVector last = new PVector(0, - radius * 2);

    for (int i = 1 ; i <= numSides ; i ++)
    {
      float theta = i * thetaInc;
      PVector p = new PVector();
      p.x = sin(theta) * radius;
      p.y = -radius -cos(theta) * radius;
      vertices.add(last);
      vertices.add(p);
      last = p;
    }
    
    // Add left leg
    vertices.add(vertices.get(5).get());
    vertices.add(new PVector(w * 0.3f, h * 0.2f));
    
    last = vertices.get(vertices.size() - 1).get();   
    vertices.add(last);
    vertices.add(new PVector(w * 0.3f, h * 0.5f));
    
    last = vertices.get(vertices.size() - 1).get();
    vertices.add(new PVector(last.x - w * 0.1f, last.y));
    vertices.add(new PVector(last.x + w * 0.1f, last.y));
    
    // Add right leg
    vertices.add(vertices.get(10).get());
    vertices.add(new PVector(-w * 0.3f, h * 0.2f));

    last = vertices.get(vertices.size() - 1).get();   
    vertices.add(last);
    vertices.add(new PVector(-w * 0.3f, h * 0.5f));
    
    last = vertices.get(vertices.size() - 1).get();   
    vertices.add(new PVector(last.x - w * 0.1f, last.y));
    vertices.add(new PVector(last.x + w * 0.1f, last.y));
    
    
  }
  
  float angularVelocity;
  float maxSpeed = 500;
  float maxForce;
  
  KittyLander(ControllDevice device)
  {
    this();
    this.device = device;
  }
  
  boolean lastPressed = false;
  boolean exploding  = false;
  
  void update()
  {                 
      if (exploding)
      {
        return;
      }
      elapsed += timeDelta;

      float newtons = 100.0f;      
      
      if ((device != null && device.getSlider(4).getValue() > 0.5f) || (checkKey(forward)))
      {   
          if (fuel > 0)
          {  
            //playSound(thrustSound, true);
            force.add(PVector.mult(look, newtons));
            jet = true;
            landed = false;
            fuel --;
          }
      }      
      else
      {
        jet = false;
      }     
                 
      if (((device != null && device.getSlider(1).getValue() < - 0.5f) || checkKey(left)) && ! landed) 
      {
        theta -= timeDelta * angularVelocity;
      }    
      
      if (((device != null && device.getSlider(1).getValue() > 0.5f)  || checkKey(right)) && ! landed)
      {
        theta += timeDelta * angularVelocity;
      }
      
      look.x = sin(theta);
      look.y = -cos(theta);

      PVector acceleration = PVector.div(force, mass);
      acceleration.add(gravity);
      velocity.add(PVector.mult(acceleration, timeDelta));   
   
     if (velocity.mag() > maxSpeed)
      {
        velocity.normalize();
        velocity.mult(maxSpeed);
      }   
      
      if (landed && velocity.y > 0)
      {
        velocity.y = 0;
      }
      
      position.add(PVector.mult(velocity, timeDelta));
      // Apply damping
      velocity.mult(0.995f);
      
      // Reset the force
      force.setMag(0);
      super.update();             
  }
  
  
  void display()
  {
    if (exploding)
    {
      return;
    }
    stroke(255);
    pushMatrix();
    translate(width / 2, position.y);
    rotate(theta);
    scale(scaleF);
    stroke(colour);
    noFill();    
            
    for (int i = 1 ; i < vertices.size() ; i += 2)
    {
        PVector from = vertices.get(i - 1);
        PVector to = vertices.get(i);            
        line(from.x, from.y, to.x, to.y);
    }
    
    if (jet)
    {
      stroke(0, random(100, 255), random(100, 255));
      line(-halfWidth * 0.3f, 0, 0, halfHeight);
      line(halfWidth * 0.3f, 0, 0, halfHeight);
    }
    popMatrix();
    
    super.display();    
  } 
}
