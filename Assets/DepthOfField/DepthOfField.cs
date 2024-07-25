using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class DepthOfField : MonoBehaviour
{
    public Shader dofShader;
    private Material dofMaterial;
    [Range(0.1f, 100f)] public float focusDistance = 10f;
    [Range(0.1f, 10f)] public float focusRange = 3f;
    [Range(0f, 1f)] public float focusBlend = 0.15f;
    [Range(0, 5)] public int maxFilterRadius = 3;
    [Range(0, 5)] public int boxBlurRadius = 5;
    [Range(0, 5)] public float luminanceBias = 0.05f;
    [Range(1, 2)] public float exposure = 1.02f;
    public bool useHDR = true;

    void Start()
    {
        if (dofMaterial == null)
        {
            dofMaterial = new Material(dofShader);
            dofMaterial.hideFlags = HideFlags.HideAndDontSave;
        }
    }
    
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        RenderTexture sourceHDR, coc, cocTemp, temp, blurColor;
        coc = RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.RGFloat, RenderTextureReadWrite.Linear);
        cocTemp = RenderTexture.GetTemporary(source.width, source.height, 0, RenderTextureFormat.RGFloat, RenderTextureReadWrite.Linear);
        temp = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
        blurColor = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);

        if (useHDR)
        {
            sourceHDR = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
            Graphics.Blit(source, sourceHDR, dofMaterial, 0);
        }
        else sourceHDR = source;

        dofMaterial.SetFloat("_FocusDistance", focusDistance);
        dofMaterial.SetFloat("_FocusRange", focusRange);
        dofMaterial.SetFloat("_FocusBlend", 1.0f - focusBlend);
        dofMaterial.SetFloat("_LuminanceBias", luminanceBias);
        dofMaterial.SetFloat("_Exposure", exposure);
        dofMaterial.SetInt("_MaxFilterRadius", maxFilterRadius);
        dofMaterial.SetInt("_BoxBlurRadius", boxBlurRadius);
        dofMaterial.SetTexture("_CoC", coc);
        dofMaterial.SetTexture("_Blur", blurColor);

        // Create Circle of Confusion and max filter/box blur close field
        Graphics.Blit(sourceHDR, coc, dofMaterial, 2);
        Graphics.Blit(coc, cocTemp, dofMaterial, 3);
        Graphics.Blit(cocTemp, coc, dofMaterial, 4);

        // Get far color and blend with source image
        Graphics.Blit(sourceHDR, temp, dofMaterial, 5);
        Graphics.Blit(temp, blurColor, dofMaterial, 6);
        Graphics.Blit(sourceHDR, temp, dofMaterial, 7);

        // Get close color and blend with previous image
        Graphics.Blit(sourceHDR, blurColor, dofMaterial, 6);
        if (useHDR) 
        {
            // No longer need sourceHDR, use it like a temp buffer to Tonemap HDR->SDR
            Graphics.Blit(temp, sourceHDR, dofMaterial, 8);
            Graphics.Blit(sourceHDR, destination, dofMaterial, 1);
        }
        else Graphics.Blit(temp, destination, dofMaterial, 8);

        RenderTexture.ReleaseTemporary(coc);
        RenderTexture.ReleaseTemporary(cocTemp);
        RenderTexture.ReleaseTemporary(temp);
        RenderTexture.ReleaseTemporary(blurColor);
        if (useHDR) RenderTexture.ReleaseTemporary(sourceHDR);
    }
}
