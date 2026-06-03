#pragma warning disable CS0109
using Godot;

namespace Konado.Wrapper;

public sealed partial class KonadoScriptsInterpreter : RefCounted
{    
    private static GDScript _sourceScript;
    private const string SourceScriptPath = "res://addons/konado/ks/ks_interpreter.gd";
    private GodotObject _source;

    /// <summary>
    /// Create a new instance of the <see cref="KonadoScriptsInterpreter"/> class.
    /// </summary>
    /// <param name="flags"></param>
    /// <returns></returns>
    /// <exception cref="System.InvalidOperationException"></exception>
    public KonadoScriptsInterpreter(Godot.Collections.Dictionary<string, Variant> flags = null)
    {
        if (!ResourceLoader.Exists(SourceScriptPath))
        {
            throw new System.InvalidOperationException("Source script not found!");
        }

        _sourceScript ??= ResourceLoader.Load<GDScript>(SourceScriptPath);
        _source = _sourceScript.New().AsGodotObject();
    }

    public KonadoScriptsInterpreter(GodotObject source)
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

    public new static class GDScriptMethodName
    {
        public new static readonly StringName ProcessScriptsToData = "process_scripts_to_data";
        public new static readonly StringName ParseSingleLine = "parse_single_line";
    }

    public KndShot ProcessScriptsToData(string path)
        => new(_source.Call(GDScriptMethodName.ProcessScriptsToData, path).As<Resource>());

    public Dialogue ParseSingleLine(string line, long lineNumber, string path)
        => new(_source.Call(GDScriptMethodName.ParseSingleLine, line, lineNumber, path).As<Resource>());

}
