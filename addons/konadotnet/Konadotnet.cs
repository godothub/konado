#if TOOLS
using Godot;
using System.Collections.Generic;

/// <summary>
/// Konadotnet插件入口类，继承自EditorPlugin
/// </summary>
[Tool]
public partial class Konadotnet : EditorPlugin
{
	/// <summary>
	/// 插件自动加载的类，键为类名，值为类路径
	/// </summary>
	private readonly Dictionary<string, string> _autoloads = new Dictionary<string, string>()
	{
		{"KonadoAPI", "res://addons/konadotnet/Runtime/API/KonadoAPI.cs"}
		// {"DialogueManagerAPI", "res://addons/konadotnet/api/DialogueManagerAPI.cs"}
	};

	public override void _EnterTree()
	{
		GD.Print("Konadotnet插件加载中...");
		// 检查插件路径
		if (!FileAccess.FileExists("res://addons/konado/plugin.cfg"))
		{
			GD.PrintErr("Konado插件未安装，无法加载Konadotnet插件");
			return;
		}

		var pluginConfig = ProjectSettings.GetSetting("editor_plugins/enabled")
			.As<Godot.Collections.Array<string>>();

		if (pluginConfig != null)
		{
			if (pluginConfig.Contains("res://addons/konado/plugin.cfg"))
			{
				GD.Print("检查Konado插件已启用");
			}
			else
			{
				GD.PrintErr("Konado插件未启用，请先在项目设置启用Konado插件");
				return;
			}
		}
		else
		{
			GD.PrintErr("无法获取项目插件配置信息，请检查project.godot文件");
			return;
		}

		foreach (var autoload in _autoloads)
		{
			if (!ProjectSettings.HasSetting($"autoload/{autoload.Key}"))
			{
				AddAutoloadSingleton(autoload.Key, autoload.Value);
			}
		}

		GD.Print("Konadotnet插件加载成功");


	}

	public override void _ExitTree()
	{
		foreach (var autoload in _autoloads)
		{
			if (ProjectSettings.HasSetting($"autoload/{autoload.Key}"))
			{
				RemoveAutoloadSingleton(autoload.Key);
			}
		}
	}
}

#endif
