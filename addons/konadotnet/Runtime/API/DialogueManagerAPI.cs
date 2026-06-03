using Godot;

namespace Konado.Runtime.API;

/// <summary>
/// Konado DialogueManager C# API，用于与 Konado DialogueManager 节点进行交互
/// </summary>
public sealed partial class DialogueManagerAPI : Node
{
    private const string DialogueManagerScriptPath = "res://addons/konado/scripts/dialogue/knd_dialogue_manager.gd";

    private Node _source;

    public bool IsReady { get; private set; }
    public Node Source => _source;
    
    public override void _Ready()
    {
        BindDialogueManager();
    }

    public bool BindDialogueManager(Node source = null)
    {
        _source = source ?? FindDialogueManager(GetTree().Root);
        IsReady = _source != null;

        if (!IsReady)
        {
            GD.PrintErr("未找到 KND_DialogueManager 节点。请确保场景中已实例化 Konado 对话管理器。");
            return false;
        }

        GD.Print($"Konado.NET 已绑定对话管理器：{_source.GetPath()}");
        return true;
    }

    private static Node FindDialogueManager(Node currentNode)
    {
        if (currentNode == null)
            return null;

        if (IsDialogueManager(currentNode))
            return currentNode;

        foreach (Node child in currentNode.GetChildren())
        {
            var foundNode = FindDialogueManager(child);
            if (foundNode != null)
                return foundNode;
        }

        return null;
    }

    private static bool IsDialogueManager(Node node)
    {
        if (node == null)
            return false;

        if (node.Name == "DialogManager" || node.Name == "DialogueManager" || node.Name == "KonadoDialogueManager")
            return true;

        if (!ResourceLoader.Exists(DialogueManagerScriptPath))
            return false;

        var sourceScript = ResourceLoader.Load<GDScript>(DialogueManagerScriptPath);
        return node.GetScript().As<GDScript>() == sourceScript;
    }

    private bool EnsureReady()
    {
        if (IsReady || BindDialogueManager())
            return true;

        GD.PrintErr("Konado.NET DialogueManagerAPI 尚未就绪。");
        return false;
    }
    
    public static class GDScriptSignalName
    {
        public static readonly StringName ShotStart = "shot_start";
        public static readonly StringName ShotEnd = "shot_end";
        public static readonly StringName DialogueLineStart = "dialogue_line_start";
        public static readonly StringName DialogueLineEnd = "dialogue_line_end";
        public static readonly StringName CustomSignal = "custom_signal";
    }

    public delegate void ShotStartSignalHandler();
    private ShotStartSignalHandler _shotStartSignal;
    private Callable _shotStartSignalCallable;
    public event ShotStartSignalHandler ShotStart
    {
        add
        {
            if (!EnsureReady()) return;
            if (_shotStartSignal is null)
            {
                _shotStartSignalCallable = Callable.From(() => _shotStartSignal?.Invoke());
                _source.Connect(GDScriptSignalName.ShotStart, _shotStartSignalCallable);
            }
            _shotStartSignal += value;
        }
        remove
        {
            if (!EnsureReady()) return;
            _shotStartSignal -= value;
            if (_shotStartSignal is not null) return;
            _source.Disconnect(GDScriptSignalName.ShotStart, _shotStartSignalCallable);
            _shotStartSignalCallable = default;
        }
    }

    public delegate void ShotEndSignalHandler();
    private ShotEndSignalHandler _shotEndSignal;
    private Callable _shotEndSignalCallable;
    public event ShotEndSignalHandler ShotEnd
    {
        add
        {
            if (!EnsureReady()) return;
            if (_shotEndSignal is null)
            {
                _shotEndSignalCallable = Callable.From(() => _shotEndSignal?.Invoke());
                _source.Connect(GDScriptSignalName.ShotEnd, _shotEndSignalCallable);
            }
            _shotEndSignal += value;
        }
        remove
        {
            if (!EnsureReady()) return;
            _shotEndSignal -= value;
            if (_shotEndSignal is not null) return;
            _source.Disconnect(GDScriptSignalName.ShotEnd, _shotEndSignalCallable);
            _shotEndSignalCallable = default;            
        }
        
    }

    public delegate void DialogueLineStartSignalHandler(string nodeId);
    private DialogueLineStartSignalHandler _dialogueLineStartSignal;
    private Callable _dialogueLineStartSignalCallable;
    public event DialogueLineStartSignalHandler DialogueLineStart
    {
        add
        {
            if (!EnsureReady()) return;
            if (_dialogueLineStartSignal is null)
            {
                _dialogueLineStartSignalCallable = Callable.From((string nodeId) => _dialogueLineStartSignal?.Invoke(nodeId));
                _source.Connect(GDScriptSignalName.DialogueLineStart, _dialogueLineStartSignalCallable);
            }
            _dialogueLineStartSignal += value;
        }
        remove
        {
            if (!EnsureReady()) return;
            _dialogueLineStartSignal -= value;
            if (_dialogueLineStartSignal is not null) return;        
            _source.Disconnect(GDScriptSignalName.DialogueLineStart, _dialogueLineStartSignalCallable);
            _dialogueLineStartSignalCallable = default;
        }
    }

    public delegate void DialogueLineEndSignalHandler(string nodeId);
    private DialogueLineEndSignalHandler _dialogueLineEndSignal;
    private Callable _dialogueLineEndSignalCallable;
    public event DialogueLineEndSignalHandler DialogueLineEnd
    {
        add
        {
            if (!EnsureReady()) return;
            if (_dialogueLineEndSignal is null)
            {
                _dialogueLineEndSignalCallable = Callable.From((string nodeId) => _dialogueLineEndSignal?.Invoke(nodeId));
                _source.Connect(GDScriptSignalName.DialogueLineEnd, _dialogueLineEndSignalCallable);
            }
            _dialogueLineEndSignal += value;
        }
        remove
        {
            if (!EnsureReady()) return;
            _dialogueLineEndSignal -= value;
            if (_dialogueLineEndSignal is not null) return;
            _source.Disconnect(GDScriptSignalName.DialogueLineEnd, _dialogueLineEndSignalCallable);
            _dialogueLineEndSignalCallable = default;            
        }
    }

    public delegate void CustomSignalHandler(string content);
    private CustomSignalHandler _customSignal;
    private Callable _customSignalCallable;
    public event CustomSignalHandler CustomSignal
    {
        add
        {
            if (!EnsureReady()) return;
            if (_customSignal is null)
            {
                _customSignalCallable = Callable.From((string content) => _customSignal?.Invoke(content));
                _source.Connect(GDScriptSignalName.CustomSignal, _customSignalCallable);
            }
            _customSignal += value;
        }
        remove
        {
            if (!EnsureReady()) return;
            _customSignal -= value;
            if (_customSignal is not null) return;
            _source.Disconnect(GDScriptSignalName.CustomSignal, _customSignalCallable);
            _customSignalCallable = default;
        }
    }

    public static class GDScriptMethodName
    {
        public static readonly StringName InitDialogue = "init_dialogue";
        public static readonly StringName SetShot = "set_shot";
        public static readonly StringName StartDialogue = "start_dialogue";
        public static readonly StringName StopDialogue = "stop_dialogue";
        public static readonly StringName StartAutoplay = "start_autoplay";
        public static readonly StringName SaveGame = "save_game";
        public static readonly StringName LoadGame = "load_game";
        public static readonly StringName DeleteSave = "delete_save";
        public static readonly StringName GetSaveInfo = "get_save_info";
        public static readonly StringName GetAllSaveInfo = "get_all_save_info";
    }

    /// <summary>
    /// 初始化对话，调用 Konado DialogueManager 节点的 init_dialogue 方法
    /// </summary>
    public void InitDialogue()
    {
        if (EnsureReady())
            _source.Call(GDScriptMethodName.InitDialogue);
    }

    public void SetShot(Resource shot)
    {
        if (EnsureReady())
            _source.Call(GDScriptMethodName.SetShot, shot);
    }
        
    /// <summary>
    /// 开始对话，调用 Konado DialogueManager 节点的 start_dialogue 方法
    /// </summary>
    public void StartDialogue()
    {
        if (EnsureReady())
            _source.Call(GDScriptMethodName.StartDialogue);
    }

    /// <summary>
    /// 停止对话，调用 Konado DialogueManager 节点的 stop_dialogue 方法
    /// </summary>
    public void StopDialogue()
    {
        if (EnsureReady())
            _source.Call(GDScriptMethodName.StopDialogue);
    }

    public void StartAutoplay(bool value)
    {
        if (EnsureReady())
            _source.Call(GDScriptMethodName.StartAutoplay, value);
    }

    public bool SaveGame(int saveId)
        => EnsureReady() && _source.Call(GDScriptMethodName.SaveGame, saveId).As<bool>();

    public bool LoadGame(int saveId)
        => EnsureReady() && _source.Call(GDScriptMethodName.LoadGame, saveId).As<bool>();

    public bool DeleteSave(int saveId)
        => EnsureReady() && _source.Call(GDScriptMethodName.DeleteSave, saveId).As<bool>();

    public Godot.Collections.Dictionary GetSaveInfo(int saveId)
        => EnsureReady()
            ? _source.Call(GDScriptMethodName.GetSaveInfo, saveId).AsGodotDictionary()
            : new Godot.Collections.Dictionary();

    public Godot.Collections.Array<Godot.Collections.Dictionary> GetAllSaveInfo()
        => EnsureReady()
            ? _source.Call(GDScriptMethodName.GetAllSaveInfo).AsGodotArray<Godot.Collections.Dictionary>()
            : new Godot.Collections.Array<Godot.Collections.Dictionary>();
}
