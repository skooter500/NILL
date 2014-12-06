

class KittyLander extends GameObject
{  
  float fireRate = 5.0f;
  float toPass = 1.0f / fireRate;
  float elapsed = toPass;
  
  int lives = 10;
  int hyper  = 5;
  int ammo = 100;
  
  char forward;
  char left;
  char right;
  char fire;
  char hyperDrive;
  color colour;
  boolean shield = false;
  boolean drawShield = true;
  int shieldEllapsedFrames;
  int shieldToPassFrames;
  AudioPlayer shootSound;
  AudioPlayer hyperDriveSound;
  float halfWidth;
  float halfHeight;
  float fuel = 1000;
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
    fuel = 1000;
    position.x = width / 2;
    position.y = height / 2;
    exploding = false;
    landed = false;    
  }
  
  KittyLander()
  {
    w = 20;
    h = 20;
    halfWidth = w / 2;
    halfHeight = h / 2;
    
    position.x = width / 2;
    position.y = height / 2;

    angularVelocity = 1.0f;
    mass = 0.5f;
    colour = color(0, 255, 255);
    int numSides = 8;
    float thetaInc = TWO_PI / (float) numSides;
    
    PVector last = new PVector(0, - halfHeight);
    
    for (int i = 1 ; i <= numSides ; i ++)
    {
      float theta = i * thetaInc;
      PVector p = new PVector();
      p.x = sin(theta) * halfWidth;
      p.y = -cos(theta) * halfHeight;
      vertices.add(last);
      vertices.add(p);
      last = p;
    }
    
    // Add legs
    vertices.add(vertices.get(5).get());
    vertices.add(new PVector(halfWidth, halfHeight * 1.5f));
    
    vertices.add(new PVector(halfWidth, halfHeight * 1.5f));
    vertices.add(new PVector(halfWidth, halfHeight * 2f));
    
    
    vertices.add(new PVector(halfWidth * 0.8f, halfHeight * 2f));    
    vertices.add(new PVector(halfWidth * 1.2f, halfHeight * 2f));

    vertices.add(vertices.get(10).get());
    vertices.add(new PVector(-halfWidth, halfHeight * 1.5f));
    
    vertices.add(new PVector(-halfWidth, halfHeight * 1.5f));
    vertices.add(new PVector(-halfWidth, halfHeight * 2f));
    
    
    vertices.add(new PVector(-halfWidth * 0.8f, halfHeight * 2f));
    vertices.add(new PVector(-halfWidth * 1.2f, halfHeight * 2f));
    
    // Add whiskers
    /*
    vertices.add(vertices.get(3).get());
    vertices.add(new PVector(w, 0));
    vertices.add(vertices.get(3).get());
    vertices.add(new PVector(w, -halfHeight * 0.5f));
    vertices.add(vertices.get(3).get());
    vertices.add(new PVector(w, halfHeight * 0.5f));

    vertices.add(vertices.get(11).get());
    vertices.add(new PVector(-w, 0));
    vertices.add(vertices.get(11).get());
    vertices.add(new PVector(-w, -halfHeight * 0.5f));
    vertices.add(vertices.get(11).get());
    vertices.add(new PVector(-w, halfHeight * 0.5f));
    */
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
      
      if (device.getSlider(4).getValue() > 0.5f)
      {     
          force.add(PVector.mult(look, newtons));
          jet = true;
          landed = false;
          fuel --;
      }      
      else
      {
        jet = false;
      }     
                 
      if (device.getSlider(1).getValue() < - 0.5f && ! landed)  
      {
        theta -= timeDelta * angularVelocity;
      }    
      
      if (device.getSlider(1).getValue() > 0.5f && ! landed)
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
      velocity.mult(0.99f);
      
      // Reset the force
      force.setMag(0);

      if (shield)
      {
        shieldEllapsedFrames ++;
        if (shieldEllapsedFrames % 10 == 0)
        {
          drawShield = ! drawShield;
        }
        if (shieldEllapsedFrames >= shieldToPassFrames)
        {
          shield = ! shield;
        }
        
      }      
      super.update();             
  }
  
  void resetShield(float duration)
  {
    shield = true;
    drawShield = true;
    shieldEllapsedFrames = 0;
    this.shieldToPassFrames = (int) duration * 60;
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
        
    if (shield && drawShield)
    {
      ellipse(0,0, w * 2, h * 2);
    }
    
    for (int i = 1 ; i < vertices.size() ; i += 2)
    {
        PVector from = vertices.get(i - 1);
        PVector to = vertices.get(i);            
        line(from.x, from.y, to.x, to.y);
    }
    
    if (jet)
    {
      line(-halfWidth * 0.3f, halfHeight, 0, h);
      line(halfWidth * 0.3f, halfHeight, 0, h);
    }
    popMatrix();
    
    super.display();    
  } 
}
