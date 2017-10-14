public final class ShapeSource
{
  public final PVector position;
  public final float size;
  
  public ShapeSource(PVector pos, float s)
  {
    position = pos;
    size = s;
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
      vertex(source.position.x + (source.size * cos(angle)), source.position.y + (source.size * sin(angle)), source.position.z);
    }
    endShape(CLOSE);
  }
}

final class PliantSpot extends Shape
{
  private final float radius;
  
  public PliantSpot(ShapeSource src, float r)
  {
    super(src);
    radius = r;
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
      float baseX = radius * cos(baseAngle + angle);
      float baseY = radius * sin(baseAngle + angle);
      float r = radius * (0.5 + noise(baseX, baseY, ns));
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