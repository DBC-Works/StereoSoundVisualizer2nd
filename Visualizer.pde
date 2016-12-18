/**
 * Visualizer
 * @author Sad Juno
 * @version 201605
 */

import java.util.Iterator;
 
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

  void keyReleased()
  {
  }
  void mouseReleased()
  {
  }
}