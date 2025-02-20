//Author:doublecats
//https://x.com/doublecats1
//https://space.bilibili.com/442123027
//https://www.patreon.com/doublecats/shop
Shader "DC/DoubleCats_GlitchSplit"
{
	Properties
	{

		[Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Float) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 8
		[Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull Mode", Float) = 0


		_mask("mask", 2D) = "white" {}
		_Base_alpha("Base_alpha", Range( 0 , 3)) = 1
		_scale("scale", Range( 0 , 1)) = 0.1
		_shift("shift", Range( 0 , 1)) = 1
		[Toggle(_CUSTOM1_X_CONTROL_SHIFT_ON)] _custom1_x_control_shift("custom1_x_control_shift", Float) = 0
		[NoScaleOffset]_mask2("mask2", 2D) = "white" {}
		_noise_mask_uv("noise_mask_uv", Vector) = (1,1,0,0)
		_X_speed("X_speed", Range( -1 , 1)) = 1
		_Y_speed("Y_speed", Range( -1 , 1)) = 0
		_speed("speed", Range( 0 , 4)) =1
		[Toggle(_CUSTOM1_ZW_MOVE_UV_ON)] _custom1_zw_move_uv("custom1_zw_move_uv", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

	}
	
	SubShader
	{
		
		
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "PreviewType" = "Plane" }
		LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend SrcAlpha OneMinusSrcAlpha
		AlphaToMask Off
		// Cull Off
		ColorMask RGBA
		// ZWrite On
		// ZTest LEqual
		Offset 0 , 0
		
		ZWrite [_ZWrite]
		ZTest [_ZTest]
		Cull [_Cull]
		


		
		GrabPass{ }

		Pass
		{
			Name "Unlit"
			Tags { "LightMode"="ForwardBase" }
			CGPROGRAM

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
			#include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"
			#pragma shader_feature_local _CUSTOM1_X_CONTROL_SHIFT_ON
			#pragma shader_feature_local _CUSTOM1_ZW_MOVE_UV_ON


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
					float3 worldPos : TEXCOORD0;
				#endif
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			ASE_DECLARE_SCREENSPACE_TEXTURE( _GrabTexture )
			uniform float _shift;
			uniform sampler2D _mask2;
			SamplerState sampler_mask2;
			uniform float _speed;
			uniform float _X_speed;
			uniform float _Y_speed;
			uniform float4 _noise_mask_uv;
			uniform float _scale;
			uniform sampler2D _mask;
			SamplerState sampler_mask;
			uniform float4 _mask_ST;
			uniform float _Base_alpha;
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
			

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				float4 ase_clipPos = UnityObjectToClipPos(v.vertex);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord1 = screenPos;
				
				o.ase_texcoord2 = v.ase_texcoord;
				o.ase_texcoord3 = v.ase_texcoord1;
				o.ase_color = v.color;
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
			
			fixed4 frag (v2f i ) : SV_Target
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
				float2 temp_output_12_0 = (ase_grabScreenPosNorm).xy;
				float4 texCoord36 = i.ase_texcoord2;
				texCoord36.xy = i.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				#ifdef _CUSTOM1_X_CONTROL_SHIFT_ON
					float staticSwitch40 = texCoord36.z;
				#else
					float staticSwitch40 = _shift;
				#endif
				float mulTime54 = _Time.y * _speed;
				float2 appendResult47 = (float2(_X_speed , _Y_speed));
				float2 normalizeResult50 = normalize( appendResult47 );
				float2 appendResult52 = (float2(_noise_mask_uv.x , _noise_mask_uv.y));
				float2 appendResult53 = (float2(_noise_mask_uv.z , _noise_mask_uv.w));
				float2 texCoord33 = i.ase_texcoord2.xy * appendResult52 + appendResult53;
				float2 panner46 = ( mulTime54 * normalizeResult50 + texCoord33);
				float4 texCoord41 = i.ase_texcoord3;
				texCoord41.xy = i.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float4 appendResult42 = (float4(texCoord41.x , texCoord41.y , 0.0 , 0.0));
				#ifdef _CUSTOM1_ZW_MOVE_UV_ON
					float4 staticSwitch43 = ( float4( panner46, 0.0 , 0.0 ) + appendResult42 );
				#else
					float4 staticSwitch43 = float4( panner46, 0.0 , 0.0 );
				#endif
				float temp_output_21_0 = ( ( staticSwitch40 * tex2D( _mask2, staticSwitch43.xy ).r ) * _scale );
				float2 appendResult19 = (float2(temp_output_21_0 , 0.0));
				float4 screenColor1 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture,( temp_output_12_0 + appendResult19 ));
				float4 screenColor27 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture,temp_output_12_0);
				float2 appendResult25 = (float2(( temp_output_21_0 * -1.0 ) , 0.0));
				float4 screenColor28 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture,( temp_output_12_0 + appendResult25 ));
				float3 appendResult17 = (float3(screenColor1.r , screenColor27.g , screenColor28.b));
				float2 uv_mask = i.ase_texcoord2.xy * _mask_ST.xy + _mask_ST.zw;
				float4 appendResult6 = (float4((appendResult17).xyz , saturate( ( ( tex2D( _mask, uv_mask ).r * _Base_alpha ) * i.ase_color.a ) )));
				
				
				finalColor = appendResult6;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ColorShiftGui"
	
	
}
