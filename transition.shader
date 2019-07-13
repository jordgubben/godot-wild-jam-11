shader_type canvas_item;
render_mode unshaded;

uniform float darkness : hint_range(0.0, 1.0);

void fragment()
{
  COLOR = vec4(COLOR.rgb, darkness);
}