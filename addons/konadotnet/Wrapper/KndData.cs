#pragma warning disable CS0109
using Godot;

namespace Konado.Wrapper;

public partial class KndData : Resource
{
    private static GDScript _sourceScript;
    private const string SourceScriptPath = "res://addons/konado/scripts/knd_data/knd_data.gd";
    protected GodotObject SourceObject;

    public KndData(GodotObject source)
    {
        if (source is null || !IsInstanceValid(source))
        {
            throw new System.InvalidOperationException("Source object is not valid!");
        }

        LoadSourceScript();
        SourceObject = source;
    }

    public KndData()
    {
        LoadSourceScript();
        SourceObject = _sourceScript.New().AsGodotObject();
    }

    public Resource SourceResource => SourceObject as Resource;

    private static void LoadSourceScript()
    {
        if (!ResourceLoader.Exists(SourceScriptPath))
        {
            throw new System.InvalidOperationException("KND_Data source script not found!");
        }

        _sourceScript ??= ResourceLoader.Load<GDScript>(SourceScriptPath);
    }
}
