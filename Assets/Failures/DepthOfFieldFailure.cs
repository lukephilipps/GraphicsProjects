using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class DepthOfFieldFailure : MonoBehaviour
{
    public Shader postProcessingShader;
    private Material postProcessingMaterial;
    public float focusDistance = 10f;
    public float focusRange = 3f;
    [Range(0, 1)] public float focusStrength = 0.5f;
    [Range(0, 4)] public int maxFilterRadius = 1;
    [Range(0, 5)] public int boxBlurRadius = 3;
    [Range(1, 2)] public float exposure = 1.0f;
    [Range(0, 5)] public float luminanceBias = 0.1f;

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
        RenderTexture nearMask, farMask, temp1, temp2, temp3, sourceTonemapped;
        nearMask = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
        farMask = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
        temp1 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
        temp2 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
        temp3 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
        sourceTonemapped = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);

        // Apply Reverse tonemap
        postProcessingMaterial.SetFloat("_Exposure", exposure);
        Graphics.Blit(source, sourceTonemapped, postProcessingMaterial, 7);

        // Get near CoC
        postProcessingMaterial.SetFloat("_Bound1", focusDistance - focusRange * focusStrength + 0.01f);
        postProcessingMaterial.SetFloat("_Bound2", focusDistance - focusRange);
        Graphics.Blit(source, temp2, postProcessingMaterial, 0);

        // Apply max filter to near CoC
        postProcessingMaterial.SetInt("_MaxFilterRadius", maxFilterRadius);
        Graphics.Blit(temp2, temp3, postProcessingMaterial, 4);

        // Apply box blur to near CoC
        postProcessingMaterial.SetInt("_BoxBlurRadius", boxBlurRadius);
        Graphics.Blit(temp3, nearMask, postProcessingMaterial, 5);

        RenderTexture.ReleaseTemporary(temp2);
        RenderTexture.ReleaseTemporary(temp3);
        temp2 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
        temp3 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);

        // Get far CoC
        postProcessingMaterial.SetFloat("_Bound1", focusDistance + focusRange * focusStrength - 0.01f);
        postProcessingMaterial.SetFloat("_Bound2", focusDistance + focusRange);
        Graphics.Blit(source, farMask, postProcessingMaterial, 0);

        // Get far field
        postProcessingMaterial.SetTexture("_FarMask", farMask);
        Graphics.Blit(sourceTonemapped, temp1, postProcessingMaterial, 1);

        // Blur far field
        postProcessingMaterial.SetFloat("_LuminanceBias", luminanceBias);
        Graphics.Blit(temp1, temp2, postProcessingMaterial, 6);

        // Interpolate between source and far
        postProcessingMaterial.SetTexture("_BlurTex", temp2);
        postProcessingMaterial.SetTexture("_Mask", farMask);
        Graphics.Blit(sourceTonemapped, temp3, postProcessingMaterial, 3);

        Graphics.Blit(temp3, destination);

        RenderTexture.ReleaseTemporary(temp1);
        temp1 = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);

        // Blur close field
        Graphics.Blit(sourceTonemapped, temp1, postProcessingMaterial, 6);

        // Interpolate between blurred source/far and near
        postProcessingMaterial.SetTexture("_BlurTex", temp1);
        postProcessingMaterial.SetTexture("_Mask", nearMask);
        Graphics.Blit(temp3, destination, postProcessingMaterial, 3);

        RenderTexture.ReleaseTemporary(nearMask);
        RenderTexture.ReleaseTemporary(farMask);
        RenderTexture.ReleaseTemporary(temp1);
        RenderTexture.ReleaseTemporary(temp2);
        RenderTexture.ReleaseTemporary(temp3);
        RenderTexture.ReleaseTemporary(sourceTonemapped);
    }
}
