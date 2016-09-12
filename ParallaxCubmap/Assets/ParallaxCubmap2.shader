Shader "ParallaxCubmap2" {
Properties {
    _Color ("Main Color", Color) = (1,1,1,1)
    _ReflectColor ("Reflection Color", Color) = (1,1,1,0.5)
    _MainTex ("Base (RGB) RefStrength (A)", 2D) = "white" {}
    _Cube ("Reflection Cubemap", Cube) = "_Skybox" { TexGen CubeReflect }
    _BumpMap ("Normalmap", 2D) = "bump" {}
    _BoxPosition ("Bounding Box Position", Vector) = (0, 0, 0)
    _BoxSize ("Bounding Box Size", Vector) = (10, 10, 10)
	_Roughness("Roughness", Range(0, 6)) = 0
}
 
SubShader {
    Tags { "RenderType"="Opaque" }
    LOD 300
   
CGPROGRAM
#pragma target 3.0
#pragma glsl
#pragma surface surf Lambert
 
sampler2D _MainTex;
sampler2D _BumpMap;
sampler2D _Billboard;
samplerCUBE _Cube;
 
fixed4 _Color;
fixed4 _ReflectColor;
float3 _BoxSize;
float3 _BoxPosition;
float3 _QuadPosition;
fixed4 _QuadNormal;
float4x4 _QuadInverseMatrix;
half _Roughness;
 
struct Input {
    float2 uv_MainTex;
    float2 uv_BumpMap;
    fixed3 worldPos;
    float3 worldNormal;
    INTERNAL_DATA
};
 
void surf (Input IN, inout SurfaceOutput o) {
    // Base diffuse texture
    fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
    fixed4 c = tex * _Color;
    o.Albedo = c.rgb;
   
    fixed3 n = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
   
    // Reflection-ray
	float3 wpos = float3(_Object2World[0].w, _Object2World[1].w, _Object2World[2].w);
		float3 viewDir = IN.worldPos - 0 - (_WorldSpaceCameraPos - 0);
    float3 worldNorm = IN.worldNormal;
    worldNorm.xy -= n;
    float3 reflectDir = reflect (viewDir, worldNorm);
    fixed3 nReflDirection = normalize(reflectDir);
   
    // Parallax correction
	half3 boxStart = _BoxPosition - _BoxSize / 2.0;
		half3 firstPlaneIntersect = (boxStart + _BoxSize - IN.worldPos) / nReflDirection;
		half3 secondPlaneIntersect = (boxStart - IN.worldPos) / nReflDirection;
		half3 furthestPlane = (nReflDirection > 0.0) ? firstPlaneIntersect : secondPlaneIntersect;//max(firstPlaneIntersect, secondPlaneIntersect);// (nReflDirection > 0.0) ? firstPlaneIntersect : secondPlaneIntersect;
    half3 intersectDistance = min(min(furthestPlane.x, furthestPlane.y), furthestPlane.z);
    half3 intersectPosition = IN.worldPos + nReflDirection * intersectDistance;
    fixed4 reflcol = texCUBElod(_Cube, float4(intersectPosition - _BoxPosition, _Roughness));
   
    // Reflection display
    reflcol *= tex.a;
    o.Emission = reflcol.rgb * _ReflectColor.rgb;
    o.Alpha = reflcol.a * _ReflectColor.a;
}
ENDCG
}
 
FallBack "Reflective/VertexLit"
}