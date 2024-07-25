using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class QuantizationDither : MonoBehaviour
{
    [Range(0, 8)] public int downSampleCount = 1;
    [Range(0, 1)] public float scatter = .03f;

    public Shader postProcessingShader;
    private Material postProcessingMaterial;

    void Update()
    {
        if (Input.GetKeyDown("left")) downSampleCount = Mathf.Max(downSampleCount - 1, 0);
        if (Input.GetKeyDown("right")) downSampleCount = Mathf.Min(downSampleCount + 1, 8);
    }

    void Start()
    {
        if (postProcessingMaterial == null)
        {
            postProcessingMaterial = new Material(postProcessingShader);

            // Hides the material info in editor
            postProcessingMaterial.hideFlags = HideFlags.HideAndDontSave;
        }
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        RenderTexture[] renderTextures = new RenderTexture[downSampleCount];
        RenderTexture downsampledSource = source;

        int width = source.width;
        int height = source.height;

        for (int i = 0; i < downSampleCount; ++i)
        {
            width /= 2;
            height /= 2;

            renderTextures[i] = RenderTexture.GetTemporary(width, height, 0, source.format);

            Graphics.Blit(downsampledSource, renderTextures[i], postProcessingMaterial, 1);

            downsampledSource = renderTextures[i];
        }

        RenderTexture ditheredTexture = RenderTexture.GetTemporary(width, height, 0, source.format);

        postProcessingMaterial.SetFloat("_Scatter", scatter);
        Graphics.Blit(downsampledSource, ditheredTexture, postProcessingMaterial, 0);
        Graphics.Blit(ditheredTexture, destination, postProcessingMaterial, 1);

        RenderTexture.ReleaseTemporary(ditheredTexture);
        foreach(RenderTexture texture in renderTextures) RenderTexture.ReleaseTemporary(texture);
    }
}
