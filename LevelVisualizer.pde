/**
 * LevelVisualizer
 * @author Sad Juno
 * @version 201705
 */

import java.util.AbstractMap.SimpleEntry;

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

abstract class BeatCircleVisualizer extends Visualizer
{
  protected final float radius;
  protected final float weightUnit;
  protected final color fgColor;
  protected final color bgColor;

  private final float alphaLevel;
  private final List<Float> kickDiameters = new ArrayList<Float>();
  private final List<Float> hatDiameters = new ArrayList<Float>();

  private float detectionIntervalFrame = 1;
  private int kickCount = -1;
  private int hatCount = -1;
  
  protected BeatCircleVisualizer(SceneInfo scene, float fgAlphaLevel)
  {
    super(scene);
    alphaLevel = fgAlphaLevel;
    fgColor = scene.fgColor != null ? decodeColor(scene.fgColor) : 0;
    bgColor = scene.bgColor != null ? decodeColor(scene.bgColor) : #ffffff;

    int shortSideLen = getShortSideLen(); 
    radius = (shortSideLen / 2) * 4.0 / 5;
    weightUnit = shortSideLen / 100.0;
  }
  
  final boolean isDrawable()
  {
    return true;
  }

  protected final void setDetectionIntervalFrame(float frame)
  {
    detectionIntervalFrame = frame; 
  }
  
  protected void doPrepare(MusicDataProvider provider, boolean isPrimary)
  {
    if (isPrimary) {
      background(bgColor);
    }

    updateDiameters(kickDiameters, 0.67 * (24.0 / fps), (radius / 20.0));
    if (kickCount < 0) {
      if (provider.beatDetector.isKick()) {
        kickDiameters.add(radius * 2);
        kickCount = 0;
      }
    }
    else {
      if (detectionIntervalFrame <= ++kickCount) {
        kickCount = -1;
      }
    }

    updateDiameters(hatDiameters, 1.2 * (24.0 / fps), max(width, height));
    if (hatCount < 0) {
      if (provider.beatDetector.isHat()) {
        hatDiameters.add(radius * 2);
        hatCount = 0;
      }
    }
    else {
      if (detectionIntervalFrame <= ++hatCount) {
        hatCount = -1;
      }
    }

    prepareAdditionalElements(provider);
  }
  
  protected final void doVisualize()
  {
    colorMode(RGB, 255, 255, 255, 100);
    blendMode(targetScene.blendMode);
    
    noFill();
 
    translate(width / 2, height / 2);

    ellipseMode(CENTER);
    strokeWeight(weightUnit * 2);
    stroke(red(fgColor), green(fgColor), blue(fgColor), alphaLevel);
    for (float diameter : kickDiameters) {
      ellipse(0, 0, diameter, diameter);
    }
    
    strokeWeight(weightUnit * 1.5);
    for (float diameter : hatDiameters) {
      ellipse(0, 0, diameter, diameter);
    }
    
    visualizeAdditionalElements();
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
  
  abstract protected void prepareAdditionalElements(MusicDataProvider provider);
  abstract protected void visualizeAdditionalElements();
}

final class BeatCircleAndFreqLevelVisualizer extends BeatCircleVisualizer
{
  private final List<Particle> rightParticles = new ArrayList<Particle>();
  private final List<Particle> leftParticles = new ArrayList<Particle>();

  BeatCircleAndFreqLevelVisualizer(SceneInfo scene)
  {
    super(scene, 40);
  }
  protected final void prepareAdditionalElements(MusicDataProvider provider)
  {
    updateParticles(rightParticles, provider.rightFft, false);
    updateParticles(leftParticles, provider.leftFft, true);
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
  protected final void visualizeAdditionalElements()
  {
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

final class BeatCircleAndOctavedFreqLevelVisualizer extends BeatCircleVisualizer
{
  private List< List< Float > > rightLevels;
  private List< List< Float > > leftLevels;

  BeatCircleAndOctavedFreqLevelVisualizer(SceneInfo scene)
  {
    super(scene, 67);
  }
  
  protected final void prepareAdditionalElements(MusicDataProvider provider)
  {
    setDetectionIntervalFrame(provider.getCrotchetQuantityFrame() / 4);
    
    SimpleEntry< List< List< Float > >, List< List<Float> > > octavedLevels = provider.getOctavedLevels();
    rightLevels = octavedLevels.getKey();
    leftLevels = octavedLevels.getValue();
  }
  protected final void visualizeAdditionalElements()
  {
    stroke(red(fgColor), green(fgColor), blue(fgColor), 80);
    drawLevels(rightLevels, false);
    drawLevels(leftLevels, true);
  }
  
  private void drawLevels(List< List< Float > > levels, boolean asLeft)
  {
    for(List<Float> levelPerScale : levels) {
      float angleStep = PI / levelPerScale.size();
      float unit = getShortSideLen() / 2;
      float x = 0, y = 0, prevX = 0, prevY = unit; 
      for (int index = 0; index < levelPerScale.size(); ++index) {
        float level = levelPerScale.get(index);
        x = (unit * (level / 20.0) * cos((PI / 2) + (angleStep * index))) * (asLeft ? -1 : 1);
        y = (unit * (level / 20.0) * sin((PI / 2) + (angleStep * index)));
        strokeWeight(screenCoordinator.getScaledValue(level * 1.5));
        line(prevX, prevY, x, y);
        prevX = x;
        prevY = y;
      }
      line(prevX, prevY, 0, -unit);
    }
  }
}

final class PoppingLevelVisualizer extends Visualizer
{
  private List<List<Float>> rightLevels;
  private List<List<Float>> leftLevels;
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
    SimpleEntry< List< List< Float > >, List< List<Float> > > octavedLevels = provider.getOctavedLevels();
    rightLevels = octavedLevels.getKey();
    leftLevels = octavedLevels.getValue();
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

final class SpreadOctagonVisualizer extends Visualizer
{
  private final List<List<List<ShapeSource>>> rightSourcesHistory;
  private final List<List<List<ShapeSource>>> leftSourcesHistory;
  private final color fgColor;
  private final color bgColor;
  
  SpreadOctagonVisualizer(SceneInfo scene)
  {
    super(scene);
    fgColor = scene.fgColor != null ? decodeColor(scene.fgColor) : #ffffff;
    bgColor = scene.bgColor != null ? decodeColor(scene.bgColor) : 0;
    
    rightSourcesHistory = new ArrayList<List<List<ShapeSource>>>(); 
    leftSourcesHistory = new ArrayList<List<List<ShapeSource>>>(); 
  }
  
  boolean isDrawable()
  {
    return 0 < rightSourcesHistory.size() || 0 < leftSourcesHistory.size();
  }

  private List<List<ShapeSource>> translateLevelsToPoints(List<List<Float>> levels, boolean asLeft)
  {
    List<List<ShapeSource>> points = new ArrayList<List<ShapeSource>>(); 
    for(List<Float> levelsPerScale : levels) {
      List<ShapeSource> pointsPerScale = new ArrayList<ShapeSource>(); 
      float angleStep = PI / levelsPerScale.size();
      float unit = getShortSideLen() / 2;
      for (int index = 0; index < levelsPerScale.size(); ++index) {
        float level = levelsPerScale.get(index);
        float x = (unit * (level / 20.0) * cos((PI / 2) + (angleStep * index))) * (asLeft ? 1 : -1);
        float y = (unit * (level / 20.0) * sin((PI / 2) + (angleStep * index)));
        pointsPerScale.add(new ShapeSource(new PVector(x, y, 0), screenCoordinator.getScaledValue(level * 8)));
      }
      points.add(pointsPerScale);
    }
    return points;
  }
  
  protected void doPrepare(MusicDataProvider provider, boolean isPrimary)
  {
    if (isPrimary) {
      background(bgColor);
      SimpleEntry< List< List< Float > >, List< List<Float> > > octavedLevels = provider.getOctavedLevels();
      rightSourcesHistory.add(translateLevelsToPoints(octavedLevels.getKey(), false));
      leftSourcesHistory.add(translateLevelsToPoints(octavedLevels.getValue(), true));
    }
    if ((isPrimary == false && rightSourcesHistory.isEmpty() == false) || 6 < rightSourcesHistory.size()) {
      rightSourcesHistory.remove(0);
    }
    if ((isPrimary == false && leftSourcesHistory.isEmpty() == false) || 6 < leftSourcesHistory.size()) {
      leftSourcesHistory.remove(0);
    }
  }
  protected void doVisualize()
  {
    colorMode(HSB, 360, 100, 100, 100);
    blendMode(targetScene.blendMode);
    
    translate(width / 2, height / 2);
    smooth();
    noFill();

    strokeWeight(screenCoordinator.getScaledValue(3));
    pushMatrix();
    int index = rightSourcesHistory.size();
    for (List<List<ShapeSource>> rightSources : rightSourcesHistory) {
      visualizeSources(rightSources, (float)index / rightSourcesHistory.size());
      rotateY((PI / rightSourcesHistory.size()) / 2);
      --index;
    }
    popMatrix();
    pushMatrix();
    index = leftSourcesHistory.size();
    for (List<List<ShapeSource>> leftSources : leftSourcesHistory) {
      visualizeSources(leftSources, (float)index / leftSourcesHistory.size());
      rotateY(-((PI / rightSourcesHistory.size()) / 2));
      --index;
    }
    popMatrix();
  }
  
  private void visualizeSources(List<List<ShapeSource>> sources, float intensity) {
    float h = hue(fgColor);
    float s = saturation(fgColor);
    float b = brightness(fgColor);
    stroke(color(h, s * ((1 - intensity) * 2), b, 75));
    Shape shape = new RegularPolygon(null, 8);
    for (List<ShapeSource> sourcesPerScale : sources) {
      for (ShapeSource source : sourcesPerScale) {
        shape.setSource(source).visualize();
      }
    }
  }
}