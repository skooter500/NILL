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
  
  int playerVertex;
  
  boolean isLandSite(int vIndex)
  {
    return (vertices.get(vIndex).x - vertices.get(vIndex - 1).x == landSiteWidth);
  }
  
  int findPlayerVertex(KittyLander lander)
  {
    // Binary search
    int lo = 0;
    int hi = vertices.size() - 1;
    PVector pos = lander.position.get();
   
    while (lo <= hi)
    {
      int mid = lo + (hi - lo) / 2;      
      if (pos.x < vertices.get(mid).x) 
      {
        if (pos.x > vertices.get(mid - 1).x)
        {
          return mid;
        }
        else
        {
          hi = mid - 1;
        }        
      }
      else
      {
        lo = mid + 1;
      }
    }    
    return -1;
  }
  
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
        KittyBox box = new KittyBox();
        box.position.x = p.x - 10;
        box.position.y = p.y;
        addGameObject(box);        
        boxes.add(box);
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
        if (i == playerVertex)
        {
          stroke(255, 0, 0);
        } 
        else
        {
          stroke(255);
        }
        if (isLandSite(i))
        {
          stroke(51, 255, 51);
        }
        line(from.x, from.y, to.x, to.y);
    }
    popMatrix();
  }
}
