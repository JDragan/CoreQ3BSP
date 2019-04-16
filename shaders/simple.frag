#version 330 core

in vec2 g_TexCoord;
in vec2 g_LmapCoord;

uniform sampler2D TEX;
uniform sampler2D LMAP;

out vec4 FragColor;

void main() {
  vec4 o_texture = texture(TEX, g_TexCoord);
  vec4 o_lightmap = texture(LMAP, g_LmapCoord);

  FragColor = o_texture * o_lightmap * 3;
}
