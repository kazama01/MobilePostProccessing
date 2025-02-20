using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CustomRenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class CustomRenderSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        public LayerMask layerMask = ~0; // Default to everything
        public int stencilRef = 1;
        public CompareFunction stencilCompare = CompareFunction.Always;
        public StencilOp stencilPassOp = StencilOp.Replace;
        public StencilOp stencilFailOp = StencilOp.Keep;
        public StencilOp stencilZFailOp = StencilOp.Keep;
    }

    public CustomRenderSettings settings = new CustomRenderSettings();
    private CustomRenderPass customPass;

    public override void Create()
    {
        customPass = new CustomRenderPass(settings);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(customPass);
    }

    private class CustomRenderPass : ScriptableRenderPass
    {
        private FilteringSettings filteringSettings;
        private ShaderTagId shaderTagId = new ShaderTagId("UniversalForward");
        private Material overrideMaterial;
        private int stencilRef;
        private CompareFunction stencilCompare;
        private StencilOp stencilPassOp;
        private StencilOp stencilFailOp;
        private StencilOp stencilZFailOp;

        public CustomRenderPass(CustomRenderSettings settings)
        {
            renderPassEvent = settings.renderPassEvent;
            filteringSettings = new FilteringSettings(RenderQueueRange.all, settings.layerMask);
            stencilRef = settings.stencilRef;
            stencilCompare = settings.stencilCompare;
            stencilPassOp = settings.stencilPassOp;
            stencilFailOp = settings.stencilFailOp;
            stencilZFailOp = settings.stencilZFailOp;

            Shader stencilShader = Shader.Find("Hidden/StencilOverride");
            if (stencilShader != null)
            {
                overrideMaterial = new Material(stencilShader);
            }
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (overrideMaterial == null) return;

            CommandBuffer cmd = CommandBufferPool.Get("CustomRenderPass");
            
            // Set stencil properties
            overrideMaterial.SetInt("_StencilRef", stencilRef);
            overrideMaterial.SetInt("_StencilComp", (int)stencilCompare);
            overrideMaterial.SetInt("_StencilPassOp", (int)stencilPassOp);
            overrideMaterial.SetInt("_StencilFailOp", (int)stencilFailOp);
            overrideMaterial.SetInt("_StencilZFailOp", (int)stencilZFailOp);

            DrawingSettings drawingSettings = CreateDrawingSettings(shaderTagId, ref renderingData, SortingCriteria.CommonTransparent);
            drawingSettings.overrideMaterial = overrideMaterial;

            context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSettings);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}
