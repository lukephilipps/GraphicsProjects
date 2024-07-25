using System.Collections.Generic;
using UnityEngine;

public class CullCloseObjects : MonoBehaviour
{
    private struct CloseObject
    {
        public CloseObject(Transform transform, Material material, int layer)
        {
            this.transform = transform;
            this.material = material;
            this.layer = layer;
        }

        public Transform transform;
        public Material material;
        public int layer;
    }

    public Shader ditherShader;
    public float closeDistance = 1f;
    [Layer] public int closeLayer;
    [Range(0, 1)] public float closeAlpha = 0.5f;

    private RenderTexture overlayTexture;
    private Material ditherMaterial;
    private List<CloseObject> closeObjects;
    private Camera mainCamera, rtCamera;
    private int screenWidth, screenHeight;

    void Start()
    {
        Camera.onPreRender += OnPreRenderCallback;
        Camera.onPostRender += OnPostRenderCallback;

        mainCamera = GetComponent<Camera>();
        mainCamera.cullingMask = mainCamera.cullingMask | (1 << closeLayer);

        closeObjects = new List<CloseObject>();

        ditherMaterial = new Material(ditherShader);
        ditherMaterial.hideFlags = HideFlags.HideAndDontSave;

        GameObject newObj = new GameObject("Camera Holder");
        newObj.transform.parent = transform;
        newObj.transform.position = transform.position;
        newObj.transform.rotation = transform.rotation;
        
        rtCamera = newObj.AddComponent<Camera>();
        overlayTexture = new RenderTexture(Screen.width, Screen.height, 24);

        InitializeRenderTargetCamera();

        screenWidth = Screen.width;
        screenHeight = Screen.height;
    }

    void OnDestroy()
    {
        Camera.onPreRender -= OnPreRenderCallback;
        Camera.onPostRender -= OnPostRenderCallback;
    }

    void Update()
    {
        // Reset previous hit materials
        {
            foreach(CloseObject closeObject in closeObjects)
            {
                closeObject.transform.gameObject.layer = closeObject.layer;
            }
            closeObjects.Clear();
        }

        // Raycast from camera to check for close objects
        {
            Ray ray = mainCamera.ViewportPointToRay(new Vector3(0.5f, 0.5f, 0));
            ray.origin -= transform.forward * mainCamera.nearClipPlane;

            foreach (RaycastHit hit in Physics.SphereCastAll(ray, 0.5f, closeDistance + mainCamera.nearClipPlane - 0.5f))
            {
                Transform hitTransform = hit.transform;
                Renderer hitRenderer = hitTransform.GetComponent<Renderer>();

                if (hitRenderer != null)
                {
                    closeObjects.Add(new CloseObject(hitTransform, hitRenderer.material, hitTransform.gameObject.layer));
                    hitTransform.gameObject.layer = closeLayer;
                }
            }
        }

        if (screenWidth != Screen.width || screenHeight != Screen.height) ResizeRenderTexture();
    }

    void OnPreRenderCallback(Camera cam)
    {
        if (cam == mainCamera)
        {
            foreach (CloseObject closeObject in closeObjects)
            {
                ditherMaterial.SetTexture("_OverlayTex", overlayTexture);
                ditherMaterial.SetFloat("_OverlayAlpha", closeAlpha);
                closeObject.transform.GetComponent<Renderer>().material = ditherMaterial;
            }
        }
    }

    void OnPostRenderCallback(Camera cam)
    {
        if (cam == mainCamera)
        {
            foreach (CloseObject closeObject in closeObjects)
            {
                closeObject.transform.GetComponent<Renderer>().material = closeObject.material;
            }
        }
    }

    void InitializeRenderTargetCamera()
    {
        rtCamera.CopyFrom(mainCamera);
        rtCamera.targetTexture = overlayTexture;
        rtCamera.cullingMask = (1 << closeLayer);
        rtCamera.clearFlags = CameraClearFlags.SolidColor;
        rtCamera.backgroundColor = new Color(0.0f, 0.0f, 0.0f, 0.0f);
        rtCamera.depth = mainCamera.depth - 1;
    }

    void ResizeRenderTexture()
    {
        overlayTexture.Release();
        overlayTexture = new RenderTexture(Screen.width, Screen.height, 24);
        rtCamera.targetTexture = overlayTexture;
    }
}