using UnityEngine;
using UnityEditor;
using UnityEditor.SceneManagement;

[CustomEditor(typeof(PaletteSwapper))]
public class PaletteSwapperEditor : Editor
{
    string[] shadingTypes = new string[]
    {
        "Channel Color Count", "Per Channel Color Counts", "Palette Swapping"
    };

    public override void OnInspectorGUI()
    {
        PaletteSwapper script = (PaletteSwapper)target;

        script.shader = (Shader)EditorGUILayout.ObjectField("Shader", script.shader, typeof(Shader), false);
        script.shaderType = EditorGUILayout.Popup("Type", script.shaderType, shadingTypes);

        script.downsampleCount = EditorGUILayout.IntSlider("Downsample Count", script.downsampleCount, 0, 8);
        script.ditherScatter = EditorGUILayout.Slider("Dither Scattering", script.ditherScatter, 0, 1);

        if (script.shaderType == 0)
        {
            int colorCount = EditorGUILayout.IntSlider("Color Count", script.redColorCount, 2, 16);
            script.redColorCount = colorCount;
            script.greenColorCount = colorCount;
            script.blueColorCount = colorCount;
        }
        if (script.shaderType == 1)
        {
            script.redColorCount = EditorGUILayout.IntSlider("R Color Count", script.redColorCount, 2, 16);
            script.greenColorCount = EditorGUILayout.IntSlider("G Color Count", script.greenColorCount, 2, 16);
            script.blueColorCount = EditorGUILayout.IntSlider("B Color Count", script.blueColorCount, 2, 16);
        }
        if (script.shaderType == 2)
        {
            script.palette = (Texture2D)EditorGUILayout.ObjectField("Palette", script.palette, typeof(Texture2D), false, GUILayout.Height(EditorGUIUtility.singleLineHeight));
            
            script.redColorCount = script.palette == null ? 8 : script.palette.width;
            script.greenColorCount = script.palette == null ? 8 : script.palette.width;
            script.blueColorCount = script.palette == null ? 8 : script.palette.width;
        }

        if (GUI.changed && !Application.isPlaying)
        {
            EditorUtility.SetDirty(script);
            EditorSceneManager.MarkSceneDirty(script.gameObject.scene);
        }
    }
}
