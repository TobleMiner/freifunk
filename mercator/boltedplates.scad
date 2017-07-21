module bolt(r_head=9, r_bolt=5, l_head=5, l_bolt=35) {
    rotate([-90, 0, -90]) {
        cylinder(l_head, r_head, r_head, $fn=6);
        translate([0, 0, l_head]) cylinder(l_bolt, r_bolt, r_bolt);
    };
}

module nut(r_inner=5, r_outer=9, length=5) {
    rotate([-90, 10, -90]) difference() {
        cylinder(length, r_outer, r_outer, $fn=6);
        cylinder(length, r_inner, r_inner);        
    };
}

module bolted_plates(size=[50, 50, 4], dist=15, border=5, bolt=5) {
    bolt_head_length = 5;
    bolt_hangover = 2;
    nut_length = 5;
    
    bolt_offset = border + bolt / 2;
    
    bolt_offsets = [
        [0, -bolt_offset, bolt_offset],
        [0, bolt_offset - size[0], bolt_offset],
        [0, -bolt_offset, size[1] - bolt_offset],
        [0, bolt_offset - size[0], size[1] - bolt_offset]
    ];
    
    rotate([90, 0, -90]) mirror([0, 0, 1]) cube(size);
    translate([dist + size[2], 0, 0]) rotate([90, 0, -90]) mirror([0, 0, 1]) cube(size);
    for(i = [0:len(bolt_offsets) - 1]) {
        translate(bolt_offsets[i]) {
            translate([-bolt_head_length, 0, 0]) bolt(bolt * 2 - 1, bolt, bolt_head_length, size[2] * 2 + dist + nut_length + bolt_hangover);
            translate([size[2] * 2 + dist, 0, 0]) nut(bolt, bolt * 2 - 1, nut_length);
        };
    };
}