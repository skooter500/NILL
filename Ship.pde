class Ship extends GameObject
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
  float fuel;
  float maxFuel = 1500;
  float kitties = 0;

  boolean landed = false;
    
  ControlDevice device;
  boolean update;
  
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
    maxSpeed = 80;
    position.x = worldWidth / 2;
    position.y = height / 2;

    exploding = false;
    landed = false;
    escaping = false;    
  }
  
  Ship()
  {
    this(true);
  }
  
  Ship(boolean update)
  {
    this.update = update;
    w = 30;
    h = 30;
    halfWidth = w / 2;
    halfHeight = h / 2;
    
    
    angularVelocity = 1.0f;
    mass = 0.5f;
    colour = color(0, 255, 255);
    
    float thetaInc = TWO_PI / (float) 3;
    
    float radius = halfHeight;
    vertices.add(new PVector(0, - radius));
    vertices.add(new PVector(sin(thetaInc) * radius, - cos(thetaInc) * radius));
    
    vertices.add(new PVector(sin(thetaInc) * radius, - cos(thetaInc) * radius));
    vertices.add(new PVector(0, 0));

    vertices.add(new PVector(0, 0));
    vertices.add(new PVector(-sin(thetaInc) * radius, - cos(thetaInc) * radius));

    vertices.add(new PVector(-sin(thetaInc) * radius, - cos(thetaInc) * radius));
    vertices.add(new PVector(0, - radius));
        
    // Add left leg
    vertices.add(new PVector(- w * 0.1f, h * 0.1f));
    vertices.add(new PVector(- w * 0.3f, h * 0.5f));
        
    PVector last = vertices.get(vertices.size() - 1).get();
    vertices.add(new PVector(last.x - w * 0.1f, last.y));
    vertices.add(new PVector(last.x + w * 0.1f, last.y));

    vertices.add(new PVector(w * 0.1f, h * 0.1f));
    vertices.add(new PVector(w * 0.3f, h * 0.5f));
        
    last = vertices.get(vertices.size() - 1).get();
    vertices.add(new PVector(last.x - w * 0.1f, last.y));
    vertices.add(new PVector(last.x + w * 0.1f, last.y));

  }
  
  float angularVelocity;
  float maxSpeed = 500;
  float maxForce;
  
  
  boolean lastPressed = false;
  boolean exploding  = false;
  
  boolean escaping  = false;
  
  boolean fade = true;
   
  void fadeSound(AudioPlayer p)
  {
    if (fade)
    {      
      fade = false;
      p.shiftGain(14, -80, 500);
    }
  }
  
  void update()
  {                 
      if (!update)
      {
        return;
      }
      if (exploding)
      {
        return;
      }
      elapsed += timeDelta;

      float newtons = 100.0f;            
      
      float cx = width / 2;
      float cy = height / 2;
                                  
      if ((device != null && (device.getSlider(4).getValue() > 0.5f || device.getSlider(4).getValue() < -0.5f)) || (checkKey(forward)))      
      {   
          if (fuel > 0 && position.y > height * .2)
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
      
      if (theta < - PI)
      {
        theta = PI;
      }
      
      if (theta > PI)
      {
        theta = -PI;
      }
      
      if (escaping)
      {
        theta = 0;
        jet = true;
        force.add(PVector.mult(new PVector(0, -1), newtons));
        if (position.y < - 10)
        {
          winState = 2;
          gameState = 2;
        }        
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
      if (position.x < width / 2)
      {
        position.x = width / 2;
      }
      
      if (position.x > worldWidth - width / 2)
      {
        position.x = worldWidth - width / 2;
      }
   
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
      speed = velocity.mag();
      velocity.mult(damping);
      
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
    pushMatrix();
    stroke(255);
    translate(position.x, position.y);
    rotate(theta);
    scale(scaleF);
    stroke(colour);
    noFill();    
    //ellipse(0, 0, w, h);
            
    for (int i = 1 ; i < vertices.size() ; i += 2)
    {
        PVector from = vertices.get(i - 1);
        PVector to = vertices.get(i);            
        line(from.x, from.y, to.x, to.y);
    }
    
    if (jet)
    {
      stroke(0, random(100, 255), random(100, 255));
      line(-halfWidth * 0.3f, h * 0.1, 0, halfHeight);
      line(halfWidth * 0.3f, h * 0.1, 0, halfHeight);
    }
    popMatrix();
    
    super.display();    
  } 
}