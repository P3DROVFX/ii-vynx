.pragma library

// Tabela de ~150 cores comuns baseadas na especificação CSS / SVG
const colorTable = [
    { name: "Black", hex: "#000000" },
    { name: "Night Rider", hex: "#333333" },
    { name: "Dim Gray", hex: "#696969" },
    { name: "Gray", hex: "#808080" },
    { name: "Dark Gray", hex: "#A9A9A9" },
    { name: "Silver", hex: "#C0C0C0" },
    { name: "Light Gray", hex: "#D3D3D3" },
    { name: "Gainsboro", hex: "#DCDCDC" },
    { name: "White Smoke", hex: "#F5F5F5" },
    { name: "White", hex: "#FFFFFF" },
    { name: "Snow", hex: "#FFFAFA" },
    { name: "Ghost White", hex: "#F8F8FF" },
    { name: "Floral White", hex: "#FFFAF0" },
    { name: "Linen", hex: "#FAF0E6" },
    { name: "Antique White", hex: "#FAEBD7" },
    { name: "Papaya Whip", hex: "#FFEFD5" },
    { name: "Blanched Almond", hex: "#FFEBCD" },
    { name: "Bisque", hex: "#FFE4C4" },
    { name: "Moccasin", hex: "#FFE4B5" },
    { name: "Navajo White", hex: "#FFDEAD" },
    { name: "Peach Puff", hex: "#FFDAB9" },
    { name: "Misty Rose", hex: "#FFE4E1" },
    { name: "Lavender Blush", hex: "#FFF0F5" },
    { name: "Seashell", hex: "#FFF5EE" },
    { name: "Old Lace", hex: "#FDF5E6" },
    { name: "Ivory", hex: "#FFFFF0" },
    { name: "Honeydew", hex: "#F0FFF0" },
    { name: "Mint Cream", hex: "#F5FFFA" },
    { name: "Azure", hex: "#F0FFFF" },
    { name: "Alice Blue", hex: "#F0F8FF" },
    { name: "Lavender", hex: "#E6E6FA" },
    { name: "Thistle", hex: "#D8BFD8" },
    { name: "Plum", hex: "#DDA0DD" },
    { name: "Violet", hex: "#EE82EE" },
    { name: "Orchid", hex: "#DA70D6" },
    { name: "Fuchsia", hex: "#FF00FF" },
    { name: "Magenta", hex: "#FF00FF" },
    { name: "Medium Orchid", hex: "#BA55D3" },
    { name: "Medium Purple", hex: "#9370DB" },
    { name: "Amethyst", hex: "#9966CC" },
    { name: "Blue Violet", hex: "#8A2BE2" },
    { name: "Dark Violet", hex: "#9400D3" },
    { name: "Dark Orchid", hex: "#9932CC" },
    { name: "Dark Magenta", hex: "#8B008B" },
    { name: "Purple", hex: "#800080" },
    { name: "Indigo", hex: "#4B0082" },
    { name: "Slate Blue", hex: "#6A5ACD" },
    { name: "Dark Slate Blue", hex: "#483D8B" },
    { name: "Medium Slate Blue", hex: "#7B68EE" },
    { name: "Green Yellow", hex: "#ADFF2F" },
    { name: "Chartreuse", hex: "#7FFF00" },
    { name: "Lawn Green", hex: "#7CFC00" },
    { name: "Lime", hex: "#00FF00" },
    { name: "Lime Green", hex: "#32CD32" },
    { name: "Pale Green", hex: "#98FB98" },
    { name: "Light Green", hex: "#90EE90" },
    { name: "Medium Spring Green", hex: "#00FA9A" },
    { name: "Spring Green", hex: "#00FF7F" },
    { name: "Medium Sea Green", hex: "#3CB371" },
    { name: "Sea Green", hex: "#2E8B57" },
    { name: "Forest Green", hex: "#228B22" },
    { name: "Green", hex: "#008000" },
    { name: "Dark Green", hex: "#006400" },
    { name: "Yellow Green", hex: "#9ACD32" },
    { name: "Olive Drab", hex: "#6B8E23" },
    { name: "Olive", hex: "#808000" },
    { name: "Dark Olive Green", hex: "#556B2F" },
    { name: "Medium Aquamarine", hex: "#66CDAA" },
    { name: "Dark Sea Green", hex: "#8FBC8F" },
    { name: "Light Sea Green", hex: "#20B2AA" },
    { name: "Dark Cyan", hex: "#008B8B" },
    { name: "Teal", hex: "#008080" },
    { name: "Aqua", hex: "#00FFFF" },
    { name: "Cyan", hex: "#00FFFF" },
    { name: "Light Cyan", hex: "#E0FFFF" },
    { name: "Pale Turquoise", hex: "#AFEEEE" },
    { name: "Aquamarine", hex: "#7FFFD4" },
    { name: "Turquoise", hex: "#40E0D0" },
    { name: "Medium Turquoise", hex: "#48D1CC" },
    { name: "Dark Turquoise", hex: "#00CED1" },
    { name: "Cadet Blue", hex: "#5F9EA0" },
    { name: "Steel Blue", hex: "#4682B4" },
    { name: "Light Steel Blue", hex: "#B0C4DE" },
    { name: "Powder Blue", hex: "#B0E0E6" },
    { name: "Light Blue", hex: "#ADD8E6" },
    { name: "Sky Blue", hex: "#87CEEB" },
    { name: "Light Sky Blue", hex: "#87CEFA" },
    { name: "Deep Sky Blue", hex: "#00BFFF" },
    { name: "Dodger Blue", hex: "#1E90FF" },
    { name: "Cornflower Blue", hex: "#6495ED" },
    { name: "Royal Blue", hex: "#4169E1" },
    { name: "Blue", hex: "#0000FF" },
    { name: "Medium Blue", hex: "#0000CD" },
    { name: "Dark Blue", hex: "#00008B" },
    { name: "Navy", hex: "#000080" },
    { name: "Midnight Blue", hex: "#191970" },
    { name: "Pink", hex: "#FFC0CB" },
    { name: "Light Pink", hex: "#FFB6C1" },
    { name: "Hot Pink", hex: "#FF69B4" },
    { name: "Deep Pink", hex: "#FF1493" },
    { name: "Pale Violet Red", hex: "#DB7093" },
    { name: "Medium Violet Red", hex: "#C71585" },
    { name: "Indian Red", hex: "#CD5C5C" },
    { name: "Light Coral", hex: "#F08080" },
    { name: "Salmon", hex: "#FA8072" },
    { name: "Dark Salmon", hex: "#E9967A" },
    { name: "Light Salmon", hex: "#FFA07A" },
    { name: "Crimson", hex: "#DC143C" },
    { name: "Red", hex: "#FF0000" },
    { name: "Fire Brick", hex: "#B22222" },
    { name: "Dark Red", hex: "#8B0000" },
    { name: "Tomato", hex: "#FF6347" },
    { name: "Orange Red", hex: "#FF4500" },
    { name: "Dark Orange", hex: "#FF8C00" },
    { name: "Orange", hex: "#FFA500" },
    { name: "Gold", hex: "#FFD700" },
    { name: "Yellow", hex: "#FFFF00" },
    { name: "Light Yellow", hex: "#FFFFE0" },
    { name: "Lemon Chiffon", hex: "#FFFACD" },
    { name: "Light Goldenrod Yellow", hex: "#FAFAD2" },
    { name: "Pale Goldenrod", hex: "#EEE8AA" },
    { name: "Khaki", hex: "#F0E68C" },
    { name: "Dark Khaki", hex: "#BDB76B" },
    { name: "Cornsilk", hex: "#FFF8DC" },
    { name: "Wheat", hex: "#F5DEB3" },
    { name: "Burly Wood", hex: "#DEB887" },
    { name: "Tan", hex: "#D2B48C" },
    { name: "Rosy Brown", hex: "#BC8F8F" },
    { name: "Sandy Brown", hex: "#F4A460" },
    { name: "Goldenrod", hex: "#DAA520" },
    { name: "Dark Goldenrod", hex: "#B8860B" },
    { name: "Peru", hex: "#CD853F" },
    { name: "Chocolate", hex: "#D2691E" },
    { name: "Saddle Brown", hex: "#8B4513" },
    { name: "Sienna", hex: "#A0522D" },
    { name: "Brown", hex: "#A52A2A" },
    { name: "Maroon", hex: "#800000" }
];

function hexToRgb(hex) {
    hex = hex.replace(/^#/, '');
    if (hex.length === 3) {
        hex = hex.split('').map(char => char + char).join('');
    }
    const r = parseInt(hex.substring(0, 2), 16) || 0;
    const g = parseInt(hex.substring(2, 4), 16) || 0;
    const b = parseInt(hex.substring(4, 6), 16) || 0;
    return { r, g, b };
}

function hexToHsl(hex) {
    let { r, g, b } = hexToRgb(hex);
    r /= 255; g /= 255; b /= 255;
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    let h, s, l = (max + min) / 2;

    if (max === min) {
        h = s = 0; // achromatic
    } else {
        const d = max - min;
        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
        switch (max) {
            case r: h = (g - b) / d + (g < b ? 6 : 0); break;
            case g: h = (b - r) / d + 2; break;
            case b: h = (r - g) / d + 4; break;
        }
        h /= 6;
    }
    return { h: h * 360, s, l };
}

function hslToHex(h, s, l) {
    let r, g, b;
    h /= 360;

    if (s === 0) {
        r = g = b = l; // achromatic
    } else {
        const hue2rgb = (p, q, t) => {
            if (t < 0) t += 1;
            if (t > 1) t -= 1;
            if (t < 1 / 6) return p + (q - p) * 6 * t;
            if (t < 1 / 2) return q;
            if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
            return p;
        };
        const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        const p = 2 * l - q;
        r = hue2rgb(p, q, h + 1 / 3);
        g = hue2rgb(p, q, h);
        b = hue2rgb(p, q, h - 1 / 3);
    }

    const toHex = x => {
        const hex = Math.round(x * 255).toString(16);
        return hex.length === 1 ? '0' + hex : hex;
    };
    return `#${toHex(r)}${toHex(g)}${toHex(b)}`.toUpperCase();
}

function clamp(value, min, max) {
    return Math.min(Math.max(value, min), max);
}

function getColorName(hex) {
    if (!hex || typeof hex !== "string" || hex === "transparent") return "Unknown";
    
    const targetRgb = hexToRgb(hex);
    if (isNaN(targetRgb.r)) return "Unknown";

    let closestName = "Unknown";
    let minDistance = Infinity;

    for (let i = 0; i < colorTable.length; i++) {
        const color = colorTable[i];
        const rgb = hexToRgb(color.hex);
        const distance = Math.pow(rgb.r - targetRgb.r, 2) + 
                         Math.pow(rgb.g - targetRgb.g, 2) + 
                         Math.pow(rgb.b - targetRgb.b, 2);
                         
        if (distance < minDistance) {
            minDistance = distance;
            closestName = color.name;
        }
    }

    return closestName;
}
