/**
 * Visualizer
 * @author Sad Juno
 * @version 201712
 */

import java.util.Iterator;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
 
abstract class Visualizer
{
  protected final SceneInfo targetScene;

  Visualizer(SceneInfo scene)
  {
    targetScene = scene;
  }
  final Visualizer prepare(MusicDataProvider provider, boolean isPrimary)
  {
    doPrepare(provider, isPrimary);
    return this;
  }
  final Visualizer visualize()
  {
    if (isDrawable()) {
      pushMatrix();
      doVisualize();
      popMatrix();
    }
    return this;
  }
  
  abstract boolean isDrawable();
  protected abstract void doPrepare(MusicDataProvider provider, boolean isPrimary);
  protected abstract void doVisualize();

  protected color decodeColor(String nm)
  {
    int c = Integer.decode(nm); 
    return nm.startsWith("#0000") && c < 256 ? color(0, 0, c) : color(c);
  }
  protected int getShortSideLen()
  {
    return min(width, height); 
  }
  
  void keyReleased()
  {
  }
  void mouseReleased()
  {
  }
}

final class VisualizerManager
{
  private final List<String> visualizerNames;
  private final List<Visualizer> visualizers = new ArrayList<Visualizer>();

  VisualizerManager(XML visualizersElement)
  {
    visualizerNames = new ArrayList<String>();
    
    for (XML visualizer : visualizersElement.getChildren()) {
      String elementName = visualizer.getName();
      if (elementName.equals("visualizer")) {
        visualizerNames.add(visualizer.getContent());
      }
    }
  }
  
  void setupVisualizers(final SceneInfo scene)
  {
    Map<String,Visualizer> map = new HashMap<String,Visualizer>() {
      {
        put("Ellipse rotation", new EllipseRotationVisualizer(scene));
        put("Particle fountain", new ParticleFountainVisualizer(scene));
        put("Noise steering line", new NoiseSteeringLineVisualizer(scene));
        put("Level trace", new LevelTraceVisualizer(scene));
        put("Noise steering curve line", new NoiseSteeringCurveLineVisualizer(scene));
        put("Beat circle and frequency level", new BeatCircleAndFreqLevelVisualizer(scene));
        put("Popping level", new PoppingLevelVisualizer(scene));
        put("Beat circle and octaved frequency level", new BeatCircleAndOctavedFreqLevelVisualizer(scene));
        put("Spread octagon level", new SpreadOctagonVisualizer(scene));
        put("Triple regular octahedron", new TripleRegularOctahedronVisualizer(scene));
      }
    };
    
    Visualizer primaryVisualizer = null;
    visualizers.clear();
    for (String name : visualizerNames) {
      if (map.containsKey(name)) {
        if (name.equals(scene.visualizer)) {
          primaryVisualizer = map.get(name);
        }
        else {
          visualizers.add(map.get(name));
        }
      }
    }
    if (primaryVisualizer != null) {
      visualizers.add(primaryVisualizer);
    }
  }
  void visualize(MusicDataProvider provider)
  {
    Visualizer primaryVisualizer = visualizers.get(visualizers.size() - 1);
    primaryVisualizer.prepare(provider, true);
    for (int index = 0; index < visualizers.size() - 2; ++index) {
      Visualizer visualizer = visualizers.get(index);
      visualizer.prepare(provider, false);
      if (visualizer.isDrawable() == false) {
        visualizer.visualize();
      }
    }
    primaryVisualizer.visualize();
  }
  void keyReleased()
  {
    for (Visualizer visualizer : visualizers) {
      visualizer.keyReleased();
    }
  }
  void mouseReleased()
  {
    for (Visualizer visualizer : visualizers) {
      visualizer.mouseReleased();
    }
  }
}