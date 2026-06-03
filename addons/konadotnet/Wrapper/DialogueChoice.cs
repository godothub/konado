#pragma warning disable CS0109
using Godot;

namespace Konado.Wrapper;

public partial class DialogueChoice : Resource
{
    private static GDScript _sourceScript;
    private const string SourceScriptPath = "res://addons/konado/scripts/dialogue/knd_dialogue_choice.gd";
    private GodotObject _source;

    public DialogueChoice(GodotObject source)
    {
        if (source is null || !IsInstanceValid(source))
        {
            throw new System.InvalidOperationException("Source object is not valid!");
        }

        LoadSourceScript();
        if (source.GetScript().As<GDScript>() != _sourceScript)
        {
            throw new System.InvalidOperationException("Source object is not a KND_DialogueChoice resource!");
        }

        _source = source;
    }

    public DialogueChoice()
    {
        LoadSourceScript();
        _source = _sourceScript.New().AsGodotObject();
    }

    public Resource SourceResource => _source as Resource;

    private static void LoadSourceScript()
    {
        if (!ResourceLoader.Exists(SourceScriptPath))
        {
            throw new System.InvalidOperationException("KND_DialogueChoice source script not found!");
        }

        _sourceScript ??= ResourceLoader.Load<GDScript>(SourceScriptPath);
    }

    public new static class GDScriptPropertyName
    {
        public new static readonly StringName ChoiceText = "choice_text";
        public new static readonly StringName NextId = "next_id";
    }

    public new string ChoiceText
    {
        get => _source.Get(GDScriptPropertyName.ChoiceText).As<string>();
        set => _source.Set(GDScriptPropertyName.ChoiceText, value);
    }

    public string NextId
    {
        get => _source.Get(GDScriptPropertyName.NextId).As<string>();
        set => _source.Set(GDScriptPropertyName.NextId, value);
    }
}
