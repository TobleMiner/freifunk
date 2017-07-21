include <nanostation.scad>
include <util.scad>

//highriser();

rooftop();

//rotate([0,0,-90]) railing_pair(700, mountangle=30, nsm=true);

/*rotate([0, 20, 0]) {
    nanostationm_mount(200, 200, 300, 60);
};

translate([0, 600, 0]) rotate([0, 20, 0]) {
    nanostationloco_mount(200, 200, 300, 60);
};*/


module rooftop() {
    width = 47580 / 10 * 2;
    depth = 17590 / 10 * 4;
    railing_inset = 700;
    railing_dist = 800;
    rail_inset = 800;

    strength = 10;
    
    rail_length = [width - 2 * rail_inset, depth - 2 * rail_inset];
    
    n_railing_elements = [floor(rail_length[0] / railing_dist), floor(rail_length[1] / railing_dist)];
    
    railing_offset = [(rail_length[0] - n_railing_elements[0] * railing_dist) / 2, (rail_length[1] - n_railing_elements[1] * railing_dist) / 2];
    
    color(rgb_normalize([100, 100, 100])) cube([depth, width, strength]);
        
    translate([0, 0, strength]) {
        translate([rail_inset, rail_inset, 0]) {
            rails(rail_length[0], rail_length[1]);
        };
        translate([railing_inset, rail_inset, 0]) {
            for(i = [0:n_railing_elements[0] - 1]) {
                translate([0, railing_offset[0] + railing_dist * i, 0])
                {
                    mirror([1, 0 , 0])
                        railing_pair(railing_dist, mountangle=30, nsm=true);
                    translate([depth - 2 * railing_inset, 0, 0])
                        railing_pair(railing_dist, mountangle=30, nsm=true);
                };
            };
        };
        translate([rail_inset, railing_inset, 0]) {
            for(i = [0:n_railing_elements[1] - 1]) {
                translate([railing_offset[1] + railing_dist * i, 0, 0]) {
                    rotate([0, 0, -90])
                        railing_pair(railing_dist, mountangle=30, loco=true);
                    translate([0, width - 2 * railing_inset, 0]) rotate([0, 0, -90]) mirror([1, 0, 0])
                        railing_pair(railing_dist, mountangle=30, nsm=true);
                };
            };
        };
    };
};

module rails(width, depth) {
    rail_width = 20;
    rail_height = 35;
    
    rail_support_height = 50;
    rail_support_width = 50;
    
    rail_spacing = 400;
    
    rail_support_dist = 800;
    
    n_supports = [floor((width - 2 * rail_spacing) / rail_support_dist), floor((depth - 2 * rail_spacing) / rail_support_dist)];
    
    support_offset = [((width - 2 * rail_spacing) - (n_supports[0] * rail_support_dist)) / 2, ((depth  - 2 * rail_spacing) - (n_supports[1] * rail_support_dist)) / 2];
    
    echo(support_offset);
        
    color(rgb_normalize([255, 255, 255])) {
        for(i = [1:n_supports[0]]) {
            translate([0, rail_support_dist * i + support_offset[0], 0 ]) cube([rail_spacing + rail_width, rail_support_width, rail_support_height]);
            translate([depth - rail_spacing, rail_support_dist * i + support_offset[0], 0 ]) cube([rail_spacing + rail_width, rail_support_width, rail_support_height]);
        }
        echo(n_supports[1]);
        for(i = [1:n_supports[1]]) {
            translate([rail_support_dist * i + support_offset[1], 0, 0 ]) cube([rail_support_width, rail_spacing + rail_width, rail_support_height]);
            translate([rail_support_dist * i + support_offset[1], width - rail_spacing - rail_width, 0 ]) cube([rail_support_width, rail_spacing + rail_width, rail_support_height]);
        }
    };
    
    translate([0, 0, rail_support_height]) {
        rail_rectangle(width, depth, [rail_width, rail_height]);
        translate([rail_spacing, rail_spacing, 0]) rail_rectangle(width - 2 * rail_spacing, depth - 2 * rail_spacing, [rail_width, rail_height]);
    }
}

module rail_rectangle(a, b, rail_dimensions) {
    color(rgb_normalize([130, 130, 130])) {
        cube([rail_dimensions[0], a, rail_dimensions[1]]);
        rotate([0, 0, -90]) cube([rail_dimensions[0], b, rail_dimensions[1]]);
        translate([0, a, 0]) rotate([0, 0, -90]) cube([rail_dimensions[0], b, rail_dimensions[1]]);
        translate([b, 0, 0]) cube([rail_dimensions[0], a, rail_dimensions[1]]);
    };
}

module highriser() {
    height = 61400;
    width = 47580;
    depth = 17590;
    
    cube([depth, width, height]);
};


module railing_support(height, height_upper_straight, angle, mid_height, mid_length, material_depth, material_width, offset_z_upper, offset_x_upper) {

    color(rgb_normalize([255, 255, 255])) {
        rotate([0, 90 - angle, 0]) cube([material_depth, material_width, mid_length]);
        translate([offset_x_upper, 0, offset_z_upper]) cube([material_depth, material_width, height_upper_straight]);
    };
};

module railing_pair(dist, mountangle=0, pos=0.7, off=60, length=400, nsm=false, loco=false) {
    height = 1000;
    height_upper_straight = 350;
    angle = 40;
    material_depth = 50;
    material_width = 15;

    mid_height = height - height_upper_straight;

    mid_length = mid_height / sin(angle);

    offset_z_upper = mid_height;
    offset_x_upper = cos(angle) * mid_length;

    // Supports
    railing_support(height, height_upper_straight, angle, mid_height, mid_length, material_depth, material_width, offset_z_upper, offset_x_upper);
    translate([0, dist, 0]) railing_support(height, height_upper_straight, angle, mid_height, mid_length, material_depth, material_width, offset_z_upper, offset_x_upper);
    
    // Outer panel
    color(rgb_normalize([166, 166, 166])) translate([offset_x_upper + material_depth, 0, offset_z_upper]) cube([material_width, 2 * material_width + dist, height_upper_straight]);
    
    vec = [mid_length * cos(angle), 0, mid_length * sin(angle)];
    vec_norm = vec / vec_len(vec);
    vec_scaled = vec_norm * mid_length * pos;
        
    translate([0, dist + material_width / 2, 0] + vec_scaled) {
        rotate([0, -angle, 0]) {
            translate([0, 0, -material_depth/2]) {
                rotate([0, angle, 0]) {
                    rotate([0, mountangle, 0]) {
                        if(nsm) {
                            nanostationm_mount(dist / 2, dist / 2, length, off);
                        }
                        
                        if(loco) {
                            nanostationloco_mount(dist / 2, dist / 2, length, off);
                        }
                    };
                };
            };
        };
    };
}

module mount(left, right, length) {
    radius = 9;
    
    color(rgb_normalize([101, 101, 101])) {
        rotate([90, 0, 0]) {
            cylinder(left, radius, radius);
            translate([0, 0, left]) cylinder(right, radius, radius);
        };
        
        translate([0, -left, -(length + radius / 2)]) rotate(0, 90, 90) cylinder(length + radius / 2, radius, radius);
    };   
};

module nanostationm_mount(left, right, length, off) {
    
    mount(left, right, length, off);
    
    translate([0, -left, -off]) nanostationm();   
};

module nanostationloco_mount(left, right, length, off) {
    
    mount(left, right, length, off);
    
    translate([0, -left, -off]) nanostationloco();   
};