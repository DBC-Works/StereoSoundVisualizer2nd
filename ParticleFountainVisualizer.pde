final class ParticleFountainVisualizer extends Visualizer
{
  private final List<Particle> rightParticles = new ArrayList<Particle>();
  private final List<Particle> leftParticles = new ArrayList<Particle>();
  private final color fgColor;
  private final color bgColor;
  
  private float noiseSeed = random(1);
  
  ParticleFountainVisualizer(SceneInfo scene)
  {
    super(scene);
    fgColor = scene.fgColor != null ? decodeColor(scene.fgColor) : #fffa88;
    bgColor = scene.bgColor != null ? decodeColor(scene.bgColor) : 0;
    noiseSeed((long)random(Integer.MAX_VALUE));
  }
  
  boolean isDrawable()
  {
    return true;
  }

  protected void doPrepare(MusicDataProvider provider, boolean isPrimary)
  {
    if (isPrimary) {
      background(bgColor);
    }
    
    moveParticles(rightParticles);
    moveParticles(leftParticles);
    noiseSeed += 0.01;
    
    int maxSpec = provider.rightFft.specSize() / 2;
    for (int index = 0; index < maxSpec; ++index) {
      rightParticles.add(createParticle(PI * ((float)index / maxSpec), provider.rightFft.getBand(index)));
    }
    for (int index = 0; index < maxSpec; ++index) {
      leftParticles.add(createParticle(-PI * ((float)index / maxSpec), provider.leftFft.getBand(index)));
    }
  }

  protected void doVisualize()
  {
    colorMode(HSB, 360, 100, 100, 100);
    blendMode(targetScene.blendMode);
    rectMode(CENTER);
    
    translate(width / 2, height / 2);
    rotate(PI / 2);
    noStroke();
    strokeWeight(screenCoordinator.getScaledValue(1));
    fill(hue(fgColor), saturation(fgColor), brightness(fgColor), 5);
    
    float r = screenCoordinator.getScaledValue(8);
    ellipseMode(CENTER);
    visualizeParticles(rightParticles, r);
    visualizeParticles(leftParticles, r);
  }

  private void moveParticles(List<Particle> particles)
  {
    PVector wind = new PVector(0, (noise(noiseSeed) - 0.5) * screenCoordinator.getScaledValue(8));
    int index = 0;
    while (index < particles.size()) {
      Particle particle = particles.get(index);
      if (particle.getAliveCount() < 10) {
        PVector pos = particle.getCurrentPosition();
        pos.mult(1.2);
        pos.add(wind);
        particle.moveTo(pos);
        ++index;
      }
      else {
        particles.remove(index);
      }
    }
  }
  
  private Particle createParticle(float angle, float band)
  {
    float len = band * width / 2.0;
    return new Particle(new PVector(len * cos(angle), len * sin(angle)), 1);
  }
  
  private void visualizeParticles(List<Particle> particles, float radius)
  {
    for (Particle particle : particles) {
      PVector pos = particle.getCurrentPosition();
      if (1 < abs(pos.x) && 1 < abs(pos.y)) { 
        ellipse(pos.x, pos.y, radius, radius);
      }
    }
  }
}