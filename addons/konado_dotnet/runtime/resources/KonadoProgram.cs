using Godot;

namespace Konado.Runtime.Resources;

/// <summary>Read-only wrapper for the compact Konado 2.9 executable Program.</summary>
public sealed partial class KonadoProgram : Resource
{
	private static GDScript? _sourceScript;
	private const string SourceScriptPath =
		"res://addons/konado/runtime/dialogue/konado_program.gd";

	public KonadoProgram(GodotObject source)
	{
		if (source is not Resource || !IsInstanceValid(source)
			|| !KonadoData.InheritsSourceScript(source, LoadSourceScript()))
		{
			throw new System.InvalidOperationException(
				"Source object is not a KonadoProgram resource!");
		}
		SourceResource = (Resource)source;
	}

	public Resource SourceResource { get; }
	public int InstructionCount =>
		SourceResource.Call(ScriptMethodName.InstructionCount).AsInt32();
	public bool IsValid => SourceResource.Call(ScriptMethodName.IsValid).AsBool();
	public string Fingerprint => SourceResource.Call(ScriptMethodName.Fingerprint).AsString();
	public int EntryPc => SourceResource.Get(ScriptPropertyName.EntryPc).AsInt32();

	public int PcForKey(string stableKey) =>
		SourceResource.Call(ScriptMethodName.PcForKey, stableKey).AsInt32();

	public KonadoInstruction? InstructionAt(int pc)
	{
		var source = SourceResource.Call(ScriptMethodName.InstructionAt, pc).AsGodotObject();
		return source == null ? null : new KonadoInstruction(source);
	}

	private static GDScript LoadSourceScript()
	{
		if (!ResourceLoader.Exists(SourceScriptPath))
			throw new System.InvalidOperationException("KonadoProgram source script not found!");
		return _sourceScript ??= ResourceLoader.Load<GDScript>(SourceScriptPath);
	}

	private static class ScriptPropertyName
	{
		public static readonly StringName EntryPc = "entry_pc";
	}

	private static class ScriptMethodName
	{
		public static readonly StringName InstructionCount = "instruction_count";
		public static readonly StringName IsValid = "is_valid";
		public static readonly StringName Fingerprint = "fingerprint";
		public static readonly StringName PcForKey = "pc_for_key";
		public static readonly StringName InstructionAt = "instruction_at";
	}
}
