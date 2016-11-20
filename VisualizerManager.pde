/**
 * VisualizerManager
 * @author Sad Juno
 * @version 201609
 */
 
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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