//Author:doublecats
//https://x.com/doublecats1
//https://space.bilibili.com/442123027
//https://www.patreon.com/doublecats/shop
Shader "DC/DoubleCats_scene_distort2"
{
	Properties
	{
		[NoScaleOffset]_Normal_Tex("Normal_Tex", 2D) = "white" {}
		_normal_uv("normal_uv", Vector) = (1,1,0,0)
		_normal_speed("normal_speed", Vector) = (1,0,0,0)
		_Distort_power("Distort_power", Range( 0 , 1)) = 1
		_MaskTex("MaskTex", 2D) = "white" {}
		[Enum(Off,0,On,1)]_Zwrite("Zwrite", Float) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)]_Ztest("Ztest", Float) = 4
		[Enum(UnityEngine.Rendering.CullMode)]_Cull("Cull", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque" "Queue"="Transparent" "RenderPipeline" = "UniversalPipeline" }
		LOD 100

		HLSLPROGRAM 
		#pragma target 3.0
		ENDHLSL
		Blend SrcAlpha OneMinusSrcAlpha
		AlphaToMask Off
		Cull [_Cull]
		ColorMask RGBA
		ZWrite [_Zwrite]
		ZTest [_Ztest]
		Offset 0 , 0
		
		
		GrabPass{ }

		Pass
		{
			Name "Unlit"
			Tags { "LightMode"="ForwardBase" }
			HLSLPROGRAM 

			#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
			#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex);
			#else
			#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex)
			#endif


			#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
			//only defining to not throw compilation error over Unity 5.5
			#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
			#endif
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			//#include <HLSLSupport.cginc>
			//#include <UnityShaderUtilities.cginc>

			#include <HLSLSupport.cginc>
			#include <UnityShaderUtilities.cginc>

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"
			//#include "UnityShaderVariables.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct Varyings
			{
				float4 vertex : SV_POSITION;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 worldPos : TEXCOORD0;
				#endif
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform float _Ztest;
			uniform float _Cull;
			uniform float _Zwrite;
			ASE_DECLARE_SCREENSPACE_TEXTURE( _GrabTexture )
			uniform sampler2D _Normal_Tex;
			uniform float4 _normal_speed;
			uniform float4 _normal_uv;
			uniform float _Distort_power;
			uniform sampler2D _MaskTex;
			uniform float4 _MaskTex_ST;
			inline float4 ASE_ComputeGrabScreenPos( float4 pos )
			{
				#if UNITY_UV_STARTS_AT_TOP
				float scale = -1.0;
				#else
				float scale = 1.0;
				#endif
				float4 o = pos;
				o.y = pos.w * 0.5f;
				o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
				return o;
			}
			

			
			Varyings vert ( appdata v )
			{
				Varyings o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float4 ase_clipPos = UnityObjectToClipPos(v.vertex);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord1 = screenPos;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				o.ase_color = v.color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = vertexValue;
				#if ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif
				o.vertex = UnityObjectToClipPos(v.vertex);

				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				#endif
				return o;
			}
			
			half4  frag (Varyings i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 WorldPosition = i.worldPos;
				#endif
				float4 screenPos = i.ase_texcoord1;
				float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( screenPos );
				float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
				float2 temp_output_6_0 = (ase_grabScreenPosNorm).xy;
				float4 break11_g75 = _normal_speed;
				float mulTime5_g75 = _Time.y * break11_g75.z;
				float2 appendResult6_g75 = (float2(break11_g75.x , break11_g75.y));
				float4 break10_g75 = _normal_uv;
				float2 appendResult2_g75 = (float2(break10_g75.x , break10_g75.y));
				float2 appendResult3_g75 = (float2(break10_g75.z , break10_g75.w));
				float2 texCoord4_g75 = i.ase_texcoord2.xy * appendResult2_g75 + appendResult3_g75;
				float2 panner1_g75 = ( mulTime5_g75 * appendResult6_g75 + texCoord4_g75);
				float2 uv_MaskTex = i.ase_texcoord2.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				float2 lerpResult9 = lerp( temp_output_6_0 , ( temp_output_6_0 + (UnpackNormal( tex2D( _Normal_Tex, panner1_g75 ) )).xy ) , ( _Distort_power * i.ase_color.a * tex2D( _MaskTex, uv_MaskTex ).r ));
				float4 screenColor3 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture,lerpResult9);
				
				
				finalColor = saturate( screenColor3 );
				return finalColor;
			}
			ENDHLSL
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
