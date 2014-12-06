class Explosion extends GameObject
{
  Arraylist<PVector> vertices = new ArrayList<PVector>();
  Arraylist<PVector> directions = new ArrayList<PVector>();
  Arraylist<Float> rotations = new ArrayList<Float>();
  Arraylist<Float> angularVelocities = new ArrayList<Float>();
  
  float speed = 10;
  
  float timeDelta = 1.0 / 60.0f;
  float start = 0;
  float ellapsed = 0;
  float liveFor = 10.0f;
  
  Explosion(Arraylist<PVector> vertices)
  {
    this.vertices = vertices;
    for (int i = 0 ;  i < vertices.size() ; i +=2)
    {
        PVector dir = new PVector(random(-1, 1), random(-1, 1));
        dir.normalise();
        dir.mult(speed);
        directions.add(dir);
    }
  }

  void update()
  {
  }

  void display()
  {
  }  
}
