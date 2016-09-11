/**
 * SceneInfo
 * @author Sad Juno
 * @version 201605
 */
 
final class SceneInfo
{
  final float beatPerMinute;
  final String filePath;
  final String visualizer;
  final int blendMode;
  String fgColor;
  String bgColor;

  SceneInfo(
    float bpm,
    String path,
    String v,
    String fg,
    String bg,
    String blendModeName)
  {
    beatPerMinute = bpm;
    filePath = path;
    visualizer = v;
    fgColor = fg;
    bgColor = bg;
    switch (blendModeName.toUpperCase()) {
      case "NORMAL":
        blendMode = NORMAL;
        break;
      case "ADD":
        blendMode = ADD;
        break;
      case "SUBTRACT":
        blendMode = SUBTRACT;
        break;
      case "DARKEST": 
        blendMode = DARKEST;
        break;
      case "LIGHTEST": 
        blendMode = LIGHTEST;
        break;
      case "DIFFERENCE": 
        blendMode = DIFFERENCE;
        break;
      case "EXCLUSION":
        blendMode = EXCLUSION;
        break;
      case "MULTIPLY": 
        blendMode = MULTIPLY;
        break;
      case "SCREEN": 
        blendMode = SCREEN;
        break;
      case "REPLACE":
        blendMode = REPLACE;
        break;
      default:
        blendMode = NORMAL;
        break;
    }
  }
}