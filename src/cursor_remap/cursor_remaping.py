python3 -c '
import glob
import os

files = glob.glob("src/config/*.cursor")
print(f"Processando {len(files)} arquivos com a nova camada física de 128px...")

for filepath in files:
    with open(filepath, "r") as f:
        lines = f.readlines()
    
    base_hx, base_hy = 4, 4
    for line in lines:
        parts = line.strip().split()
        if len(parts) >= 3:
            base_hx = int(parts[1])
            base_hy = int(parts[2])
            break

    basename = os.path.basename(filepath)
    cursor_name = os.path.splitext(basename)[0]
    
    new_lines = []
    
    # Mapeia a escada GNOME (24, 32, 48, 64, 96) para as imagens físicas reais (x1, x1_5, x2, x4, x5)
    # 1. Nominal 24 -> 32px (x1)
    new_lines.append(f"24 {base_hx} {base_hy} x1/{cursor_name}.png\n")
    
    # 2. Nominal 32 -> 48px (x1_5)
    h32_x, h32_y = int(base_hx * 1.5), int(base_hy * 1.5)
    new_lines.append(f"32 {h32_x} {h32_y} x1_5/{cursor_name}.png\n")
    
    # 3. Nominal 48 -> 64px (x2)
    h48_x, h48_y = int(base_hx * 2.0), int(base_hy * 2.0)
    new_lines.append(f"48 {h48_x} {h48_y} x2/{cursor_name}.png\n")
    
    # 4. Nominal 64 -> 96px (x4)
    h64_x, h64_y = int(base_hx * 3.0), int(base_hy * 3.0)
    new_lines.append(f"64 {h64_x} {h64_y} x4/{cursor_name}.png\n")
    
    # 5. Nominal 96 -> 128px (x5 - Nitidez máxima absoluta sem distorção)
    h96_x, h96_y = int(base_hx * 4.0), int(base_hy * 4.0)
    new_lines.append(f"96 {h96_x} {h96_y} x5/{cursor_name}.png\n")

    with open(filepath, "w") as f:
        f.writelines(new_lines)

print("Mapeamento com 128px concluído com sucesso!")
'
