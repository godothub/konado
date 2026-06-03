using Godot;
using Godot.Collections;
using Konado.Runtime.API;
using Konado.Wrapper;
using static Konado.Runtime.API.KonadoAPI;

/// <summary>
/// 这个是DialogueManagerAPI的使用示例
/// </summary>
public partial class DialogueManagerAPISample : Node
{
	public override void _Ready()
	{
		var interpreter = new KonadoScriptsInterpreter(new Dictionary<string, Variant>());
		var shot = interpreter.ProcessScriptsToData("res://sample/demo/demo_01.ks");
		GD.Print(shot.Dialogues.Count);
		
		if (DialogueManagerApi.IsReady)
		{
			GD.Print("Ready");
			
			_StartDialogue();
		}
	}
	
	private void _StartDialogue()
	{
		DialogueManagerApi.ShotStart += () =>
		{
			GD.Print("Shot Start");
		};

		DialogueManagerApi.ShotEnd += () =>
		{
			GD.Print("Shot End");
		};
		DialogueManagerApi.DialogueLineStart += (string nodeId) =>
		{
			GD.Print(nodeId);
		};
		DialogueManagerApi.DialogueLineEnd += (string nodeId) =>
		{
			GD.Print(nodeId);
		};
		
		if (API.IsApiReady)
		{
			GD.Print("API Ready");

			DialogueManagerApi.InitDialogue();
			DialogueManagerApi.StartDialogue();
			//DialogueManagerAPI.Instance.LoadDialogueShot("res://sample/sample_lists/storys/test.ks");
		}
	}

}
