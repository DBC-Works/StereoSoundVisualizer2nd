/**
 * LevelVisualizer
 * @author Sad Juno
 * @version 201705
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
    fgColor = scene.fgColor != null ? decodeColor(scene.fgColor) : #ffffff;
    bgColor = scene.bgColor != null ? decodeColor(scene.bgColor) : 0;
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

final class BeatCircleAndFreqLevelVisualizer extends Visualizer
{
  private final List<Particle> rightParticles = new ArrayList<Particle>();
  private final List<Particle> leftParticles = new ArrayList<Particle>();
  private final List<Float> kickDiameters = new ArrayList<Float>();
  private final List<Float> hatDiameters = new ArrayList<Float>();
 
  private final float radius;
  private final float weightUnit;
  private final color fgColor;
  private final color bgColor;
 
  private boolean kicked;
  private boolean hatted;

  BeatCircleAndFreqLevelVisualizer(SceneInfo scene)
  {
    super(scene);
    fgColor = scene.fgColor != null ? decodeColor(scene.fgColor) : 0;
    bgColor = scene.bgColor != null ? decodeColor(scene.bgColor) : #ffffff;

    int shortSideLen = min(width, height); 
    radius = (shortSideLen / 2) * 4.0 / 5;
    weightUnit = shortSideLen / 100.0;
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

    updateDiameters(kickDiameters, 0.67 * (24.0 / fps), (radius / 20.0));
    if (provider.beatDetector.isKick()) {
      if (kicked == false) {
        kickDiameters.add(radius * 2);
        kicked = true;
      }
    }
    else if (kicked) {
      kicked = false;
    }

    updateDiameters(hatDiameters, 1.2 * (24.0 / fps), max(width, height));
    if (provider.beatDetector.isHat()) {
      if (hatted == false) {
        hatDiameters.add(radius * 2);
        hatted = true;
      }
    }
    else if (hatted) {
      hatted = false;
    }
    
    updateParticles(rightParticles, provider.rightFft, false);
    updateParticles(leftParticles, provider.leftFft, true);
  }
  private void updateDiameters(List<Float> diameters, float ratio, float limit)
  {
    int index = 0;
    while (index < diameters.size()) {
      float diameter = diameters.get(index) * ratio;
      if ((ratio < 1.0 && diameter < limit) || (1.0 <= ratio && limit < diameter)) {
        diameters.remove(index);
      }
      else {
        diameters.set(index, diameter);
        ++index;
      }
    }
  }
  private void updateParticles(List<Particle> particles, FFT fft, boolean asLeft)
  {
    final float bandRatio = 100;
//  int maxSpec = fft.specSize();
    int maxSpec = fft.freqToIndex(440 * 16);
    particles.clear();
    for (int index = 0; index < maxSpec; ++index) {
      float rad = map(index, 0, maxSpec, -PI / 2, PI / 2);
      PVector pos = new PVector(radius * cos(rad) * (asLeft ? -1 : 1), -radius * sin(rad));
      Particle p = new Particle(pos, 2);
      PVector a = PVector.mult(pos, sin(map(fft.getBand(index) / bandRatio, 0, 1, 0, PI / 2)) * map(index, 0, maxSpec, 1, 3));
      p.moveTo(new PVector(pos.x - a.x, pos.y - a.y));
      particles.add(p);
    }
  }
  
  protected void doVisualize()
  {
    colorMode(RGB, 255, 255, 255, 100);
    blendMode(targetScene.blendMode);
    
    noFill();
 
    translate(width / 2, height / 2);

    ellipseMode(CENTER);
    strokeWeight(weightUnit * 2);
    stroke(red(fgColor), green(fgColor), blue(fgColor), 40);
    for (float diameter : kickDiameters) {
      ellipse(0, 0, diameter, diameter);
    }
    
    strokeWeight(weightUnit * 1.5);
    for (float diameter : hatDiameters) {
      ellipse(0, 0, diameter, diameter);
    }
    
    strokeWeight(weightUnit);
    stroke(red(fgColor), green(fgColor), blue(fgColor), 80);
    visualizeParticles(rightParticles);
    visualizeParticles(leftParticles);
  }
  
  private void visualizeParticles(List<Particle> particles)
  {
    for (Particle particle : particles) {
      beginShape(LINES);
      for (PVector pos : particle.getPositionHistory()) {
        vertex(pos.x, pos.y);
      }
      endShape();
    }
  }
}

final class PoppingLevelVisualizer extends Visualizer
{
  private final List<List<Float>> rightLevels = new ArrayList<List<Float>>();
  private final List<List<Float>> leftLevels = new ArrayList<List<Float>>();
  private final color fgColor;
  private final color bgColor;
  private XorShift32 rand;

  private float ns;
  
  PoppingLevelVisualizer(SceneInfo scene)
  {
    super(scene);
    fgColor = scene.fgColor != null ? decodeColor(scene.fgColor) : #ffffff;
    bgColor = scene.bgColor != null ? decodeColor(scene.bgColor) : 0;
  }
  
  boolean isDrawable()
  {
    return true;
  }
  protected void doPrepare(MusicDataProvider provider, boolean isPrimary)
  {
    if (isPrimary) {
      background(bgColor);
      if (rand == null) {
        rand = new XorShift32((int)targetScene.beatPerMinute);
        ns = rand.nextFloat();
      }
    }
    rightLevels.clear();
    leftLevels.clear();
    
    float maxFreq = provider.rightFft.indexToFreq(provider.rightFft.specSize() - 1);
    float beginFreq = 0;
    float endFreq = 27.5;
    while (endFreq < maxFreq) {
      preparePoint(provider.rightFft, beginFreq, endFreq, rightLevels);
      preparePoint(provider.leftFft, beginFreq, endFreq, leftLevels);
      
      beginFreq = endFreq;
      endFreq = endFreq * 2;
    }
  }
  
  private void preparePoint(FFT fft, float beginFreq, float endFreq, List<List<Float>> target) {
      List<Float> levels = new ArrayList<Float>();
      for (int index = fft.freqToIndex(beginFreq); index < fft.freqToIndex(endFreq); ++index) {
        levels.add(fft.getBand(index));
      }
      target.add(levels);
  }
  
  protected void doVisualize()
  {
    colorMode(HSB, 360, 100, 100, 100);
    blendMode(targetScene.blendMode);
    ellipseMode(CENTER);
    
    translate(width / 2, 0);
    noStroke();
    smooth();
    
    visualizeLevels(rightLevels, false);
    visualizeLevels(leftLevels, true);
  }
  
  private void visualizeLevels(List<List<Float>> levelHistory, boolean asLeft) {
    float unit = width / 4.0;
    float h = hue(fgColor);
    float s = saturation(fgColor);
    float b = brightness(fgColor);
    for (List<Float> levels : levelHistory) {
      int index = 0;
      float alpha = 30 + (50 * ((float)levels.size() / (float)levelHistory.get(levelHistory.size() - 1).size()) - 0.1);
      fill(h, s, b, alpha);
      for (float level: levels) {
        float u = (unit / levels.size()) * map(level, 0, 50, 0, 1);
        pushMatrix();
        float x = map(index, 0, levels.size(), 0, (width / 2) * (asLeft ? -1 : 1));
        float y = map(level, 0, 50, height, 0);
        translate(x, y);
        rotate(PI * (noise(x, y, ns) - 0.5));
        ellipse(0, 0, (width / 2.0) / levels.size(), u);
        popMatrix();

        ns += 0.01;
        ++index;
      }
    }
  }
}