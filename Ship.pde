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

  float kitties = 0;

  boolean landed = false;
  
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
    maxSpeed = 80;
    position.x = worldWidth / 2;
    position.y = height / 2;

    exploding = false;
    landed = false;    
  }
  
  Ship()
  {
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
  
  Ship(ControllDevice device)
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
      
      float cx = width / 2;
      float cy = height / 2;
                  
      Hand hand = leap.getRightHand();
      if (hand != null)
      {
        if (!lander.landed)
        {
          println(hand.getRawPosition().y);
          lander.theta = radians(hand.getPitch());
        }
      }   
          
      if ((device != null && device.getSlider(4).getValue() > 0.5f) || (checkKey(forward)) || (hand != null && hand.getPosition().y > 550))
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
      
      if (theta > TWO_PI || theta < - TWO_PI)
      {
        theta = 0;
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
