include <util.scad>

module anchor()
{
 height = 48;
 width = 40;
 depth = 31;
 radius = 11;
 material_strength = 1; 
 
 depth_base = depth - radius;

 difference() {
    cylinder(height, radius, radius);
    cylinder(height, radius - material_strength, radius - material_strength);
    translate([-radius, -radius, 0]) {
      cube([radius, radius * 2, height]);
    };
 };

 translate([radius, -radius, 0]) {
     cube([depth_base, radius * 2, height]);
 };
}

module nanostationm()
{
    height = 280;
    width = 80;
    depth = 30;
    
    anchor1_shift = 65;
    
    anchor2_shift = 165;

    color(rgb_normalize([255,255,255])) translate([0, 0, -height]) {
        translate([0, 0, anchor1_shift]) anchor();  
        translate([0, 0, anchor2_shift]) anchor();  

        translate([31, -width / 2, 0]) {
            cube([depth, width, height]);
        };
    };
}

module nanostationloco()
{
    height = 175;
    width = 80;
    depth = 30;
    
    anchor1_shift = 65;
    
    color(rgb_normalize([255,255,255])) translate([0, 0, -height]) {
        translate([0, 0, anchor1_shift]) anchor();
        
        translate([31, -width / 2, 0]) {
            cube([depth, width, height]);
        };
    };
}