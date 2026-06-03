#pragma warning disable CS0109
using System.Linq;
using Godot;
using Konado.Runtime.API;

namespace Konado.Wrapper;

public partial class Dialogue : Resource
{
    private static GDScript _sourceScript;
    private const string SourceScriptPath = "res://addons/konado/scripts/dialogue/knd_dialogue.gd";
    private GodotObject _source;

    public Dialogue(GodotObject source)
    {
        if (source is null || !IsInstanceValid(source))
        {
            throw new System.InvalidOperationException("Source object is not valid!");
        }

        LoadSourceScript();
        if (source.GetScript().As<GDScript>() != _sourceScript)
        {
            throw new System.InvalidOperationException("Source object is not a KND_Dialogue resource!");
        }

        _source = source;
    }

    public Dialogue()
    {
        LoadSourceScript();
        _source = _sourceScript.New().AsGodotObject();
    }

    public Resource SourceResource => _source as Resource;

    private static void LoadSourceScript()
    {
        if (!ResourceLoader.Exists(SourceScriptPath))
        {
            throw new System.InvalidOperationException("KND_Dialogue source script not found!");
        }

        _sourceScript ??= ResourceLoader.Load<GDScript>(SourceScriptPath);
    }

    public enum Type
    {
        OrdinaryDialog,
        DisplayActor,
        ActorChangeState,
        MoveActor,
        SwitchBackground,
        ExitActor,
        PlayBgm,
        StopBgm,
        PlaySoundEffect,
        ShowChoice,
        IfElseBranch,
        Branch,
        Jump,
        JumpBranch,
        Signal,
        AchievementUnlock,
        AchievementProgress,
        AchievementFlag,
        SetVariable,
        TheEnd
    }

    public new static class GDScriptPropertyName
    {
        public new static readonly StringName SourceFileLine = "source_file_line";
        public new static readonly StringName DialogType = "dialog_type";
        public new static readonly StringName NodeId = "node_id";
        public new static readonly StringName NextId = "next_id";
        public new static readonly StringName IfNextId = "if_next_id";
        public new static readonly StringName ElseNextId = "else_next_id";
        public new static readonly StringName VarName = "varname";
        public new static readonly StringName ConditionOperator = "condition_operator";
        public new static readonly StringName TargetValue = "target_value";
        public new static readonly StringName CharacterId = "character_id";
        public new static readonly StringName DialogueContent = "dialog_content";
        public new static readonly StringName CharacterName = "character_name";
        public new static readonly StringName CharacterState = "character_state";
        public new static readonly StringName ActorPosition = "actor_position";
        public new static readonly StringName ExitActor = "exit_actor";
        public new static readonly StringName ChangeStateActor = "change_state_actor";
        public new static readonly StringName ChangeState = "change_state";
        public new static readonly StringName TargetMoveChara = "target_move_chara";
        public new static readonly StringName TargetMovePos = "target_move_pos";
        public new static readonly StringName Choices = "choices";
        public new static readonly StringName BgmName = "bgm_name";
        public new static readonly StringName VoiceId = "voice_id";
        public new static readonly StringName SoundeffectName = "soundeffect_name";
        public new static readonly StringName BackgroundImageName = "background_image_name";
        public new static readonly StringName BackgroundToggleEffects = "background_toggle_effects";
        public new static readonly StringName CustomSignalName = "custom_signal_name";
        public new static readonly StringName JumpShotPath = "jump_shot_path";
        public new static readonly StringName JumpBranchTarget = "jump_branch_target";
        public new static readonly StringName AchievementId = "achievement_id";
        public new static readonly StringName AchievementValue = "achievement_value";
        public new static readonly StringName AchievementFlagName = "achievement_flag_name";
        public new static readonly StringName AchievementFlagValue = "achievement_flag_value";
        public new static readonly StringName VariableName = "variable_name";
        public new static readonly StringName VariableOperation = "variable_operation";
        public new static readonly StringName VariableOperand = "variable_operand";
        public new static readonly StringName IsPersistent = "is_persistent";
    }

    public int SourceFileLine
    {
        get => _source.Get(GDScriptPropertyName.SourceFileLine).As<int>();
        set => _source.Set(GDScriptPropertyName.SourceFileLine, value);
    }

    public new Type DialogueType
    {
        get => (Type)_source.Get(GDScriptPropertyName.DialogType).As<int>();
        set => _source.Set(GDScriptPropertyName.DialogType, (int)value);
    }

    public string NodeId
    {
        get => _source.Get(GDScriptPropertyName.NodeId).As<string>();
        set => _source.Set(GDScriptPropertyName.NodeId, value);
    }

    public string NextId
    {
        get => _source.Get(GDScriptPropertyName.NextId).As<string>();
        set => _source.Set(GDScriptPropertyName.NextId, value);
    }

    public string IfNextId
    {
        get => _source.Get(GDScriptPropertyName.IfNextId).As<string>();
        set => _source.Set(GDScriptPropertyName.IfNextId, value);
    }

    public string ElseNextId
    {
        get => _source.Get(GDScriptPropertyName.ElseNextId).As<string>();
        set => _source.Set(GDScriptPropertyName.ElseNextId, value);
    }

    public string VarName
    {
        get => _source.Get(GDScriptPropertyName.VarName).As<string>();
        set => _source.Set(GDScriptPropertyName.VarName, value);
    }

    public int ConditionOperator
    {
        get => _source.Get(GDScriptPropertyName.ConditionOperator).As<int>();
        set => _source.Set(GDScriptPropertyName.ConditionOperator, value);
    }

    public int TargetValue
    {
        get => _source.Get(GDScriptPropertyName.TargetValue).As<int>();
        set => _source.Set(GDScriptPropertyName.TargetValue, value);
    }

    public new string CharacterId
    {
        get => _source.Get(GDScriptPropertyName.CharacterId).As<string>();
        set => _source.Set(GDScriptPropertyName.CharacterId, value);
    }

    public new string DialogueContent
    {
        get => _source.Get(GDScriptPropertyName.DialogueContent).As<string>();
        set => _source.Set(GDScriptPropertyName.DialogueContent, value);
    }

    public string CharacterName
    {
        get => _source.Get(GDScriptPropertyName.CharacterName).As<string>();
        set => _source.Set(GDScriptPropertyName.CharacterName, value);
    }

    public string CharacterState
    {
        get => _source.Get(GDScriptPropertyName.CharacterState).As<string>();
        set => _source.Set(GDScriptPropertyName.CharacterState, value);
    }

    public Vector2 ActorPosition
    {
        get => _source.Get(GDScriptPropertyName.ActorPosition).As<Vector2>();
        set => _source.Set(GDScriptPropertyName.ActorPosition, value);
    }

    public new string ExitActor
    {
        get => _source.Get(GDScriptPropertyName.ExitActor).As<string>();
        set => _source.Set(GDScriptPropertyName.ExitActor, value);
    }

    public string ChangeStateActor
    {
        get => _source.Get(GDScriptPropertyName.ChangeStateActor).As<string>();
        set => _source.Set(GDScriptPropertyName.ChangeStateActor, value);
    }

    public string ChangeState
    {
        get => _source.Get(GDScriptPropertyName.ChangeState).As<string>();
        set => _source.Set(GDScriptPropertyName.ChangeState, value);
    }

    public string TargetMoveChara
    {
        get => _source.Get(GDScriptPropertyName.TargetMoveChara).As<string>();
        set => _source.Set(GDScriptPropertyName.TargetMoveChara, value);
    }

    public Vector2 TargetMovePos
    {
        get => _source.Get(GDScriptPropertyName.TargetMovePos).As<Vector2>();
        set => _source.Set(GDScriptPropertyName.TargetMovePos, value);
    }

    public Godot.Collections.Array<DialogueChoice> Choices
    {
        get => new(_source.Get(GDScriptPropertyName.Choices).As<Godot.Collections.Array<Resource>>().Select(r => new DialogueChoice(r)));
        set
        {
            var sourceChoices = new Godot.Collections.Array<Resource>();
            foreach (var choice in value)
            {
                sourceChoices.Add(choice.SourceResource);
            }
            _source.Set(GDScriptPropertyName.Choices, sourceChoices);
        }
    }

    public new string BgmName
    {
        get => _source.Get(GDScriptPropertyName.BgmName).As<string>();
        set => _source.Set(GDScriptPropertyName.BgmName, value);
    }

    public new string VoiceId
    {
        get => _source.Get(GDScriptPropertyName.VoiceId).As<string>();
        set => _source.Set(GDScriptPropertyName.VoiceId, value);
    }

    public new string SoundeffectName
    {
        get => _source.Get(GDScriptPropertyName.SoundeffectName).As<string>();
        set => _source.Set(GDScriptPropertyName.SoundeffectName, value);
    }

    public new string BackgroundImageName
    {
        get => _source.Get(GDScriptPropertyName.BackgroundImageName).As<string>();
        set => _source.Set(GDScriptPropertyName.BackgroundImageName, value);
    }

    public new ActingInterface.BackgroundTransitionEffectsType BackgroundToggleEffects
    {
        get => (ActingInterface.BackgroundTransitionEffectsType)_source.Get(GDScriptPropertyName.BackgroundToggleEffects).As<int>();
        set => _source.Set(GDScriptPropertyName.BackgroundToggleEffects, (int)value);
    }

    public string CustomSignalName
    {
        get => _source.Get(GDScriptPropertyName.CustomSignalName).As<string>();
        set => _source.Set(GDScriptPropertyName.CustomSignalName, value);
    }

    public string JumpShotPath
    {
        get => _source.Get(GDScriptPropertyName.JumpShotPath).As<string>();
        set => _source.Set(GDScriptPropertyName.JumpShotPath, value);
    }

    public string JumpBranchTarget
    {
        get => _source.Get(GDScriptPropertyName.JumpBranchTarget).As<string>();
        set => _source.Set(GDScriptPropertyName.JumpBranchTarget, value);
    }

    public string AchievementId
    {
        get => _source.Get(GDScriptPropertyName.AchievementId).As<string>();
        set => _source.Set(GDScriptPropertyName.AchievementId, value);
    }

    public int AchievementValue
    {
        get => _source.Get(GDScriptPropertyName.AchievementValue).As<int>();
        set => _source.Set(GDScriptPropertyName.AchievementValue, value);
    }

    public string AchievementFlagName
    {
        get => _source.Get(GDScriptPropertyName.AchievementFlagName).As<string>();
        set => _source.Set(GDScriptPropertyName.AchievementFlagName, value);
    }

    public bool AchievementFlagValue
    {
        get => _source.Get(GDScriptPropertyName.AchievementFlagValue).As<bool>();
        set => _source.Set(GDScriptPropertyName.AchievementFlagValue, value);
    }

    public string VariableName
    {
        get => _source.Get(GDScriptPropertyName.VariableName).As<string>();
        set => _source.Set(GDScriptPropertyName.VariableName, value);
    }

    public int VariableOperation
    {
        get => _source.Get(GDScriptPropertyName.VariableOperation).As<int>();
        set => _source.Set(GDScriptPropertyName.VariableOperation, value);
    }

    public string VariableOperand
    {
        get => _source.Get(GDScriptPropertyName.VariableOperand).As<string>();
        set => _source.Set(GDScriptPropertyName.VariableOperand, value);
    }

    public bool IsPersistent
    {
        get => _source.Get(GDScriptPropertyName.IsPersistent).As<bool>();
        set => _source.Set(GDScriptPropertyName.IsPersistent, value);
    }
}
