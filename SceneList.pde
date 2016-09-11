/**
 * SceneList
 * @author Sad Juno
 * @version 201605
 */
 
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

final class SceneList
{
  final boolean repeatPlayback; 
  final List<SceneInfo> scenes;

  SceneList(XML scenesElement)
  {
    List<SceneInfo> sceneList = new ArrayList<SceneInfo>();
    
    repeatPlayback = (scenesElement.getString("repeat").toLowerCase().equals("yes"));
    for (XML scene : scenesElement.getChildren()) {
      if (scene.getName().equals("scene")) {
        String filePath = "";
        float bpm = 120;
        String visualizer = "";
        String fgColor = null;
        String bgColor = null;
        String blendModeName = "NORMAL";
        for (XML detail : scene.getChildren()) {
          switch (detail.getName()) {
            case "file":
              filePath = detail.getContent();
              break;
            case "beatPerMinute":
              bpm = Float.parseFloat(detail.getContent());
              break;
            case "visualization":
              for (XML visualization : detail.getChildren()) {
                switch (visualization.getName()) {
                  case "visualizer":
                    visualizer = visualization.getContent();
                    break;
                  case "color":
                    fgColor = visualization.getContent();
                    break;
                  case "backgroundColor":
                    bgColor = visualization.getContent();
                    break;
                  case "blendMode":
                    blendModeName = visualization.getContent().trim();
                    break;
                }
              }
              break;
          }
        }
        sceneList.add(new SceneInfo(bpm, filePath, visualizer, fgColor, bgColor,blendModeName));
      }
    }
    scenes = Collections.unmodifiableList(sceneList);
  }
  
  SceneInfo get(int index)
  {
    return scenes.get(index);
  }
}