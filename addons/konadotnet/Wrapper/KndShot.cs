#pragma warning disable CS0109
using System.Linq;
using Godot;

namespace Konado.Wrapper;

public partial class KndShot : KndData
{
    private static GDScript _sourceScript;
    private const string SourceScriptPath = "res://addons/konado/scripts/dialogue/knd_shot.gd";

    public KndShot(GodotObject source) : base(source)
    {
        LoadSourceScript();
        if (source.GetScript().As<GDScript>() != _sourceScript)
        {
            throw new System.InvalidOperationException("Source object is not a KND_Shot resource!");
        }

        SourceObject = source;
    }

    public KndShot()
    {
        LoadSourceScript();
        SourceObject = _sourceScript.New().AsGodotObject();
    }

    private static void LoadSourceScript()
    {
        if (!ResourceLoader.Exists(SourceScriptPath))
        {
            throw new System.InvalidOperationException("KND_Shot source script not found!");
        }

        _sourceScript ??= ResourceLoader.Load<GDScript>(SourceScriptPath);
    }

    public new static class GDScriptPropertyName
    {
        public new static readonly StringName KsPath = "ks_path";
        public new static readonly StringName ShotId = "shot_id";
        public new static readonly StringName StartNodeId = "start_node_id";
        public new static readonly StringName Dialogues = "dialogues";
    }

    public string KsPath
    {
        get => SourceObject.Get(GDScriptPropertyName.KsPath).As<string>();
        set => SourceObject.Set(GDScriptPropertyName.KsPath, value);
    }

    public new string ShotId
    {
        get => SourceObject.Get(GDScriptPropertyName.ShotId).As<string>();
        set => SourceObject.Set(GDScriptPropertyName.ShotId, value);
    }

    public string StartNodeId
    {
        get => SourceObject.Get(GDScriptPropertyName.StartNodeId).As<string>();
        set => SourceObject.Set(GDScriptPropertyName.StartNodeId, value);
    }

    public Godot.Collections.Array<Dialogue> Dialogues
    {
        get => new(SourceObject.Get(GDScriptPropertyName.Dialogues).As<Godot.Collections.Array<Resource>>().Select(r => new Dialogue(r)));
        set
        {
            var sourceDialogues = new Godot.Collections.Array<Resource>();
            foreach (var dialogue in value)
            {
                sourceDialogues.Add(dialogue.SourceResource);
            }
            SourceObject.Set(GDScriptPropertyName.Dialogues, sourceDialogues);
        }
    }

    public Dialogue FindNode(string nodeId)
    {
        var result = SourceObject.Call("find_node", nodeId).As<Resource>();
        return result == null ? null : new Dialogue(result);
    }

    public Dialogue GetStartNode()
    {
        var result = SourceObject.Call("get_start_node").As<Resource>();
        return result == null ? null : new Dialogue(result);
    }
}
