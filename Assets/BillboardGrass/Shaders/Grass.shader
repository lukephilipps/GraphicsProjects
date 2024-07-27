Shader "Projects/Grass/Billboard"
{
    SubShader
    {
        Cull Off
        ZWrite On
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.5

            #include "UnityCG.cginc"
            #define UNITY_INDIRECT_DRAW_ARGS IndirectDrawIndexedArgs
            #include "UnityIndirect.cginc"
            
            struct GrassInstance
            {
                float3 position;
                float height;
            };
            
            struct a2v
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float height : TEXCOORD1;
            };
            
            StructuredBuffer<GrassInstance> _GrassInstances;
            float _RotationDegrees;
            float _CullingDistance = 100.0f;

            sampler2D _GrassSampler;

            bool CullVertice(float3 vPosition, float cullBias)
            {
                float4 vertex = float4(vPosition, 1.0f);
                return 
                    dot(vertex, unity_CameraWorldClipPlanes[0]) < cullBias || // Left Plane
                    dot(vertex, unity_CameraWorldClipPlanes[1]) < cullBias || // Right Plane
                    dot(vertex, unity_CameraWorldClipPlanes[2]) < cullBias || // Bottom Plane
                    dot(vertex, unity_CameraWorldClipPlanes[3]) < cullBias || // Top Plane
                    distance(vPosition, _WorldSpaceCameraPos) > _CullingDistance; // Distance culling
            }

            // Acquired from https://forum.unity.com/threads/rotating-mesh-in-vertex-shader.501709/
            float4 RotateAroundYInDegrees(float4 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float4(mul(m, vertex.xz), vertex.yw).xzyw;
            }

            v2f vert(a2v v, uint svInstanceID : SV_InstanceID)
            {
                InitIndirectDrawArgs(0);
                v2f o;

                uint instanceID = GetIndirectInstanceID(svInstanceID);
                GrassInstance grassInstance = _GrassInstances[instanceID];

                v.pos = RotateAroundYInDegrees(v.pos, _RotationDegrees);

                v.pos.xyz += grassInstance.position;

                v.pos.x += cos(_Time.y + v.pos.x) * v.uv.y * .2f;
                v.pos.y += grassInstance.height * v.uv.y;

                if (CullVertice(v.pos.xyz, -2.0f)) o.pos = 0.0f;
                else o.pos = UnityObjectToClipPos(v.pos);
                
                o.uv = v.uv;
                o.height = grassInstance.height;

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 color = tex2D(_GrassSampler, i.uv);
                
                float tipColor = lerp(0, i.height, i.uv.y * i.uv.y) * 0.5f;
                color.rg += tipColor;
                color.b += tipColor * 0.5f;
                
                clip(color.a - 0.5);

                return color;
            }
            ENDCG
        }
    }
}