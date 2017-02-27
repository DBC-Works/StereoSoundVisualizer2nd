/**
 * NoiseSteeringLineVisualizer
 * @author Sad Juno
 * @version 201702
 */

final class NoiseSteeringLineVisualizer extends Visualizer
{
  private final List<Particle> particles = new ArrayList<Particle>();
  private final color fgColor;
  private final color bgColor;
  private XorShift32 rand;
  
  NoiseSteeringLineVisualizer(SceneInfo scene)
  {
    super(scene);
    fgColor = scene.fgColor != null ? decodeColor(scene.fgColor) : 0;
    bgColor = scene.bgColor != null ? decodeColor(scene.bgColor) : #ffffff;
  }
  boolean isDrawable()
  {
    return particles.isEmpty() == false;
  }
  protected void doPrepare(MusicDataProvider provider, boolean isPrimary)
  {
    int halfWidth = width / 2;
    int halfHeight = height / 2;
    if (isPrimary) {
      if (rand == null) {
        background(bgColor);
        rand = new XorShift32((int)targetScene.beatPerMinute);
      }
      float rate =  provider.player.sampleRate() / 2;
      PVector right = new PVector(map(provider.rightFft.calcAvg(0, rate), 0, 1, 0, halfWidth), map(provider.player.right.level() * 5, 0, 1, halfHeight, -halfHeight));
      PVector left = new PVector(map(provider.leftFft.calcAvg(0, rate), 0, 1, 0, -halfWidth), map(provider.player.left.level() * 5, 0, 1, halfHeight, -halfHeight));
      particles.add(new Particle(right, 2));
      particles.add(new Particle(left, 2));
    }
    
    if (0 < particles.size() && (isPrimary == false || 4 < particles.size())) {
      particles.remove(0);
    }
    int index = 0;
    while (index < particles.size()) {
      Particle particle = particles.get(index);
      if (particle.isAlive()) {
        float length = screenCoordinator.getScaledValue(rand.nextFloat() * (height / 100.0) + 1);
        PVector pos = particle.getCurrentPosition();
        float ns = noise(pos.x / 25.0, pos.y / 25.0);
        pos.x += (cos(ns * TWO_PI) * length);
        pos.y += (sin(ns * TWO_PI) * length);
        particle.moveTo(pos);
        if (particle.isAlive()) {
          if (pos.x < -halfWidth  || pos.y < -halfHeight || halfWidth < pos.x || halfHeight < pos.y) {
            particle.terminate();
          }
        }
        ++index;
      }
      else {
          particles.remove(index);
      }
    }
  }
  
  protected void doVisualize()
  {
    colorMode(HSB, 360, 100, 100, 100);
    blendMode(targetScene.blendMode);
    
    translate(width / 2, height / 2);
    stroke(hue(fgColor), saturation(fgColor), brightness(fgColor), 10);
    strokeWeight(screenCoordinator.getScaledValue(1));
    noFill();
    for (Particle particle : particles) {
      List<PVector> positions = particle.getPositionHistory();
      if (1 < positions.size()) {
        beginShape(LINES);
        for (PVector pos: positions) {
          vertex(pos.x, pos.y);
        }
        endShape();
      }
    }
  }
}

final class NoiseSteeringCurveLineVisualizer extends Visualizer
{
  private final List<Particle> rightParticles = new ArrayList<Particle>();
  private final List<Particle> leftParticles = new ArrayList<Particle>();
  private final color fgColor;
  private final color bgColor;
  private XorShift32 rand;

  private float ns;
  private float maxLevel;
  
  NoiseSteeringCurveLineVisualizer(SceneInfo scene)
  {
    super(scene);
    fgColor = scene.fgColor != null ? color(Integer.decode(scene.fgColor)) : #ffffff;
    bgColor = scene.bgColor != null ? color(Integer.decode(scene.bgColor)) : 0;
  }
  
  boolean isDrawable()
  {
    return rightParticles.isEmpty() == false || leftParticles.isEmpty() == false;
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

    float rate =  provider.player.sampleRate() / 3;
    
    Particle rightParticle = new Particle(new PVector(width / 2, 0), 5);
    rightParticle.moveTo(new PVector(width / 2, map(provider.rightFft.calcAvg(0, rate), 0, 2.4, height / 2, -height / 2)));
    rightParticles.add(rightParticle);
    updateParticles(rightParticles, true);
    
    Particle leftParticle = new Particle(new PVector(-width / 2, 0), 5); 
    leftParticle.moveTo(new PVector(-width / 2, map(provider.leftFft.calcAvg(0, rate), 0, 2.4, height / 2, -height / 2)));
    leftParticles.add(leftParticle);
    updateParticles(leftParticles, false);

    ns += 0.01;
  }
  
  private void updateParticles(List<Particle> particles, boolean rightSide)
  {
    Iterator iterator = particles.iterator();
    while (iterator.hasNext()) {
      Particle p = (Particle)iterator.next();
      if (p.isAlive() == false || 20 < p.getAliveCount()) {
        p.terminate();
        iterator.remove();
      }
      else {
        PVector pos = p.getCurrentPosition();
        float angle = map(noise(pos.x, pos.y, ns), 0, 1, 0, PI);
        if (rightSide) {
          angle += HALF_PI;
        }
        else {
          angle = HALF_PI - angle;
        }
        float len = abs(p.getLastDistance()) * 0.8;
        pos.add(len * cos(angle), len * sin(angle));
        p.moveTo(pos);
      }
    }    
  }
  
  protected void doVisualize()
  {
    colorMode(HSB, 360, 100, 100, 100);
    blendMode(targetScene.blendMode);
    rectMode(CENTER);
    
    translate(width / 2, height / 2);
    stroke(hue(fgColor), saturation(fgColor), brightness(fgColor), 5);
    strokeWeight(screenCoordinator.getScaledValue(1));
    noFill();

    for (Particle particle : rightParticles) {
      if (particle.isAlive()) {
        visualizeParticle(particle);
      }
    }
    
    for (Particle particle : leftParticles) {
      if (particle.isAlive()) {
        visualizeParticle(particle);
      }
    }
  }

  private void visualizeParticle(Particle particle)
  {
    beginShape();
    for (PVector pos : particle.getPositionHistory()) {
      curveVertex(pos.x, pos.y);
    }
    endShape();
  }
}