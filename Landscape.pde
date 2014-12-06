class Landscape extends GameObject
{
  ArrayList<PVector> vertices = new ArrayList<PVector>();
  
  float w;
  float density;
  float lower;
  float upper;
  float landProbability;
  float landSiteWidth = 50;
  float noisyness = 0.08f;
  
  Landscape(float density, float landProbability, float lower, float upper)
  {
    this.lower = lower;
    this.upper = upper;
    this.landProbability = landProbability;
    w = upper - lower;
    this.density = density;    
    
    int numPoints = (int) (w / density);
        
    float xGap = w / (numPoints - 1);
    float maxHeight = height * 0.5f;    
    float lastX = lower;
    float lastY = 0;    
    
    for (int i = 0 ; i < numPoints ; i ++)
    {      
      PVector p = new PVector();
      // Should we place a land site
      float r = random(0, 1);
      if (r <= landProbability)
      {
        p.x = lastX + landSiteWidth;
        p.y = lastY;      
      }
      else
      {
        p.x = lastX + xGap;
        p.y = height - noise(i * noisyness) * maxHeight;
      }
      vertices.add(p);
      lastX = p.x;
      lastY = p.y;
    }
  }
  
  void update()
  {
    if (checkKey('A'))
    {
      position.x -= 10;
    }
    if (checkKey('D'))
    {
      position.x += 10;
    }
    
  }
 
  void display()
  {    
    pushMatrix();
    translate(position.x, position.y);
    stroke(255);
    for (int i = 1 ; i < vertices.size() ; i ++)
    {
        PVector from = vertices.get(i - 1);
        PVector to = vertices.get(i);        
        line(from.x, from.y, to.x, to.y);
    }
    popMatrix();
  }
}
