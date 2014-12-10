class Landscape extends GameObject
{
  
  float w;
  float density;
  float landProbability;
  float landSiteWidth = 50;
  float noisyness = 0.08f; 
  
  int playerVertex;
  
  boolean isLandSite(int vIndex)
  {
    if (vIndex > 0 && vIndex < vertices.size())
    {
      return (vertices.get(vIndex).x - vertices.get(vIndex - 1).x == landSiteWidth);
    }
    else
    {
      println("vIndex: " + vIndex);
      return false;
    }
  }
  
  float findHeight(float xs)
  {
    int i = findVertex(xs);
    if (i > 1)
    {
      PVector from = vertices.get(i - 1);
      PVector to = vertices.get(i);
      
      float xDist = xs - from.x;
      float slope = (to.y - from.y) / (to.x - from.x);
      return from.y + (slope * xDist);
    }
    else
    {
      return 0;
    }
  }
  
  int findVertex(float xs)
  {
    // Binary search
    int lo = 0;
    int hi = vertices.size() - 1;   
    
    if (xs < vertices.get(1).x)
    {
      return 0;
    }
    
    while (lo <= hi)
    {
      int mid = lo + (hi - lo) / 2;      
      if (xs == vertices.get(mid).x)
      {
        return mid;
      }
      if (xs < vertices.get(mid).x) 
      {
        if (xs >= vertices.get(mid - 1).x)
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
    println("-1!!!!: " + xs);
    return -1;
  }
  
  Landscape(float density, float landProbability, float w)
  {
    this.landProbability = landProbability;
    this.w = w;
    this.density = density;    
    
    int numPoints = (int) (w / density);
        
    float xGap = w / (numPoints - 1);
    float maxHeight = height * 0.5f;    
    float lastX = 0;
    float lastY = 0;    
    
    int lastSite = 0;
    
    for (int i = 0 ; i < numPoints ; i ++)
    {      
      PVector p = new PVector();
      // Should we place a land site
      float r = random(0, 1);
      if (r <= landProbability && i - lastSite > 10)
      {
        p.x = lastX + landSiteWidth;
        p.y = lastY;      
        KittyBox box = new KittyBox();
        box.position.x = p.x - landSiteWidth / 2;
        box.position.y = p.y;
        box.index = i;
        addGameObject(box);        
        boxes.add(box);
        lastSite = i;
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
    
    position.x = 0;
    position.y = 0;    
  }
  
  void display()
  {    
    pushMatrix();
    stroke(255);
    for (int i = 1 ; i < vertices.size() ; i ++)
    {
        PVector from = vertices.get(i - 1);
        PVector to = vertices.get(i);       
        if (isOnScreen(from) || isOnScreen(to))
        {
          if (i == playerVertex)
          {
            stroke(255, 0, 0);
          } 
          else
          {
            stroke(245, 160, 12);
          }
          if (isLandSite(i))
          {
            stroke(255, 0, 255);
          }
          line(from.x, from.y, to.x, to.y);
        }
    }
    popMatrix();
  }
}
