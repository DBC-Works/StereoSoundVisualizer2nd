/**
 * LevelTraceVisualizer
 * @author Sad Juno
 * @version 201609
 */

final class LevelTraceVisualizer extends Visualizer
{
  private final List<Particle> rightParticles = new ArrayList<Particle>();
  private final List<Particle> leftParticles = new ArrayList<Particle>();
  private final color fgColor;
  private final color bgColor;
  private XorShift32 rand;

  private float ns;
  
  LevelTraceVisualizer(SceneInfo scene)
  {
    super(scene);
    fgColor = scene.fgColor != null ? color(Integer.decode(scene.fgColor)) : #ffffff;
    bgColor = scene.bgColor != null ? color(Integer.decode(scene.bgColor)) : 0;
  }
  
  boolean isDrawable()
  {
    return true;
  }
  protected void doPrepare(MusicDataProvider provider, boolean isPrimary)
  {
    if (isPrimary) {
      if (rand == null) {
        background(bgColor);
        rand = new XorShift32((int)targetScene.beatPerMinute);
        ns = rand.nextFloat();
      }
    }
    int maxSpec = provider.rightFft.freqToIndex(440 * 4);
    rightParticles.clear();
    for (int index = 0; index < maxSpec; ++index) {
      rightParticles.add(new Particle(new PVector(index, provider.rightFft.getBand(index)), 1));
    }
    leftParticles.clear();
    for (int index = 0; index < maxSpec; ++index) {
      leftParticles.add(new Particle(new PVector(index, provider.leftFft.getBand(index)), 1));
    }
  }
  
  protected void doVisualize()
  {
    colorMode(HSB, 360, 100, 100, 100);
    blendMode(targetScene.blendMode);
    rectMode(CENTER);
    
    translate(width / 2, height);
    float h = hue(fgColor) + 60 * (noise(ns) - 0.5);
    if (h < 0) {
      h += 360;
    }
    else if (360 < h){
      h -= 360;
    }
    ns += 0.01;
    stroke(h, saturation(fgColor), brightness(fgColor), 5);
    strokeWeight(screenCoordinator.getScaledValue(1));
    noFill();

    float amp = height / 12;
    for (Particle particle : rightParticles) {
      visualizeParticle(particle, rightParticles.size(), amp, true);
    }
    
    for (Particle particle : leftParticles) {
      visualizeParticle(particle, leftParticles.size(), amp, false);
    }
  }

  private void visualizeParticle(Particle particle, int particleCount, float amp, boolean rightSide)
  {
      PVector pos = particle.getCurrentPosition();
      float x = map(pos.x, 0, particleCount, 0, (width / 2) *  (rightSide ? 1 : -1)) + (rand.nextGaussian() * amp); 
      float y = map(pos.y, 0, 72, 0, -height) + (rand.nextGaussian() * amp); 
      float n = noise(x / 100.0, y  / 100.0);
      float yStep = -(y / 4);

      beginShape();
      curveVertex(x, y);
      curveVertex(x, y);
      curveVertex(x + (amp * n), y + yStep);
      curveVertex(x, y + yStep * 2);
      curveVertex(x - (amp * n), y + yStep * 3);
      curveVertex(x, 0);
      curveVertex(x, 0);
      endShape();
  }
}