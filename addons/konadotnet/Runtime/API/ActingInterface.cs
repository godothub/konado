using Godot;

namespace Konado.Runtime.API;

public sealed partial class ActingInterface : Control
{
    public enum BackgroundTransitionEffectsType
    {
        NoneEffect = 0,
        EraseEffect,
        BlindsEffect,
        WaveEffect,
        AlphaFadeEffect,
        VortexSwapEffect,
        WindmillEffect,
        CyberGlitchEffect
    }
}
