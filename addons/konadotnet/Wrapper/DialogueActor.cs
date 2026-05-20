#pragma warning disable CS0109
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Godot;

namespace Konado.Wrapper;

public partial class DialogueActor : Resource
{
    private static GDScript _sourceScript;
    private const string SourceScriptPath = "res://addons/konado/scripts/dialogue/dialogue_actor.gd";
    private GodotObject _source;

    public DialogueActor(GodotObject source)
    {
        if (source is null || !IsInstanceValid(source))
        {
            throw new System.InvalidOperationException("Source object is not valid!");
        }

        if (!ResourceLoader.Exists(SourceScriptPath))
        {
            throw new System.InvalidOperationException("Source script not found!");
        }

        _sourceScript ??= ResourceLoader.Load<GDScript>(SourceScriptPath);
        if (source.GetScript().As<GDScript>() != _sourceScript)
        {
            throw new System.InvalidOperationException("Source Object is not a valid source!");
        }

        _source = source;
    }

    /// <summary>
    /// Create a new instance of the <see cref="DialogueActor"/> class.
    /// </summary>
    /// <returns></returns>
    /// <exception cref="System.InvalidOperationException"></exception>
    public DialogueActor()
    {
        if (!ResourceLoader.Exists(SourceScriptPath))
        {
            throw new System.InvalidOperationException("Source script not found!");
        }

        _sourceScript ??= ResourceLoader.Load<GDScript>(SourceScriptPath);
        _source = _sourceScript.New().AsGodotObject();
    }

    public new static class GDScriptPropertyName
    {
        public new static readonly StringName CharacterName = "character_name";
        public new static readonly StringName CharacterState = "character_state";
        public new static readonly StringName ActorPosition = "actor_position";
    }

    public new string CharacterName
    {
        get => _source.Get(GDScriptPropertyName.CharacterName).As<string>();
        set => _source.Set(GDScriptPropertyName.CharacterName, value);
    }

    public new string CharacterState
    {
        get => _source.Get(GDScriptPropertyName.CharacterState).As<string>();
        set => _source.Set(GDScriptPropertyName.CharacterState, value);
    }

    public new Vector2 ActorPosition
    {
        get => _source.Get(GDScriptPropertyName.ActorPosition).As<Vector2>();
        set => _source.Set(GDScriptPropertyName.ActorPosition, value);
    }

}