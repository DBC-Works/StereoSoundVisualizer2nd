public final class ShapeSource
{
  public final PVector position;
  public final float radius;
  
  public ShapeSource(PVector pos, float r)
  {
    position = pos;
    radius = r;
  }
}

abstract class Shape
{
  protected ShapeSource source;
  
  protected Shape(ShapeSource src)
  {
    source = src;
  }
  
  public Shape setSource(ShapeSource src)
  {
    source = src;
    return this;
  }
  
  public final void visualize()
  {
    pushMatrix();
    translate(source.position.x, source.position.y, source.position.z);
    doVisualize();
    popMatrix();
  }
  
  abstract protected void doVisualize();
}

final class RegularPolygon extends Shape
{
  private final int number;
  
  public RegularPolygon(ShapeSource src, int num)
  {
    super(src);
    number = num;
  }
  
  protected final void doVisualize()
  {
    beginShape();
    for (float angle = 0; angle < TWO_PI; angle += (TWO_PI / number)) {
      vertex(source.position.x + (source.radius * cos(angle)), source.position.y + (source.radius * sin(angle)), source.position.z);
    }
    endShape(CLOSE);
  }
}

final class PliantSpot extends Shape
{
  public PliantSpot(ShapeSource src)
  {
    super(src);
  }
  
  protected final void doVisualize()
  {
    XorShift32 radomizer = new XorShift32((int)(source.position.x + source.position.y));
    float ns = radomizer.nextFloat() * (source.position.x * source.position.y);
    List<PVector> points = new ArrayList<PVector>();
    float baseAngle = radomizer.nextFloat() * TWO_PI;
    float angle = 0;
    int corners = 4 + ((int)(radomizer.nextFloat() * 4) * 2);
    while (angle < TWO_PI) {
      float baseX = source.radius * cos(baseAngle + angle);
      float baseY = source.radius * sin(baseAngle + angle);
      float r = source.radius * (0.5 + noise(baseX, baseY, ns));
      points.add(new PVector(r * cos(baseAngle + angle), r * sin(baseAngle + angle)));
      angle += (TWO_PI / corners) * (0.5 + noise(ns));
      ns += 0.01;
    }
    
    beginShape();
    PVector lastPoint = points.get(points.size() - 2); 
    curveVertex(lastPoint.x, lastPoint.y);
    for (PVector point : points) {
      curveVertex(point.x, point.y);
    }
    PVector firstPoint = points.get(1); 
    curveVertex(firstPoint.x, firstPoint.y);
    endShape(CLOSE);
  }
}