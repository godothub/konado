#pragma warning disable CS0109
using Godot;

namespace Konado.Wrapper;

/// <summary>
/// Compatibility data holder for older Konado.NET callers.
/// Konado 2.4 stores actor display fields directly on <see cref="Dialogue"/>.
/// </summary>
public partial class DialogueActor : Resource
{
    public new string CharacterName { get; set; } = string.Empty;
    public new string CharacterState { get; set; } = string.Empty;
    public new Vector2 ActorPosition { get; set; } = Vector2.Zero;
}
