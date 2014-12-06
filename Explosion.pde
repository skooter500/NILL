class Explosion extends GameObject
{
  ArrayList<PVector> vertices = new ArrayList<PVector>();
  ArrayList<PVector> directions = new ArrayList<PVector>();
  ArrayList<Float> rotations = new ArrayList<Float>();
  ArrayList<Float> angularVelocities = new ArrayList<Float>();
  
  float speed = 0.1f;
  
  float timeDelta = 1.0 / 60.0f;
  float ellapsed = 0;
  float liveFor = 5.0f;
  
  Explosion(ArrayList<PVector> vertices, PVector pos)
  {
    this.position = pos;
    for(PVector vertex:vertices)
    {
      this.vertices.add(vertex.get());
    }
    for (int i = 0 ;  i < vertices.size() ; i +=2)
    {
        PVector dir = new PVector(random(-1, 1), random(-1, 1));
        dir.normalize();
        dir.mult(speed);
        directions.add(dir);
    }
    println("New explosion");
  }

  void update()
  {    
    for (int i = 0 ; i < vertices.size() ; i ++)
    {
      PVector velocity = directions.get(i / 2);
      vertices.get(i).add(velocity);
    }
    ellapsed += timeDelta;
    if (ellapsed > liveFor)
    {
      alive = false;
    }
  }

  void display()
  {
   stroke(255);
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
