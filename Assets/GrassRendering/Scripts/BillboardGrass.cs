using UnityEngine;

public class BillboardGrass : MonoBehaviour
{
    public Material material;
    public Mesh mesh;
    [Range(0.1f, 2f)] public float grassDensity = 1f;
    [Range(0f, 1f)] public float displaceStrength = 0f;
    public float cullingDistance = 100f;
    public ComputeShader computeGrassData;
    public Texture2D heightMap, grassTexture;

    ComputeBuffer grassBuffer;
    GraphicsBuffer commandBuf;
    GraphicsBuffer.IndirectDrawIndexedArgs[] commandData;

    public bool updateGrass;

    void Start()
    {
        commandBuf = new GraphicsBuffer(GraphicsBuffer.Target.IndirectArguments, 1, GraphicsBuffer.IndirectDrawIndexedArgs.size);
        commandData = new GraphicsBuffer.IndirectDrawIndexedArgs[1];

        GenerateGrassBuffer();
    }

    void OnDestroy()
    {
        commandBuf?.Release();
        grassBuffer?.Release();
        commandBuf = null;
        grassBuffer = null;
    }

    void GenerateGrassBuffer()
    {
        Bounds bounds = GetComponent<MeshRenderer>().bounds;
        Vector2 size = new Vector2(Mathf.Floor(bounds.size.x), Mathf.Floor(bounds.size.z));
        grassBuffer = new ComputeBuffer(Mathf.CeilToInt(size.x * size.y * grassDensity * grassDensity), 4 * 4);

        computeGrassData.SetBuffer(0, "_GrassInstances", grassBuffer);
        computeGrassData.SetTexture(0, "_HeightMap", heightMap);
        computeGrassData.SetFloat("_DisplaceStrength", displaceStrength);
        computeGrassData.SetFloat("_Density", grassDensity);
        computeGrassData.SetVector("_Size", size);
        computeGrassData.SetVector("_Center", bounds.center);
        computeGrassData.Dispatch(0, Mathf.CeilToInt(size.x * grassDensity / 8.0f), Mathf.CeilToInt(size.y * grassDensity / 8.0f), 1);

        commandData[0].indexCountPerInstance = mesh.GetIndexCount(0);
        commandData[0].instanceCount = (uint)(size.x * size.y * grassDensity * grassDensity);
        commandBuf.SetData(commandData);
    }

    void Update()
    {
        RenderParams rp = new RenderParams(material);
        rp.worldBounds = new Bounds(Vector3.zero, 5000*Vector3.one); // use tighter bounds for better FOV culling
        rp.matProps = new MaterialPropertyBlock();
        rp.matProps.SetBuffer("_GrassInstances", grassBuffer);
        rp.matProps.SetTexture("_GrassSampler", grassTexture);
        rp.matProps.SetFloat("_CullingDistance", cullingDistance);

        Graphics.RenderMeshIndirect(rp, mesh, commandBuf);
        rp.matProps.SetFloat("_RotationDegrees", 60f);
        Graphics.RenderMeshIndirect(rp, mesh, commandBuf);
        rp.matProps.SetFloat("_RotationDegrees", -60f);
        Graphics.RenderMeshIndirect(rp, mesh, commandBuf);

        if (updateGrass)
        {
            UpdateGrassEditor();
            updateGrass = false;
        }
    }

    void UpdateGrassEditor()
    {
        grassBuffer?.Release();
        GenerateGrassBuffer();
    }
}