using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/* A post-processor allowing edit of:
    - Downsampling (pixelization)
    - Dithering
    - Color quantization
    - Palette Swapping
*/ 
[RequireComponent(typeof(Camera))]
public class PaletteSwapper : MonoBehaviour
{
    [HideInInspector] public int shaderType = 0; //0 = Channel Color Count, 1 = Per Channel Color Counts, 2 = Palette Swapping

    public Texture2D palette;
    public Shader shader;
    [Range(0, 8)] public int downsampleCount = 1;
    [Range(0, 1)] public float ditherScatter = .03f;
    [Range(2, 16)] public int redColorCount;
    [Range(2, 16)] public int greenColorCount;
    [Range(2, 16)] public int blueColorCount;

    private Material postProcessingMaterial;

    void Start()
    {
        if (postProcessingMaterial == null)
        {
            postProcessingMaterial = new Material(shader);
            postProcessingMaterial.hideFlags = HideFlags.HideAndDontSave;
        }
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        RenderTexture tempSource, tempDestination;
        tempSource = source;

        int width = source.width;
        int height = source.height;

        // Downscale the source
        for (int i = 0; i < downsampleCount; ++i)
        {
            width /= 2;
            height /= 2;

            tempDestination = RenderTexture.GetTemporary(width, height, 0, source.format);

            Graphics.Blit(tempSource, tempDestination, postProcessingMaterial, 0);

            RenderTexture.ReleaseTemporary(tempSource);
            tempSource = tempDestination;
        }

        postProcessingMaterial.SetFloat("_Scatter", ditherScatter);
        postProcessingMaterial.SetFloat("_RedColorCount", redColorCount);
        postProcessingMaterial.SetFloat("_GreenColorCount", greenColorCount);
        postProcessingMaterial.SetFloat("_BlueColorCount", blueColorCount);

        RenderTexture dither = RenderTexture.GetTemporary(width, height, 0, source.format);

        // Dither the rendered texture
        Graphics.Blit(tempSource, dither, postProcessingMaterial, 1);
        RenderTexture.ReleaseTemporary(tempSource);

        // If using a palette grayscale the image and then render the palette
        if (shaderType == 2)
        {
            postProcessingMaterial.SetTexture("_Palette", palette);
            tempDestination = RenderTexture.GetTemporary(width, height, 0, source.format);
            Graphics.Blit(dither, tempDestination, postProcessingMaterial, 3);
            Graphics.Blit(tempDestination, destination, postProcessingMaterial, palette == null ? 0 : 2);
            RenderTexture.ReleaseTemporary(tempDestination);
        }
        else
        {
            Graphics.Blit(dither, destination, postProcessingMaterial, 0);
        }
        RenderTexture.ReleaseTemporary(dither);
    }
}
