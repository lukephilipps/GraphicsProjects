using UnityEngine;
using UnityEditor;
using UnityEditor.SceneManagement;

[CustomEditor(typeof(DepthOfField))]
public class DepthOfFieldEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DepthOfField script = (DepthOfField)target;
        
        script.dofShader = (Shader)EditorGUILayout.ObjectField("DoF Shader", script.dofShader, typeof(Shader), false);

        EditorGUILayout.LabelField("Circle of Confusion", EditorStyles.boldLabel);
        script.focusDistance = EditorGUILayout.Slider("Focus Distance", script.focusDistance, 0.1f, 100f);
        script.focusRange = EditorGUILayout.Slider("Focus Range", script.focusRange, 0.1f, 10f);
        script.focusBlend = EditorGUILayout.Slider("Focus Blend", script.focusBlend, 0f, 1f);
        
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("CoC Near Bound", EditorStyles.boldLabel);
        script.maxFilterRadius = EditorGUILayout.IntSlider("Max Filter Radius", script.maxFilterRadius, 0, 5);
        script.boxBlurRadius = EditorGUILayout.IntSlider("Box Blur Radius", script.boxBlurRadius, 0, 5);
        
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Blur", EditorStyles.boldLabel);
        script.luminanceBias = EditorGUILayout.Slider("Karis Luminance Bias", script.luminanceBias, 0f, 5f);
        
        EditorGUILayout.Space();
        EditorGUILayout.LabelField("HDR", EditorStyles.boldLabel);
        script.useHDR = EditorGUILayout.Toggle("Use HDR", script.useHDR);
        if (script.useHDR) script.exposure = EditorGUILayout.Slider("Exposure", script.exposure, 1f, 2f);

        if (GUI.changed && !Application.isPlaying)
        {
            EditorUtility.SetDirty(script);
            EditorSceneManager.MarkSceneDirty(script.gameObject.scene);
        }
    }
}
