using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class Sharpen : MonoBehaviour
{
    private Material postProcessingMaterial;
    public Shader postProcessingShader;
    [Range(0, 1)] public float sharpness;

    void Start()
    {
        if (postProcessingMaterial == null)
        {
            postProcessingMaterial = new Material(postProcessingShader);
            postProcessingMaterial.hideFlags = HideFlags.HideAndDontSave;
        }
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        postProcessingMaterial.SetFloat("_Sharpness", sharpness);
        Graphics.Blit(source, destination, postProcessingMaterial);
    }
}
