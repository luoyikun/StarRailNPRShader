/*
 * StarRailNPRShader - Fan-made shaders for Unity URP attempting to replicate
 * the shading of Honkai: Star Rail.
 * https://github.com/stalomeow/StarRailNPRShader
 *
 * Copyright (C) 2023 Stalo <stalowork@163.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

using System.Collections.Generic;
using UnityEngine;

namespace HSR.NPRShader.Editor.Tools
{
    public class BodyMaterialSetter : BaseMaterialSetter
    {
        public override Dictionary<string, string> SupportedShaderMap => new()
        {
            ["miHoYo/CRP_Character/CharacterBase"] = "Honkai Star Rail/Character/Body",
            ["miHoYo/CRP_Character/CharacterTransparent"] = "Honkai Star Rail/Character/Body (Transparent)",
        };

        protected override IEnumerable<(string, MaterialInfo.TextureInfo)> ApplyTextures(Dictionary<string, MaterialInfo.TextureInfo> textures)
        {
            yield return ("_MainTex", textures["_MainTex"]);
            yield return ("_LightMap", textures["_LightMap"]);
            yield return ("_RampMapWarm", textures["_DiffuseRampMultiTex"]);
            yield return ("_RampMapCool", textures["_DiffuseCoolRampMultiTex"]);

            yield return ("_StockingsMap", textures["_StockRangeTex"]);
        }

        protected override IEnumerable<(string, float)> ApplyFloats(Dictionary<string, float> floats)
        {
            yield return ("_Cull", floats["_CullMode"]);

            // TODO Float 某些值不准，比如 _SrcBlend 和 _DstBlend
            // yield return ("_SrcBlendColor", floats["_SrcBlend"]);
            // yield return ("_DstBlendColor", floats["_DstBlend"]);

            yield return ("_AlphaTest", floats["_EnableAlphaCutoff"]);
            yield return ("_AlphaTestThreshold", floats["_AlphaCutoff"]);

            yield return ("_EmissionThreshold", floats["_EmissionThreshold"]);
            yield return ("_EmissionIntensity", floats["_EmissionIntensity"]);

            // Stockings
            yield return ("_StockingsDarkWidth", floats["_StockDarkWidth"]);
            yield return ("_StockingsPower", floats["_Stockpower"]);
            yield return ("_StockingsLightedWidth", floats["_Stockpower1"]);
            yield return ("_StockingsLightedIntensity", floats["_StockSP"]);
            yield return ("_StockingsRoughness", floats["_StockRoughness"]);
        }

        protected override IEnumerable<(string, Color)> ApplyColors(Dictionary<string, Color> colors)
        {
            yield return ("_Color", colors["_Color"]);
            yield return ("_BackColor", colors["_BackColor"]);
            yield return ("_EmissionColor", colors["_EmissionTintColor"]);

            for (int i = 0; i <= 7; i++)
            {
                yield return ($"_SpecularColor{i}", colors[$"_SpecularColor{i}"]);
                yield return ($"_RimColor{i}", colors[$"_RimColor{i}"]);
                yield return ($"_OutlineColor{i}", colors[$"_OutlineColor{i}"]);
                yield return ($"_BloomColor{i}", colors[$"_mBloomColor{i}"]);
            }

            // Texture Scale Offset
            yield return ("_Maps_ST", colors["_MainMaps_ST"]);

            // Stockings
            yield return ("_StockingsColor", colors["_Stockcolor"]);
            yield return ("_StockingsColorDark", colors["_StockDarkcolor"]);
        }
    }
}
