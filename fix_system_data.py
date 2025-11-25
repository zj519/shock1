#!/usr/bin/env python3
"""
Fix system.data by placing molecules on a grid instead of at origin
"""

def fix_system_data(infile, outfile):
    """Spread molecules throughout the box on a grid"""
    
    # Read file
    print(f"Reading {infile}...")
    with open(infile, 'r') as f:
        lines = f.readlines()
    
    print(f"Total lines: {len(lines)}")
    
    # Find Atoms section - look for "Atoms" followed by optional comment
    atoms_start = None
    atoms_end = None
    for i, line in enumerate(lines):
        if 'Atoms' in line and not line.strip().startswith('#'):
            print(f"Found Atoms section at line {i}: {line.strip()}")
            atoms_start = i + 1
            # Skip blank lines after "Atoms"
            while atoms_start < len(lines) and lines[atoms_start].strip() == '':
                atoms_start += 1
            break
    
    if not atoms_start:
        print("Error: Could not find Atoms section")
        return
    
    # Find end of Atoms section (blank line or next section)
    for i in range(atoms_start, len(lines)):
        line = lines[i].strip()
        if line == '' or line in ['Bonds', 'Velocities', 'Angles', 'Dihedrals']:
            atoms_end = i
            print(f"Atoms section ends at line {i}")
            break
    
    if not atoms_end:
        atoms_end = len(lines)
    
    print(f"Parsing atoms from line {atoms_start} to {atoms_end}")
    
    # Parse atoms
    atoms = []
    for i in range(atoms_start, atoms_end):
        parts = lines[i].split()
        if len(parts) >= 7:
            try:
                atoms.append({
                    'id': int(parts[0]),
                    'mol': int(parts[1]),
                    'type': int(parts[2]),
                    'q': float(parts[3]),
                    'x': float(parts[4]),
                    'y': float(parts[5]),
                    'z': float(parts[6]),
                    'line_num': i
                })
            except ValueError:
                continue  # Skip lines that can't be parsed
    
    print(f"Parsed {len(atoms)} atoms")
    
    if len(atoms) == 0:
        print("ERROR: No atoms found!")
        return
    
    # Grid dimensions for 880 N2 + 10 dodecane
    # Box: x:[2, 3700], y:[0, 1400], z:[0, 1400]
    dx = 160  # spacing in x
    dy = 70   # spacing in y
    dz = 700  # spacing in z
    
    mol_positions = {}
    ix, iy, iz = 0, 0, 0
    
    for atom in atoms:
        mol_id = atom['mol']
        
        if mol_id not in mol_positions:
            # Assign new position for this molecule
            x_base = 100 + ix * dx
            y_base = 10 + iy * dy
            z_base = 10 + iz * dz
            
            mol_positions[mol_id] = (x_base, y_base, z_base)
            
            # Increment grid position
            ix += 1
            if ix >= 22:
                ix = 0
                iy += 1
                if iy >= 20:
                    iy = 0
                    iz += 1
        
        # Get molecule base position
        x_base, y_base, z_base = mol_positions[mol_id]
        
        # Apply offset (keep relative position within molecule)
        atom['x'] += x_base
        atom['y'] += y_base
        atom['z'] += z_base
        
        # Update line
        new_line = f"{atom['id']} {atom['mol']} {atom['type']} {atom['q']:.6f} {atom['x']:.6f} {atom['y']:.6f} {atom['z']:.6f}\n"
        lines[atom['line_num']] = new_line
    
    # Write output
    with open(outfile, 'w') as f:
        f.writelines(lines)
    
    print(f"Fixed {len(atoms)} atoms in {len(mol_positions)} molecules")
    print(f"Output written to {outfile}")
    print("\nFirst few molecules positions:")
    for mol_id in sorted(mol_positions.keys())[:5]:
        print(f"  Molecule {mol_id}: {mol_positions[mol_id]}")

if __name__ == '__main__':
    fix_system_data('system.data', 'system_fixed.data')
