

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
  
  ArrayList<PVector> vertices = new ArrayList<PVector>();
  
  ControllDevice device;
  
  boolean jet;
  
  KittyLander()
  {
    w = 20;
    h = 20;
    halfWidth = w / 2;
    halfHeight = h / 2;
    
    shieldToPassFrames = 300;
    shieldEllapsedFrames = 0;
    position.x = width / 2;
    position.y = height / 2;

    angularVelocity = 5.0f;
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
  
  
  void update()
  {                 
      elapsed += timeDelta;
      
      /*
      if (device.getSlider(4).getValue() > 0.5f)
      {     
          force.add(PVector.mult(look, newtons));
          jet = true;
      }      
      else
      {
        jet = false;
      }     
           
      
      if (device.getSlider(1).getValue() < - 0.5f)
      {
        theta -= timeDelta * angularVelocity;
      }    
      
      if (device.getSlider(1).getValue() > 0.5f)
      {
        theta += timeDelta * angularVelocity;
      }
      
      if (device.getButton(1).pressed() && hyper > 0 && ! lastPressed)
      {
        playSound(hyperDriveSound);
        position.x = random(0, width);
        position.y = random(0, height);        
        hyper --;
        lastPressed = true;
      }
      if (! device.getButton(1).pressed())
      {
        lastPressed = false;
      }      
      
      look.x = sin(theta);
      look.y = -cos(theta);
      
      if (device.getButton(0).pressed() && elapsed > toPass && ammo > 0)
      {
        playSound(shootSound);
        Lazer lazer = new Lazer();
        lazer.position = position.get();
        PVector offset = look.get();
        offset.mult(w);
        lazer.position.add(offset);
        lazer.theta = theta;
        lazer.colour = colour;
        PVector lazerVelocity = PVector.mult(look, 300);
        lazer.velocity = lazerVelocity;
        addGameObject(lazer);
        elapsed = 0.0f;
        ammo --;
      }
      
      PVector acceleration = PVector.div(force, mass);
      velocity.add(PVector.mult(acceleration, timeDelta));   
   
     if (velocity.mag() > maxSpeed)
      {
        velocity.normalize();
        velocity.mult(maxSpeed);
      }   
      
      position.add(PVector.mult(velocity, timeDelta));
      // Apply damping
      velocity.mult(0.99f);
      
      // Reset the force
      force.setMag(0);
      */            
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
    stroke(255);
    pushMatrix();
    translate(position.x, position.y);
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
      stroke(255, 20, 147);
      line(-halfWidth * 0.3f, halfHeight, 0, h);
      line(halfWidth * 0.3f, halfHeight, 0, h);
    }
    popMatrix();
    
    super.display();    
  } 
}
