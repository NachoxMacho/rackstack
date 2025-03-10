include <../../helper/common.scad>
include <../../config/common.scad>
include <../sharedVariables.scad>
include <./sideWallMagnetMount.scad>
include <./sideWallVariables.scad>
use <./magnetModule.scad>
use <./hingeModule.scad>

//translate(v = [hingePoleDx ,hingePoleDy, 10])
//rotate(a=[0,0,-120])
//translate(v = [-hingePoleDx ,-hingePoleDy, 0])
*sideWallBase();

module sideWallBase() {

  applyHingeConnector()
  applyMagnetConnector()
  applyHandle()
  sideWallBase();

  module sideWallBase() {

    module sideWallShellHelper(x, y, z, r) {
      translate(v = [r, r, 0])
      minkowski() {
        cube(size = [x-r, y-2*r, z]);

        if (r > 0) {
          sphere(r = r);
        }
      }
    }

    intersection() {
      difference() {
        sideWallShellHelper(sideWallX, sideWallY, sideWallZ, baseRoundness);
        translate(v = [sideWallThickness, sideWallThickness, 0])
        sideWallShellHelper(sideWallX, sideWallY-2*sideWallThickness, sideWallZ, max(0,baseRoundness-sideWallThickness));
      }
      halfspace(vpos = [-1, 0, 0], p = [sideWallX, 0, 0]);
      halfspace(vpos = [0, 0, -1], p = [0, 0, sideWallZ]);
      halfspace(vpos = [0, 0, 1], p = [0, 0, 0]);
      halfspace(vpos = [1, 0, 0], p = [0, 0, 0]);
    }
  }

  module applyHingeConnector() {

    hingeHoleShellR = hingePoleR+1;

    hingeHoleH = hingePoleH-sideWallConnLugDepression;
    assert(hingeHoleH > 1);

    apply_pn() {
      hull() {
        hingeShell();
        hingeSideProjectionPlane();
      }

      union() {
        hingeHole(extraZ=1);

        translate(v=[0,0,sideWallZ])
        mirror(v=[0,0,1])
        hingeHole(extraZ=1);

        // Trim parts of the wall for rotational clearance
        halfspace(p=[0, sideWallY-2.5, 0], vpos=[-0.5,1,0]); // flat area to limit rotation against the main rail
        halfspace(p=[sideWallX-10, sideWallY, 0], vpos=[1,2.5,0]);
      }

      children(0);
    }

    module hingeShell() {
      translate(v = [hingePoleDx, hingePoleDy, 0])
      cylinder(r = hingeHoleShellR, h = sideWallZ);
    }

    // XZ plane in line with the back of the case. Project the hinge pole shell onto this to fill any weird
    // geometries from the curves of the side wall
    module hingeSideProjectionPlane() {
      translate(v=[sideWallThickness, hingePoleDy - hingeHoleShellR, 0])
      cube(size=[eps, 2*hingeHoleShellR, sideWallZ]);
    }

    module hingeHole(extraZ) {
      translate(v = [hingePoleDx, hingePoleDy, 0])
      cylinder(r = hingePoleR+radiusXYSlack, h = hingeHoleH+extraZ);
    }
  }

  // TODO: add correct magnet translations, also remove random variables
  module applyMagnetConnector() {
    apply_p() {
      union() {
        translate(v = [sideWallThickness, magnetMountToYBarFront, magnetMountToYBarTop - sideWallZHingeTotalClearance])
        sideWallMagnetMountRotated();

        translate(v = [sideWallThickness, magnetMountToYBarFront, sideWallZ - (magnetMountToYBarTop- sideWallZHingeTotalClearance)])
        sideWallMagnetMountRotated();
      }

      children(0);
    }

    module sideWallMagnetMountRotated() {
      rotate(a=[0,90,0])
      sideWallMagnetMount();
    }
  }

  module applyHandle() {

    handleWidth = 8;
    handleLength = 60;
    handleRoundness = 7;
    widthOffset = 3;

    apply_n() {

      minkowski() {
        sphere(r=handleRoundness);

        translate(v = [sideWallX -(handleWidth-handleRoundness) + widthOffset, 0, (sideWallZ-handleLength)/2])
        cube(size = [handleWidth-handleRoundness, sideWallThickness, handleLength-handleRoundness]);
      }

      children(0);
    }
  }
}

module applySideWallDefaultVentilation(numVents) {

  r = 2; // vent roundness
  ventLength = sideWallY - 2*sideWallDefaultVentilationToZEdge;
  ventZDiff = (sideWallZ - 2*sideWallDefaultVentilationToYEdge)/(numVents-1);

  apply_n() {
    for (i = [0:numVents-1]) {
      translate(v = [0, sideWallDefaultVentilationToZEdge, i * ventZDiff + sideWallDefaultVentilationToYEdge])
        vent();
    }
    children(0);
  }

  module vent() {
    translate(v=[-inf/2,r,-sideWallDefaultVentilationWidth/2])
    minkowski() {
      rotate(a=[0,90,0])
        cylinder(r=r,h=inf);
      cube(size = [inf, max(eps, ventLength-2*r), max(eps,sideWallDefaultVentilationWidth-2*r)]);
    }
  }
}

module applySideWallBracing(numRibs) {

  apply_p() {
    // TODO add horizontal bracing
    sideWallVerticalBracing(numRibs = numRibs);
    children(0);
  }

  module sideWallVerticalBracing(numRibs, ribZ, ribExtrusion=1) {

    ribRampLength = 5;
    ribWidth = 2;
    ribZ = sideWallZ;
    ribYDiff = sideWallY - 2*sideWallDefaultVerticalBracingToZEdge;

    translate(v=[0,sideWallDefaultVerticalBracingToZEdge,0])
      intersection() {
        for (i = [0:numRibs-1]) {

          translate(v = [sideWallThickness, i*ribYDiff, (sideWallZ-ribZ)/2])
            translate(v = [ribExtrusion-ribWidth, 0, 0])
              verticalRib(ribExtend=4, ribWidth=ribWidth);
        }

        halfspace(vpos=[1,0,0], p=[0,0,0]);
      }

    module verticalRib(ribExtend, ribWidth) {

      roundness = 0.5;
      translate(v=[0,-ribWidth/2,0])
        minkowski() {
          hull() {
            translate(v=[0,0,roundness])
              cube(size = [eps, ribWidth, eps]);

            translate(v = [0, 0, ribRampLength])
              cube(size = [ribExtend, ribWidth, ribZ-2*(ribRampLength+roundness)]);

            translate(v = [0, 0, ribZ-roundness])
              cube(size = [eps, ribWidth, eps]);
          }

          sphere(r=roundness);
        }
    }
  }
}

